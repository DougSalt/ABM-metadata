# PURPOSE

This repository is for the Miracle simulation metadata outputs specification.

# MANIFEST

+ README.md - this file
+ analysis.dot - a graphviz rendering of the analsysis subgraph.
+ bin - the directory containing all executables. These are all written in Python.
+ cfg - a directory used by the example code containing 
+ doc - documentation directory
+ example - the example code
+ finegrain.dot - a graphviz rendering of the finegrain sub-graph
+ folksonomy.dot
+ lib
+ man
+ project.dot
+ provenance.dot
+ save
+ services.dot
+ workflow.dot
+ workflow.pdf

# RUNNING THE EXAMPLE

To run the job

```
bin/clean.sh
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

then run

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

