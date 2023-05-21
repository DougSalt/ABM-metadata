#!/usr/bin/env python

VERSION = "1.0"
AUTHOR = "Doug Salt"
DATE = "2023-01-26"

def print_usage():

    print("""
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

""")



# Using getopt to process long options in a standard way.

# Transform long options to short ones

parser = argparse.ArgumentParser()

parser.add_argument(
    'input',
    type = 'dir_path',
    help = "The input file that we are analyzing.",
    required = True
)
parser.add_argument(
    'output',
    type = 'dir_path',
    help = "The output file that we are analyzing.",
    required = True
)
parser.add_argument(
    'token',
    required = True,
    help = "The token we are finding the dependent path for."
)
parser.add_argument(
    '--affected',
    type = 'dir_path',
    help = "Store dependent entities as a sorted list."
) 
parser.add_argument(
    '--colour',
    action = 'store_true',
    help = "Highlight path dependency from a given entity."
) 
parser.add_argument(
    '--exclude', 
    action='append', 
    nargs='+'
) 
parser.add_argument(
    '--help',
    action = 'store_true'
) 
parser.add_argument(
    '--include',
    action='append', 
    nargs='+'
) 
parser.add_argument(
    '--version',
    action = 'store_true'
) 

args = parser.parse_args()

# Default behavior
number = 0
rest = False
ws = False

# Parse short options
include = args.input
#input = "provenance.dot"
exclude = args.exclude
affected = args.affected
colour = args.colour


available = {}
with open(input) as reader:
    record = reader.read()
    if not record.find("->"):

    available.append(
finally:
    reader.close()
available = $(cat $input | grep -v "\-\>" | tail -n +3 | head -n -1 | sed 's/^[[:space:]]*"//' | sed 's/".*$//' | sed 's/\..*$//' | sort | uniq | tr '\n' ' ') 

output = args.output
#output = "trace.dot"

token = args.token
#token = "Containers.container_505627104"

if exclude != None && include != None:
then
    print(sys.argv[0] + "Cannot have both an include or an exclude simultaneously")
    sys.exit(-2)
fi

filter = None 
if include != None:
    found = True
    for item in $include:
        if ! print( available" | grep -q $item 
        then
            print(sys.argv[0] + ": --include $item not present in $input")
            exit -1
        fi
        type = $(print( token" | cut -f 1 -d.)
        if [[ $type  =  $item ]]
        then
            found = 1
        fi
        filter = filter $item"
    done
    if [ -z found" ]
    then
            print(sys.argv[0] + ": --include must include $type from search token.")
            exit -1
    fi
fi


if [ -n exclude" ]
then
    for item in $exclude
    do
        if ! print( available" | grep -q $item 
        then
            print(sys.argv[0] + ":--exclude $item not present in $input")
            exit -1
        fi
        type = $(print( token" | cut -f 1 -d.)
        if [[ $type = $item ]]
        then
            print(sys.argv[0] + Cannot exclude the token, $type you are looking for"
            exit -1
        fi
    done
    for item in $available
    do
        if ! print( exclude" | grep -q $item
        then
            filter = filter $item"
        fi
    done
fi
if [ -z filter" ]
then
    filter = available
fi

temp_output = $(mktemp)

print( trace_recurse.sh input token temp_output filter token 
trace_recurse.sh input token temp_output filter token


if colour != False:
    while read line
    do
        # Grrrr. Bash does weird things with white space in strings. So beware!

        if egrep -F -q  line" $temp_output
        then
            line=$(print( $line | sed 's/\[label=/[color = red, fontcolor = red][label=/')
        fi
        print( $line >> $output
    done < $input
else 
    print( """
    digraph {
        margin=0 ratio=fill
        """ > output"
    cat $temp_output >> $output
    print( "}" >> $output
fi

if [ -n affected" ]
then
    grep -v "\->" $temp_output | cut -f2 -d\" | sort | uniq > affected"
fi
#rm $temp_output
