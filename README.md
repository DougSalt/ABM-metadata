# PURPOSE

This directory is for the Miracle simulation metadata outputs specification.

# MANIFEST

+ bin - 
+ cfg - 
+ doc - 
+ example - 
+ lib - the Python 3 library containing
+ README.md - 
+ save - 

# RUNNING THE EXAMPLE

To run the job

bin/clean.sh
. bin/path.sh
nohup example/workflow.sh > workflow.out 2>workflow.err &

# NOTES

## 2017-07-28

OK where you are at:

You are tryin to simplify the drawing, and have implemented the code to define all the possible edges (including 3 part relationships), although that is not implemented yet.

You are using new_project.py to do this (considerably simplified from project.py), but are stuck on the fact that it appears that the home key for Containers apppears to be ID_CONTAINER_TYPES. So wrong. This is probably something to do with foreignKeys in ssrep_lib.py, but it needs investigating.

You have are doing a single run to generate diagrams, so do not clear out the directory.

## 2018-01-09

I tried a run before Xmas, and it looks like somebody stopped it, so I will try again.

## 2022-08-26

This is running on sqllite3, so the tasks are

1. debug the code so it is working on a local database
2. check the postgres setup is still working
3. use the example you have set up to run on postgres
4. learn flex and yacc to decompose and bash script - this will be useful for stuff elsewhere.

As of this date I have converted the code to python3 but there is still something wrong. I am not sure whether the conversion has introduced a bug or               


