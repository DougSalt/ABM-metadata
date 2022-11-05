# ssrepi.sh - interface libary for SSREPI

## SYNOPSIS

Some blurb

## DESCRIPTION

## CLASSES

### InvalidEntity(Exception):

#### Superclass Exception


### Table:
### Application:

#### Superclass Table

### Argument:

#### Superclass Table

### ArgumentValue:

### Assumption:

#### Superclass Table

### Assumption:

#### Superclass Table

### Computer:

#### Superclass Table

### Container:

#### Superclass Table

### ContainerType:

#### Superclass Table

### Content:

#### Superclass Table

### Context:

#### Superclass Table

### Contributor:

#### Superclass Table

### Dependency:

#### Superclass Table

### Documentation:

#### Superclass Table

### Employs:

#### Superclass Table

### Entailment:

#### Superclass Table

### Implements:

#### Superclass Table

### Input:

#### Superclass Table

### Involvement:

#### Superclass Table

### Meets:

#### Superclass Table

### Model:

#### Superclass Table

### Parameter:

#### Superclass Table

### Person:

#### Superclass Table

### PersonalData:

#### Superclass Table

### Pipeline:

#### Superclass Table

### Process:

#### Superclass Table

### Product:

#### Superclass Table

### Project:

#### Superclass Table

### Requirement:

#### Superclass Table

### Specification:

#### Superclass Table

### StatisticalInput:

#### Superclass Table

### StatisticalMethod:

#### Superclass Table

### StatisticalVariable:

#### Superclass Table

### Statistics:

#### Superclass Table

### Study:

#### Superclass Table

### Tag:

#### Superclass Table

### TagMap:

#### Superclass Table

### User:

#### Superclass Table

### Uses:

#### Superclass Table

### Value:

#### Superclass Table

### Variable:

#### Superclass Table

### Visualisation:

#### Superclass Table

### VisualisationMethod:

#### Superclass Table

### VisualisationValue:

#### Superclass Table

### InvalidDBSpec:

#### Superclass Exception

### InvalidNode:

#### Superclass Exception

### InvalidEdge:

#### Superclass Exception

## FUNCTIONS 

### dict_factory(cursor, row):
### connect_db(working_dir):

Will connect to either a sqlite3 or postgres database.
### disconnect_db(conn):
### create_tables(conn):
### set_debug(value):
### write_all_to_db(ss_rep, conn, order = None):
### initially_populate_db(ssrep_array):
### studies_table_exists(conn):
### print_values(ssr_dict):
### is_positive_int(s):
### iso8601(str):
### ip(str):
### mimetype(allowableMimeTypes):
### graph():
### derive_edges():
### derive_edge(schema):
### labels():
### get_label(schema):
### get_nodes(conn, nodes, labels):
### draw_nodes(conn, graph, nodes, labels):
### format_text(text, length=30):
### get_edges(conn, edges, activeNodes):
### remove_orphans(nodes, edges):
### remove_edges(nodes,edges):
### save_dot(nodes, edges, output=None):
### draw_graph (conn, nodes, output):

## OPTIONS

## ENVRIONMENT 

## EXIT STATUS

## RETURN VALUE

## EXAMPLES

## FILES

## AUTHORS

Doug Salt, Lorenzo Milazzo, Gary Polhill

## REPORTING BUGS

## BUGS

## COPYRIGHT

Copyright © 2022 The James Hutton Institute.  License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.

This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

## SEE ALSO

## HISTORY



