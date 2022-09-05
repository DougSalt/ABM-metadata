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

# DATABASES

## POSTGRES

```
brew install postgresql
brew install libmagic
brew install coreutils
```
add to .zshrc
```
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
```


pip install --upgrade pip
pip uninstall psycopg2
pip install psycopg2-binary --no-cache-dir
pip install rfc3987
pip install python-magic-bin==0.4.14
pip install graphviz

`psql` to get to the database prompt.
`psql some-database-name` to get to a specific prompt

or at the prompt, type

`\list`
`\connect some-database-name`
`\q` or '\quit' to quit

`\dt *table_name*` to show a list of tables.
`select * from *table_name* where false;`

To get the table structure.

# NOTES

## 2017-07-28

OK where you are at:

You are tryin to simplify the drawing, and have implemented the code to define all the possible edges (including 3 part relationships), although that is not implemented yet.

You are using new_project.py to do this (considerably simplified from
project.py), but are stuck on the fact that it appears that the home key for
Containers apppears to be ID_CONTAINER_TYPES. So wrong. This is probably
something to do with foreignKeys in ssrep_lib.py, but it needs investigating.

You have are doing a single run to generate diagrams, so do not clear out the directory.

## 2018-01-09

I tried a run before Xmas, and it looks like somebody stopped it, so I will try again.

## 2022-08-26

This is running on sqllite3, so the tasks are

1. debug the code so it is working on a local database
2. check the postgres setup is still working - this code appears to have disappeared.
3. use the example you have set up to run on postgres
4. learn flex and yacc to decompose and bash script - this will be useful for stuff elsewhere.

As of this date I have converted the code to python3 but there is still something wrong. I am not sure whether the conversion has introduced a bug or               

## 2022-08-16

Well that is a bit of blow. I am convinced I had mostly finished the coding for
postgres and indeed was ready to set it up and test, but it appears not, or the
code has been lost. I am getting an awful sense of deja-vu going through the
code, I know I made extensive notes about this, but cannot for the life of me,
find them.
