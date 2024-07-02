
THIS REPOSITORY IS NOW CLOSED AND HAS BEEN MOVED HERE (https://github.com/large-scale-modelling/miracle)

# PURPOSE

This repository is for the Miracle simulation metadata outputs specification.

# MANIFEST

+ README.md - this file
+ analysis.dot - a graphviz rendering of the analysis sub-graph.
+ bin - the directory containing all executables. These are all written in
  Python.
+ cfg - a directory used by the example code containing 
+ doc - documentation directory
+ DIARY.md - notes on what I have done (very out of date)
+ example - the example code or the reference example
+ finegrain.dot - a graphviz rendering of the example finegrain sub-graph
+ folksonomy.dot - a graphviz rendering of the example folksonomy sub-graph
+ lib - bash and python libraries used by code in `bin`, and also the bash library is used by the code in `example`.
+ LICENCSE - GPLv3 license
+ man - a directory with a bunch of Unix man pages.
+ project.dot - a graphviz rendering of the example project sub-graph
+ provenance.dot - a graphviz rendering of the example provenance sub-graph
+ save - the results of a previous run. This allows the re-running of
  example/postprocessing without having to do the all the model runs again in
  `example`.
+ services.dot - a graphviz rendering of the example services sub-graph
+ workflow.dot - a graphviz rendering of the example workflow sub-graph

# RUNNING THE EXAMPLE

To run the job

```
example/clean.sh
. example/path.sh
nohup example/workflow.sh > workflow.out 2>workflow.err &
```

# INSTALLATION

## DATBASES

### POSTGRES

#### OSX

```
brew install postgresql
brew install libmagic
brew install coreutils
```

### SQLITE3

```
brew install sqlite3
```

### GENERAL INSTALLATION

#### OSX

add to .zshrc
```
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
```
#### Command line OS'es

After installing the databases then install the following using pip.


```
pip install --upgrade pip
pip uninstall psycopg2
pip install psycopg2-binary --no-cache-dir
pip install rfc3987
pip install python-magic-bin==0.4.14
pip install graphviz
```

# POSTGRES Useful commands

`psql` to get to the database prompt.
`psql some-database-name` to get to a specific prompt

or at the prompt, type

`\list`
`\connect some-database-name`
`\q` or '\quit' to quit

`\dt *table_name*` to show a list of tables.
`select * from *table_name* where false;`

To get the table structure.

