# PURPOSE

This directory provides a reference implementation for the Social Simulation
REPository Interface (SSREPI).

This is based on the SSS-complex runs, where, I believe SSS stands for Swarm Social Simulation. The original repository for this is [here](https://https://github.com/garypolhill/FEARLUS-SPOMM).

An import file is

+ path.sh - this should be sourced to set up all the correct environment
  variables (and in particular, the PATH variable)

The key files to inspect are:

+ workflow.sh
+ SSS-StopC2-Cluster-create2.sh
+ SSS-StopC2-Cluster-create.sh
+ SSS-StopC2-Cluster-run2.sh
+ SSS-StopC2-Cluster-run.sh
+ postprocessing.sh

# MANIFEST

The actual model itself is this file:

+ fearlus-1.1.5.2\_spom-2.3 - the model - this is either of the following renamed.
+ shell.fearlus-1.1.5.2\_spom-2.3 - a mock version of the model which allows testing
+ elf64.fearlus-1.1.5.2\_spom-2.3 - the real binary model

Note I have replaced this with a bash script for testing at the moment.

This are the scripts to set up the runs and run the runs.

+  workflow.sh - this recreates the main workflow program, eventually this will be done by SSS-cluster.py2.py

calls the remainder:

+ SSS-StopC2-Cluster-create2.sh
+ SSS-StopC2-Cluster-create.sh
+ SSS-StopC2-Cluster-run2.sh
+ SSS-StopC2-Cluster-run.sh
+ postprocessing.sh

The following are the scripts that do the post-run analysis.

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
+ postprocessing.R - this recreates the manual R manipulation that Gary did to get the results.

postprocessing.R and table4.R are scripts I have created to recreate what Gary did manually.

There is a clean up script - this is:

+ clean.sh

The following is no longer used (although maybe again in future 

+ SSS-cluster2.py - this is the main metadata program, and produces the database,
  from which all the metadata is stored, and was originally the way the
  experiment was going to be invoked. I have changed this to bash invocation
  which I feel is more in line with the way things are normally done. Using
  Python as a job control language (JCL) is not a good idea in my humble opinion;
  althouh I may revisit this idea at some point (both are slow for doing complex
  evaluation but for differenet reasons).

