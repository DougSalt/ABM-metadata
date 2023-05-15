#!/usr/bin/env bash

VERSION=1.0
AUTHOR="Doug Salt"
DATE="2023-01-26"

print_usage() {

echo """
A small program to recursively filter on the dot produced by SSREPI programs.
This will first allow you to trace a particular entity through the directed
graph, and secondly filter on the entities you want to look at.

This takes three positional parameters. These are mandatory:

1. The input dot file that needs filtering.
2. The token we are concentrating on tracking or colouring.
3. The output dot file which will then need processing by graphviz.

So the optional parameters are:

    --help or -H - gets this help message.
    --colour or -C - sets colour on the trace entity and descendents rather than selecting the affected entities. 
    --affected or -a lists affected data to a named file. This can be used to describe affected entities, if say for instance the entity traced is a bad data set.
    --exclude or -x - exclude a given set of entity types
    --include or -i - include a specific set of entity types
    --version or -V - display the version of the program and exit.

"""

}

# Using getopt to process long options in a standard way.

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    '--affected') set -- "$@" '-a'   ;;
    '--colour')   set -- "$@" '-C'   ;;
    '--exclude')  set -- "$@" '-x'   ;;
    '--help')     set -- "$@" '-H'   ;;
    '--include')  set -- "$@" '-i'   ;;
    '--version')  set -- "$@" '-V'   ;;
    *)            set -- "$@" "$arg" ;;
  esac
done

# Default behavior
number=0; rest=false; ws=false

# Parse short options
OPTIND=1
include=""
exclude=""
affected=""
colour=

while getopts "a:HCi:x:V" opt
do
  case "$opt" in
    'a') affected="$OPTARG" ;;
    'H') print_usage; exit 0 ;;
    'C') colour=1 ;;
    'i') include="$include $OPTARG" ;;
    'V') echo $0: $VERSION  >&2; exit 1 ;;
    'x') exclude="$exclude $OPTARG" ;;
    '?') print_usage >&2; exit 1 ;;
  esac
done
shift $(expr $OPTIND - 1) # remove options from positional parameters

input="$1"
#input="provenance.dot"

if [ -z "$input" ] && [ ! -f $input ]
then
    echo "$0: The first postional parameter must be the input file we filtering or amending."
    exit -1
fi

available=$(cat $input | grep -v "\-\>" | tail -n +3 | head -n -1 | sed 's/^[[:space:]]*"//' | sed 's/".*$//' | sed 's/\..*$//' | sort | uniq | tr '\n' ' ') 

output="$2"
#output="trace.dot"
if [ -z "$output" ]
then
    echo "$0: 2nd parameter must be a path to which the input file will be written." 
    exit -1
fi

token="$3"
#token="Containers.container_505627104"
if [ -z "$token" ]
then
    echo "$0: 3rd positional parameter must be the target we are trying to trace."
   exit -1
fi 

if [[ -n "$exclude" && -n "$include" ]]
then
    echo "$0: Cannot have both an include or an exclude simultaneously"
    exit -2
fi

filter=
if [ -n "$include" ]
then
    found=
    for item in $include
    do
        if ! echo "$available" | grep -q $item 
        then
            echo "$0: --include $item not present in $input"
            exit -1
        fi
        type=$(echo "$token" | cut -f 1 -d.)
        if [[ $type = $item ]]
        then
            found=1
        fi
        filter="$filter $item"
    done
    if [ -z "$found" ]
    then
            echo "$0: --include must include $type from search token."
            exit -1
    fi
fi


if [ -n "$exclude" ]
then
    for item in $exclude
    do
        if ! echo "$available" | grep -q $item 
        then
            echo "$0: --exclude $item not present in $input"
            exit -1
        fi
        type=$(echo "$token" | cut -f 1 -d.)
        if [[ $type = $item ]]
        then
            echo "$0: Cannot exclude the token, $type you are looking for"
            exit -1
        fi
    done
    for item in $available
    do
        if ! echo "$exclude" | grep -q $item
        then
            filter="$filter $item"
        fi
    done
fi
if [ -z "$filter" ]
then
    filter=$available
fi

temp_output=$(mktemp)

echo trace_recurse.sh "$input" "$token" "$temp_output" "$filter" "$token" 
trace_recurse.sh "$input" "$token" "$temp_output" "$filter" "$token"

# What a pile of crap. You cannot call recursive _functions_. Bash gets very
# get a consistent process space. Horrible. But then I suppose was not designed
# to be recursive so I shouldn't moan too much.


if [ -n "$colour" ]
then
    while read line
    do
        # Grrrr. Bash does weird things with white space in strings. So beware!

        if egrep -F -q  "$line" $temp_output
        then
            line=$(echo $line | sed 's/\[label=/[color = red, fontcolor = red][label=/')
        fi
        echo $line >> $output
    done < $input
else 
    echo """
    digraph {
        margin=0 ratio=fill
        """ > "$output"
    cat $temp_output >> $output
    echo "}" >> $output
fi

if [ -n "$affected" ]
then
    grep -v "\->" $temp_output | cut -f2 -d\" | sort | uniq > "$affected"
fi
#rm $temp_output
