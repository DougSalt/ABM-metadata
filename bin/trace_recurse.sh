#!/usr/bin/env bash

input="$1"
token="$2"
output="$3"
filter="$4"
hist="$5"

PARENT_COMMAND=$(ps $PPID | tail -n 1 | awk "{print \$6}")
if  [[ $PARENT_COMMAND != *trace_recurse.sh ]] && \
    [[ $PARENT_COMMAND != *trace.sh ]]
then
    echo $0: This code can only be called from the following:
    echo $0: trace.sh and trace_recurse.sh
    exit -1
fi

egrep "$token" "$input" | while read line
do
    #echo LINE $line
    if [[ "$line" = *\-\>* ]]
    then
        source=$(echo $line | sed 's/^.*"\(.*\)".*\-\>.*".*".*$/\1/')
        type_source=$(echo $source | cut -f1 -d.)
        target=$(echo $line | sed 's/^.*".*".*\-\>.*"\(.*\)".*\[.*$/\1/')
        type_target=$(echo $target | cut -f1 -d.)
        if [[ "$source" = "$token" ]]
        then 
            #echo TARGET $target
            if [[ "$hist" != *$target* ]]
            then
                if [[ "$filter" = *$type_source* ]] && [[ "$filter" = *$type_target* ]] 
                then
                    echo "$line" >> "$output"
                fi
#                echo trace_recurse "$input" "$target" "$output" "$filter" "$hist$target"
                trace_recurse.sh "$input" "$target" "$output" "$filter" "$hist$target"
             fi
        fi
    elif echo "$line" | egrep -q '^"'"$token"
    then
        type=$(echo $token | cut -f1 -d.)
        if [[ "$filter" = *$type* ]]
        then
            echo "$line" >> "$output"
        fi
    fi
done < "$input"
