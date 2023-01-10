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

### Optional parameters

### Returns

Nothing.

## SSREPI\_batch x

Remember to put wait at the end of the script that uses this approach, as the
script in the foreground will just finish and leave the background processes to
run. This can have weird results.

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_content

Updates the content table.

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_contributor

Inserts a new contributor row, or updates and existing one.

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_hutton\_person

Inserts new Hutton person row, or updates and existing one. This is based on there being a user present in /etc/passwd file.

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_implements
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_input
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_involvement
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_make\_tag
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_me
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_output
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_paper
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_parameter
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_person
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_person\_makes\_assumption
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_project
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_require\_exact
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_require\_minimum
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_run

This will interactively run an application. That is it will block

## SSREPI\_statistical\_method x
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_statistical\_variable x
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_statistical\_variable\_value x

Reifies the relationship between a set of statistics and a value, recording
when the result-of some statistical methood is used on a set of statistics.
If a statistical method used by the set of statistics employs a statistical
variable produced by a statistical method, then there should be an entry in
this table recording the actual result used.

### Mandatory parameters

#### The value

Can be any kind of single value.

#### Statistical variable 

The variable referring to the statistical variable in question.

#### A container

A container entry specifying the file/image/db in which the statistics reside.

#### The statistics

The set  of a statistics this refers to.

### Optional parameters

TODO
None of these three make any sense at the moment. The last two might, but the
irst certainly doesn't. I need to read this quite closely again.

+ --parameter -  I have no idea what this is and I need to look  at it
  properly

+ --visualisation-parameter - this is should be created when a visulisation
  is being created, but does not happen as yet. This should point to a
  visualisation

+ --statistics-parameter - this is should be created when a set of statistics
  are being created, but does not happen as yet. This should point to a set
  of statistics.

### Returns

Nothing as this is a setting operation

## SSREPI\_statistics x

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_study
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_make\_tag
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_tag x
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_value x
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_variable x
### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_visualisation x

A visualisation is the process of creating an image to depict one or more
(typically more than one) visualisation\_values.

This records an actual visualisation, the method, the way, or query to
produce this particular visulisation and the location of the resulting
visualisation.


### Mandatory parameters

#### Reference to the visualisation

This is not automatically generated (although it could be) and is used to
reference this particular instance of visualisation.

### Visualisation method

Point to the visualisation methode. This visualisation method is a description
of the visualisation method, what it does, how it done and what it produces.

### Visualisation query

The query sent to the implementation referenced in the visualisation method in
order to produce the instance of the visualisation.

### Location of this instance of visualisation

Self explanatory. This points to a container showing where the visulisation is
held.

### Returns

A reference to the visualisation object.

## SSREPI\_visualisation\_method x

### Mandatory parameters

### Optional parameters

### Returns

## SSREPI\_visualisation\_variable

This creates a statistical variable that is used for a visulisation method and creates a link from this variable to the visualisation method that uses it.

A statistical method is an approach to computing some statistics. It may be implemented in or as part of an application. A statistical method generates one or more statistical variables as its results, and may use the results of another statistical method in its computation. For example, computing the standard deviation of some data uses the mean of those data.

Each time a visualisation method is applied, a visualisation ([SSREPI_visualisation](#SSREPI\_visualisation)) entry should be created. For
each visulisation variable the visualisation method ([SSREPI_visualisation_method](#SSREPI_visualisation_method) employs, there should be
a StatisticalInput entry, and for each visualisation variable that is
generated-by the visualisation method, there should be a Value entry with the
result-of field containing the ID of the Statistics activity.

In essence this is a link from the visualisation variable to a particular value and a link to the actual instance of visualisation.

So I need to build a new primitive which takes a visualisation variable, or
statistical_variable and links it to a particular value using StatisticalInput

### Mandatory parameters

#### Reference to the visualisation variable

This is not automatically generated (although it could be) and is used to
reference this particular visualisation variable. This is normally a single woord and used to reference this particular visualisation variable.

### Description

Briefly in free form text what this 

### Data type

Point to the visualisation methode. This visualisation method is a description
of the visualisation method, what it does, how it done and what it produces.

### Visualisation method

The visualisation method [SSREPI\_visualisation\_method](#SSREPI_visualisation_method)

### Location of this instance of visualisation

### Optional parameters

### Returns

## SSREPI\_visualisation\_variable\_value

Reifies the relationship between visualisation and value, recording when the
result-of a visualisation methood is used by a visualisation. If a
visualisation method used by the visualisation employs a statistical variable
generated-by a visualisation method, then there should be an entry in this
table recording the actual result used.

### Mandatory parameters

#### The value

Can be any kind of single value.

#### Visualisation variable 

The variable referring to the visualisation variable in question.

#### A container

A container entry specifying the file/image/visualisation/db in which the visualisation resides.

#### The visualisation

$4 - instance of a visualisation this refers to.

### Optional parameters

TODO
None of these three make any sense at the moment. The last two might, but the
irst certainly doesn't. I need to read this quite closely again.

+ --parameter -  I have no idea what this is and I need to look  at it
  properly

+ --visualisation-parameter - this is should be created when a visulisation
  is being created, but does not happen as yet. This should point to a
  visualisation

+ --statistics-parameter - this is should be created when a set of statistics
  are being created, but does not happen as yet. This should point to a set
  of statistics.

### Returns

Nothing as this is a setting operation

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



