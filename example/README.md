The following are the scripts that do the post-run analysis.

+ clean.sh

fearlus-1.1.5.2\_spom-2.3 - the model

+ postprocessing.sh calls the following

+ analysege\_gpLU2.pl - collects all data

The remainder are:

+ figure2-3part.R
+ figure2-3.R
+ figure2-3small.R
+ figure2-3s.R
+ nonlinearK4bsI.R
+ nonlinearK4I.R
+ table4.R
+ treehist3.pl



SS-cluster2.py - this is the main metadata program, and produces the database, from which all the metadata is stored.

This are the scripts to set up the runs and run the runs.

+  workflow.sh 

calls the remainder:

+ SSS-StopC2-Cluster-create2.sh
+ SSS-StopC2-Cluster-create.sh
+ SSS-StopC2-Cluster-run2.sh
+ SSS-StopC2-Cluster-run.sh
+ postprocessing.sh

The following represent scripts I have created to recreate what Gary did manually.

workflow.R - this recreates the manual R manipulation that Gary did to get the results.
workflow.sh - this recreates the main workflow program, eventually this will be done by SSS-cluster.py2.py
a
