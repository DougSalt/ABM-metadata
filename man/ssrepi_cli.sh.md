# ssrepi\_cli.sh - the Bash interface libary for SSREPI

## SYNOPSIS

The library for doing (Social Simulation REPository Interface) SSREPI
provenance and metadata collection. This allow invocation of the interface from
the command line and as such can be used in normal scripts. SLURM has been
built in, although the queue management of SLURM is superior and the queueing
mechanism.

Note nothing is stored in this table. This *is all metadata*. Of note, however
is the fact that anyting contained in a file type structure, such as data,
code, etc is _always_ stored in a *container*. *Container* is the term we have
used to denote something which holds a series of *values*. A value is as the
name implies some value and could be a string, number, etc. A container is just
a collection of such values, and therefore could be a file, a diagram, a
database, a csv file, etc.

## DESCRIPTION

The following calls are available in Bash > 4.0.

## SSREPI\_application 

Creates an application entry in the database. This links to the actual
executable or script and should be used to invoke the actual process as the first
argument to [SSREPI\_call](#SSREPI_call) or [SSREPI\_invoke](#SSREPI_invoke).

This identifies a piece of callable code. This could be perl, R, an ELF
executable or script, Python or a Julia script, or even another Bash or zsh script.

### Mandatory parameters

These parameters are positional.

#### The source container for the application.

Which container references the location of the application.

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

+ --seperator - this is the separator between arguments. On all current
  operating systems this is some form of white space, so the default for this
  is the space character.

### Returns

The id for this application. This is the same as the output and because of the
methodology used is may therefore be updated or created, hence this being both
an input and an output parameter. This is generally a single instance of a
string.

## SSREPI\_argument

A command-line argument accepted by an application
[SSREPI_application](#SSREPI_application). Commands vary hugely in how they
parse arguments on the command line, and this table needs to make clear how to
build a command line that the Application can use. To be clear, a command line
is a string of text that is given to a shell (DOS, bash, etc.) to initiate a
batch job.

An argument is populated by and argument value. This is done at invocation and
automatic. Hence this argument describes the argument. This means that an
application invoked knows its arguments and what is allowable. This allows
for the automatic testing and  population of the argument. This also means it
is better to specify the arguments comprehensively when using this primitive,
even if the argument is not currently used in the experiment actually being
documented.

### Mandatory parameters

These parameters are positional.

#### Application identifier

A reference to the application for which this is is an argument.

#### Argument identifier

The id for this argument, and used to reference this particular argument from
the first use of htis primitive. This is the same as the output and because of
the methodology used is may therefore be updated or created, hence this being
both an input and an output parameter. This is generally a single instance of a
string.

### Optional parameters

+ --description - documentary description of what the argument does.

+ --type - this is whether it is required, optional or flag. The default is
  optional

+ --name - if this is not a positional name then this is conjunction with the
  separator and the assignment\_operator will form the argument.

  For example if the argument is of the type optional, the name is "path" the
  separator is "--" and the assignment operator is "=" then the argument might
  eventually look like

```
  --path=some_example_file_name.csv
```

  If this is a non positional argument then this argument is mandatory.

+ --seperator - if this is not a positional name then this is conjunction with
  the argument name and the assignment\_operator will form the argument.

  For example if the argument is of the type optional, the name is "path" the
  separator is "--" and the assignment operator is "=" then the argument might
    eventually look like

```
  --path=some_example_file_name.csv
```

  The default for this is "--". Note there are some unix command variants that
  use a single dash in this postion and some Windows arguments which use the
  forward slash.

+ --order\_value - if the argument is positional, then this is the position in
  which the argument appears

+ --arity - the number of parts of the argument. This defaults to a single part.

+ --range - a string to validate the range of the argument. This is generally a
  regex but might be a file type.

+ --argsep - if the arity is greater than one, then this argument is useful.
  The default is ','. This is the seperator between different elements of the
  argument.

+ --short\_name - Part of the Unix convention on arguments (unfortunately not
  always followed) is that there are short names for some arguments. These
  short names are generally on one character long, and preceded by a single
  dash rather than two dash as is the default folr  

### Returns

The id for this argument. This is a reference to the application. This is the
same as the output and because of the methodology used is may therefore be
updated or created, hence this being both an input and an output parameter.

## SSREPI\_batch

This is the non-blocking launcher of an application.

Remember to put wait at the end of the script that uses this approach, as the
script in the foreground will just finish and leave the background processes
to run. This can have weird results.

The only difference between this an [SSREPI\_run](#SSREPI_run) is this is
non-blocking. So the use of this invocation will launch the application and not
wait for the response.

### Mandatory parameters

These parameters are positional.

#### Application identifier or application path.

This the variable containing the reference to the application for which this is
is an argument. Or alternatively it might contain

### Optional parameters

+ --SSREPI-argument - there may be multiple instances of this. This references
  the application [SSREPI\_application](#SSREPI_application) argument entry
  in the database and encodes an actual argument to the program being run.
  The definition of the argument defines its position or how the argument is
  entered, so the order in which this parameter is used is unimportant; the
  only necessary prerequisite is that the previous definitions of arguments
  must be comprehensive. Therefore it is better to define all arguments even
  if those arguments are never actually used in a run. This also makes the
  code re-usable.

+ --cwd - the directory in which the application should run. This argument can
  be used only once. If there are multiple instances then the last will be
  used.

+ --SSREPI-input - this is an input file to the application
  [SSREPI\_application](#SSREPI_application). The existence of this file will
  be determined. This argument can appear as an input and an argument,
  although often input files may be unstated in the arguments.

+ --SSREPI-output - this is an output file to the application
  [SSREPI\_application](#SSREPI_application). The existence of this file will
  be determined. This argument can appear as an output and an argument,
  although often output files may be unstated in the arguments.

This also takes all the optional arguments from an application definition as
well [SSREPI\_application](#SSREPI_application).

### Returns

Nothing. This is a setter and  not a function.

## SSREPI\_content

Updates the content table.  Content acts as a bridge from container type, which in this case is one of the input, output or argument types ([SSREPI_input](#SSREPI_input), [SSREPI_output](#SSREPI_output) or [SSREPI_argument](#SSREPI_argument)) to a named variable of interest ([SSREPI_variable](#SSREPI_variable)), specifying that such a variable appears in some or all instances of these input/output/argument types. It is associated with fine-grained provenance metadata.

### Mandatory parameters

These parameters are positional.

#### Container type

The type of container type the variable, statistical\_variable. At present this
is restricted to the output from a ([SSREPI_input](#SSREPI_input), a
[SSREPI_output](#SSREPI_output) or a [SSREPI_argument](#SSREPI_argument).k

### Optional parameters

+ --optionality - can be "always" or "depends"

+ --locator - where in a csv, using row:x, column:y, or field:z in a database.
  This has yet to be implemented.

+ --space-locator - if --is-space is set to true in the variable entry, then where in a csv, using row:x, column:y, or field:z in a database.

+ --time-locator - if --time is set to true in the variable entry, where in a csv, using row:x, column:y, or field:z in a database.

+ --link-locator - if --is-link is set to true in the variable entry, where in a csv, using row:x, column:y, or field:z in a database.

+ --agent-locator - if --is-agent is set to true in the variable entry, where in a csv, using row:x, column:y, or field:z in a database.

+ --variable - the variable that is being linked to a container type 

+ --visualisation\_method - the visualisation method, if this involes a visualisation method

+ --statistical\_variable - the statistical_method involved, if this is for a set of statistics or a visualisation.

### Returns

A reference  to that  content bridge

## SSREPI\_contributor

Associates a contributor with a particular script or executable. A contributor is necessarily a person. 

### Mandatory parameters

These parameters are positional.

#### Application ID

A reference to the executable or script with with which the person is going to be associated with as a contributor.

#### Person ID

The person who has made a contribution to the executable or script referenced above. Note this is not necessarily as author, but might be a maintainer, an enhancer or a curator.

#### Type of contribution

Author, designer, programmer, i.e. any string with relevant semantic loading.

### Returns

A contributor ID.

## SSREPI\_hutton\_person

Inserts new Hutton person into the database, or updates and existing one. This is based on there being a user present in something corrresponding to the /etc/passwd file.

### Mandatory parameters

These parameters are positional.

#### User

Actual operating system user. The assumption is that this will allow access to personal information of the user in question.

### Returns

Person ID

## SSREPI\_implements

Reified relationship between StatisticalMethods or VisualisationMethods and Applications that implement them.

### Mandatory parameters

These parameters are positional.

#### Application ID

### Optional parameters

Only single one of the following may be used.

+ --statistical_method -

+ --visualisation_method - 

+ --library - Library containing the function if appropriate

+ --function - Function in the language of the Application or provided by the application that implements the method

### Returns

This is a setting routine and not a function and has no return.

## SSREPI\_input

### Mandatory parameters

These parameters are positional.

#### Application ID

This is an input type for an executable or script. This has to define an input for to allow the value to be set as an input. If this is so defined, then the presence of the input file is checked for before the script or executable is run.

#### Container-type ID

The defines the container type. A container type may be thought as a type of input or output. Container types are less specific than this, but the code as it stands just deals with very generalised container types, such as code and more specific container types such as input and outputs to executables and other scripts.

#### Pattern

A command that verify the container type. This might be a file inspection or a regular expression on the file name. File inspection is preferred as this actually verifies the content of a container type, rather than just its existence.

### Returns

Input type ID

## SSREPI\_involvement
  
Links personnel to a particular study.

### Mandatory parameters

These parameters are positional.

#### Study ID

The reference to the study that is being linked to.

#### Person ID

A reference to the person involved in the study. The reference is generated b y
creating a person using [SSREPI\_person](#SSREPI_person) and
[SSREPI\_hutton\_person](#SSREPI_hutton_person).

#### Role

This is a string and is unvalidated so might be anything. For example "planner", "developer", "project leader" or some such.

### Returns

This is a setter, and there has no return as it is not a function.

## SSREPI\_make\_tag

### Mandatory parameters

These parameters are positional.

#### Tag ID

How the tag will be referred to, it is also a reference to the tag so must be unique.

#### A description of the tag

A piece of text giving a human-readable explanation of the tag.

### Returns

Tag ID

This is identical to the tag ID in the parameters. This is due to the overall
design which stresses idempotenency.

## SSREPI\_me

If no parameters are provided will provide the Application ID of the script (and hopefully executable or script that is currently being run). 

### Optional parameters

This can be the path name of the application being run, or an application ID.

### Returns

This returns the application ID

## SSREPI\_output

### Mandatory parameters

These parameters are positional.

#### Application ID

#### Container-type ID

#### Pattern

### Returns

The output type ID.

## SSREPI\_paper

### Mandatory parameters

These parameters are positional.

#### The path to the document

#### Person ID who has the paper

#### Person ID from whom the paper was obtained.

#### Study ID the paper refers to.

#### Date of publication of the paper.

YYYY-MM-DD

### Returns

Paper ID

## SSREPI\_parameter

A Parameter is the name of a parameter taken by a statistical or visualisation method, used to configure the way it behaves. For example, in the case of R’s rpart() function, parameters are the data stored in the rpart.control() list.

### Mandatory parameters

These parameters are positional.

#### Parameter ID

### Optional parameters

+ --statistical_method -

+ --visualisation_method -

### Returns

Parameter ID

## SSREPI\_person

### Mandatory parameters

These parameters are positional.


### Optional parameters

### Returns

Person ID

## SSREPI\_person\_makes\_assumption

### Mandatory parameters

These parameters are positional.

#### Person ID

#### Assumption ID

This create the assumption as well and attaches to the person in person ID.

#### Description of the assumption

### Optional parameters

### Returns

ID Assumption

## SSREPI\_project

### Mandatory parameters

These parameters are positional.

#### Project ID

### Optional parameters

+ --title

+ --funder

+ --grant_id

### Returns

Project ID

## SSREPI\_require\_exact

### Mandatory parameters

These parameters are positional.

#### Application ID

#### Specification ID

#### Desired version

#### Actual version

### Returns

Returns 1 for meets the specification, 0 otherwise.

## SSREPI\_require\_minimum

### Mandatory parameters

These parameters are positional.

#### Application ID

#### Specification ID

#### Desired version

#### Actual version

### Returns

Returns 1 for meets the specification, 0 otherwise.

## SSREPI\_run

This will interactively run an application. That is it will block

The only difference between this an [SSREPI\_batch](#SSREPI_batch) is this is blocking. So the use of this invocation will launch the application and will wait for the response.

### Mandatory parameters

These parameters are positional.

#### Application identifier or application path.

This the variable containing the reference to the application for which this is is an argument. Or alternatively it might contain

### Optional parameters

+ --SSREPI-argument - there may be multiple instances of this. This references
  the application [SSREPI\_application](#SSREPI_application) argument entry
  in the database and encodes an actual argument to the program being run.
  The definition of the argument defines its position or how the argument is
  entered, so the order in which this parameter is used is unimportant; the
  only necessary prerequisite is that the previous definitions of arguments
  must be comprehensive. Therefore it is better to define all arguments even
  if those arguments are never actually used in a run. This also makes the
  code re-usable.

+ --cwd - the directory in which the application should run. This argument can
  be used only once. If there are multiple instances then the last will be
  used.

+ --SSREPI-input - this is an input file to the application
  [SSREPI\_application](#SSREPI_application). The existence of this file will
  be determined. This argument can appear as an input and an argument,
  although often input files may be unstated in the arguments.

+ --SSREPI-output - this is an output file to the application
  [SSREPI\_application](#SSREPI_application). The existence of this file will
  be determined. This argument can appear as an output and an argument,
  although often output files may be unstated in the arguments.

This also takes all the optional arguments from an application definition as
well [SSREPI\_application](#SSREPI_application).

### Returns

Nothing. This is not a function.

## SSREPI\_statistical\_method

This declares a statistical method. A statistical method is an approach to
computing some statistics. It may be implemented in or as part of an
application. A statistical method generates one or more statistical variables [SSREPI\_statitical_variable](#SSREPI_statistical_variable)
as its results, and may use the results of another statistical method in its
computation. For example, computing the standard deviation of some data uses
the mean of those data.

### Mandatory parameters

These parameters are positional.

#### Statistical method ID

#### Description

A mandatory set of text describing the statistical method.

### Returns

Statistical method ID. This is identical to the statistical method ID in the
parameters. This is due to the overall design which stresses idempotenency.
This allows the instantiation or update of a particular statistical method.

## SSREPI\_statistical\_variable

A name for (one of) the result(s) of a statistical method
[SSREPI\_statistical\_method](#SSREPI_statistical_method).

Each time a statistical method is applied, a Statistics entry should be
created. For each StatisticalVariable the StatisticalMethod Employs, there
should be a StatisticalInput entry, and for each StatisticalVariable that is
generated-by the StatisticalMethod, there should be a Value entry with the
result-of field containing the ID of the Statistics activity.

### Mandatory parameters

These parameters are positional.

#### Statistical variable ID

#### Description

#### Data type

#### Generated by

### Optional parameters

### Returns

Statistical variable ID

## SSREPI\_statistical\_variable\_value x

Reifies the relationship between a set of statistics and a value, recording
when the result-of some statistical methood is used on a set of statistics.
If a statistical method used by the set of statistics employs a statistical
variable produced by a statistical method, then there should be an entry in
this table recording the actual result used.

### Mandatory parameters

These parameters are positional.

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
None of these following three make any sense at the moment. The last two might,
but the first certainly doesn't. I need to read this quite closely again.

+ --parameter -  I have no idea what this is and I need to look  at it
  properly. This may even removed.

+ --visualisation-parameter - this is should be created when a visualisation
  is being created, but does not happen as yet. This should point to a
  visualisation

+ --statistics-parameter - this is should be created when a set of statistics
  are being created, but does not happen as yet. This should point to a set
  of statistics.

### Returns

Nothing as this is a setting operation

## SSREPI\_statistics x

Statistics are activities that compute  and populate the values of statistical
rvariables. They operate on raw data that are retrieved from the values using a
query. To replicate a set of statistics, the query can be rerun, selecting
values that are pointed to by containers entries.

### Mandatory parameters

These parameters are positional.

#### ID for this statistic

The id for this statistic. This is the same as the output and because of the
methodology used is may therefore be updated or created, hence this being both
an input and an output parameter. This is generally a single instance of a
string.

#### The statistical method

#### Query used to prodce the statistic

This could be in the form of how to run a command, a SQL query, or anything relevant.

### Optional parameters

### Returns

The id for this statistic. This is the same as the input and because of the
methodology used is may therefore be updated or created, hence this being both
an input and an output parameter.

## SSREPI\_study

A Study is a piece of work at some level of aggregation, which allows
simulation outputs to be grouped together. Studies can be parts of other
Studies. For example, a Study might be a simulation experiment, that is part of
another Study to prepare a publication. Multiple studies make up a project.

### Mandatory parameters

These parameters are positional.

#### Study ID

#### Project ID

### Optional parameters

+ --description

+ --start_time YYYY-MM-DD

+ --end_time YYYY-MM-DD

### Returns

Study ID

## SSREPI\_set

Set the default parameters for calls to functions.

### Optional parameters

+ --study

+ --model

+ --version

+ --licence

### Returns 

Nothing. This is a setter and not a function.

## SSREPI\_make\_tag

### Mandatory parameters

These parameters are positional.

#### Tag ID

#### Description

### Returns

Tag ID

## SSREPI\_tag

### Mandatory parameters

These parameters are positional.

#### Tag ID

### Optional parameters

Although these parameters are optional - there should at least be one of them.

+ --documentation

+ --person

+ --study

+ --application

+ --container

+ --container_type

+ --other_tag

+ --study

+ --statistical_method

+ --visualisation_method

### Returns

Does not return anyting as this is a setter and not a function.

## SSREPI\_value x

Value of a Variable, recorded in some Container. As currently, planned, it is not proposed to store these values in a table; rather, to use the original output data. Hence this table has a ‘virtual’ presence and will need to be generated as required given a query using it. The format and units attributes are stored as information in the Content of the ContainerType for the Variable the Value is for.

### Mandatory parameters

These parameters are positional.

#### Value

#### Value ID

#### Container ID

### Optional parameters

+ --statistical_variable

+ --parameter

+ --statistical_parameter

+ --visual_parameter

+ --result_of

+ --time

+ --agent

+ --link

### Returns

Nothing. This is a setter and not a function.

## SSREPI\_variable

A Variable of interest (or potential interest), Values of which are stored in Containers of certain ContainerTypes.

### Mandatory parameters

These parameters are positional.

#### Variable ID

#### Description

#### Data type

### Returns

Variable ID

## SSREPI\_visualisation

A visualisation is the process of creating an image to depict one or more
(typically more than one) visualisation\_values.

This records an actual visualisation, the method, the way, or query to
produce this particular visulisation and the location of the resulting
visualisation.

### Mandatory parameters

These parameters are positional.

#### Reference to the visualisation

This is not automatically generated (although it could be) and is used to
reference this particular instance of visualisation.

### Visualisation method

Points to the visualisation methode. This visualisation method is a description
of the visualisation method, what it does, how it done and what it produces.

### Visualisation query

The query sent to the implementation referenced in the visualisation method in
order to produce the instance of the visualisation.

### Location of this instance of visualisation

Self explanatory. This points to a container showing where the visulisation is
held.

### Returns

A reference to the visualisation object.

## SSREPI\_visualisation\_method

This table describes methods for generating Visualisations, which then may appear in the Content of a Container produced by a Process running an Application that Implements it.

### Mandatory parameters

These parameters are positional.

#### Visualisation method ID

#### Description

### Returns

Visualisation method ID

## SSREPI\_visualisation\_variable

This creates a statistical variable that is used for a visulisation method and
creates a link from this variable to the visualisation method that uses it.

A statistical method is an approach to computing some statistics. It may be
implemented in or as part of an application. A statistical method generates one
or more statistical variables as its results, and may use the results of
another statistical method in its computation. For example, computing the
standard deviation of some data uses the mean of those data.

Each time a visualisation method is applied, a visualisation
([SSREPI_visualisation](#SSREPI\_visualisation)) entry should be created. For
each visulisation variable the visualisation method
([SSREPI_visualisation_method](#SSREPI_visualisation_method) employs, there
should be a StatisticalInput entry, and for each visualisation variable that is
generated-by the visualisation method, there should be a Value entry with the
result-of field containing the ID of the Statistics activity.

In essence this is a link from the visualisation variable to a particular value
and a link to the actual instance of visualisation.

So I need to build a new primitive which takes a visualisation variable, or
statistical_variable and links it to a particular value using StatisticalInput

### Mandatory parameters

These parameters are positional.

#### Reference to the visualisation variable

This is not automatically generated (although it could be) and is used to
reference this particular visualisation variable. This is normally a single
woord and used to reference this particular visualisation variable.

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

These parameters are positional.

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



