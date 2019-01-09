2017-07-28

OK where you are at:

You are tryin to simplify the drawing, and have implemented the code to define all the possible edges (including 3 part relationships), although that is not implemented yet.

You are using new_project.py to do this (considerably simplified from project.py), but are stuck on the fact that it appears that the home key for Containers apppears to be ID_CONTAINER_TYPES. So wrong. This is probably something to do with foreignKeys in ssrep_lib.py, but it needs investigating.

You have are doing a single run to generate diagrams, so do not clear out the directory.

2018-01-09

I tried a run before Xmas, and it looks like somebody stopped it, so I will try again.

To run the job

bin/clean.sh
. bin/path.sh
nohup workflow.sh >workflow.out 2>workflow.err &

