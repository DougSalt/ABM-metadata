# PURPOSE

Contains all the Python and Bash scripts to utilise SSREPI

# MANIFEST

+ analysis.py - converted - takes the database and draws the anlaysis sub graph
+ ContainerTypes.pl - ????
+ create\_database.py - used by Bash programs to create the database. The empty database ssrepi must be present for this to work in postgres
+ fine\_grain.py - converted - uses the database to construct the fine\_grain graph
+ folksonomy.py - converted - utilises database to produce the folksonomy sub-graph.
+ get\_value.py - used by Bash scripts to return a single value from the database given the primary key.
+ next\_study.py - used by Bash script to get the next available study number
+ path.sh - source this to get the correct paths to run the example
+ project\_metadata.py - This is an adhoc program to produce a metadata diagram.
+ project.py - converted - uses the database to produce the project sub-graph
+ provenance.py - converted - used the database to produce the provenance sub-graph
+ README.md - this file
+ services.py - converted - used to create the services sub-graph from the database
+ tbox.py
+ total.py
+ update.py - used by the Bash scripts to insert/update a database record
+ workflow.py - converted - This is an adhoc prgram to produce the workflow graph.
