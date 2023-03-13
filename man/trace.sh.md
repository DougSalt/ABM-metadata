# trace.sh - draws diagrams tracing a single entity

## SYNOPSIS

trace.sh [--colour] [--exclude]... [include]... input_file entity output_file

A small program to recursively filter on the dot produced by SSREPI programs.
This will first allow you to trace a particular entity through the directed
graph, and secondly filter on the entities you want to look at.

This takes three positional parameters. These are mandatory

1. The input dot file that needs filtering
2. The token we are concentrating on tracking or colouring
3. The output dot file which will then need processing by graphviz.

## DESCRIPTION

This takes a single instance and traces it through a diagram that has been produced from the SSREPI data. This can be used to trace things that are affected by a given entity. For instance if an original data set was in error and then we could trace the result data sets affected in that run.

This command works on diagrams that are produced from the following:

+ analysis.py.md
+ finegrain.py.md
+ folksonomy.py.md
+ get\_value.py.md
+ get\_values.py.md
+ next\_study.py.md
+ project.py.md
+ project\_metadata.py.md
+ provenance.py.md
+ services.py.md
+ workflow.py.md

## OPTIONS

So the optional parameters are:

    --help or -H - gets this help message.
    --colour or -C - sets trace or colour
    --exclude or -x - exclude a given set of entity types
    --include or -i - include a specific set of entity types
    --version or -V - display the version of the program and exit.


## ENVRIONMENT 

## EXIT STATUS

## RETURN VALUE

## EXAMPLES

## FILES

## AUTHORS

Doug Salt, Lorenzo Milazzo, Gary Polhill

## REPORTING BUGS

## BUGS

## COPYRIGHT

Copyright © 2022 The James Hutton Institute.  License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.

This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

## SEE ALSO

## HISTORY




