# ssrepi\_cli.sh - the Bash interface libary for SSREPI

## SYNOPSIS

The library for doing (Social Simulation REPository Interface) SSREPI
provenance and metadata collection. This allow invocation of the interface from the command line and as such can be used in normal scripts. SLURM has been built in, although the queue management of SLURM is superior and the queueing mechanism

## DESCRIPTION

The following calls are available in Bash > 4.0.

## SSREPI\_application 

Creates an application entry in the database. This links to the actual
executable and should be used to invoke the actual process as the first
argument to [SSREPI\_call](#SSREPI_call) or [SSREPI\_invoke](#SSREPI_invoke).

This identifies a piece of callable code. This could be perl, R, an ELF
executable, Python or a Julia script, or even another Bash or zsh script.

### Mandatory parameters

These parameters are positional.

The source path for application.

### Optional parameters

+ --model - This is documentary and refers to the model this is running. This
  in conjuction with the project and study (a study is a thing we refer to as
  an experiment), will make this run unique
+ --name - A meaningful english name that can be used in the diagramming.

+ --instance - the type of container this is. Some containers are already
  created such as bash, perl, R, etc.

+ --licence - a string describing the licence

+ --description - descibes what the application does. This is not mandatory,
  but we strongly advise that this field is filled in any time it is available.
  This will take a multi-line string and the hard 3 speach mark type of string.

### Returns

## SSREPI\_argument

This sets some basic arguments that may be common to 

### Mandatory parameters

+ $

### Optional paarameters

### Returns

Nothing.

## SSREPI\_batch

Remember to put wait at the end of the script that uses this approach, as the
script in the foreground will just finish and leave the background processes to
run. This can have weird results.

## SSREPI\_content

Updates the content table.

## SSREPI\_contributor

Inserts a new contributor row, or updates and existing one.

## SSREPI\_hutton\_person

Inserts new Hutton person row, or updates and existing one. This is based on there being a user present in /etc/passwd file.
ps
## SSREPI\_implements
## SSREPI\_input
## SSREPI\_involvement
## SSREPI\_make\_tag
## SSREPI\_me
## SSREPI\_output
## SSREPI\_paper
## SSREPI\_parameter
## SSREPI\_person
## SSREPI\_person\_makes\_assumption
## SSREPI\_project
## SSREPI\_require\_exact
## SSREPI\_require\_minimum
## SSREPI\_run

This will interactively run an application. That is it will block

## SSREPI\_set
## SSREPI\_statistical\_method
## SSREPI\_statistical\_variable
## SSREPI\_statistics
## SSREPI\_study
## SSREPI\_tag
## SSREPI\_value
## SSREPI\_visualisation\_variable\_value
## SSREPI\_variable
## SSREPI\_visualisation
## SSREPI\visualisation\_method
## SSREPI\visualisation\_variable

## ENVRIONMENT VARIABLES

This enviroment inherits all the enviornment variables from [ssrepi.py](./ssrepi.1)

These are sourced from the first calling script. Obviously only processes downstream can be affected by modified values to these. 
### SSREPI\_MAX\_PROCESSES

### SSREPI\_SLURM

### SSREPI\_SLURM\_PREFIX

### SSREPI\_SLURM\_PENDING\_BLOCKS

### SSREPI\_STUDY



### SSREPI\_DBFILE

### SSREPI\_DBUSER

### SSREPI\_DBTYPE

## AUTHORS

Doug Salt, Lorenzo Milazzo, Gary Polhill

## REPORTING BUGS

## COPYRIGHT

Copyright © 2022 The James Hutton Institute.  License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.

This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

## SEE ALSO

[ssrepi.py](./ssrepi.1)

## STANDARDS

## HISTORY



