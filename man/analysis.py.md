# analysis.py - produces a dot file which contains the SSRepI analysis subgraph.

## SYNOPSIS

analysis.py

## DESCRIPTION

Produces a dot file, which then must be processed

```

## OPTIONS

This takes no options

## ENVRIONMENT 

### SSREPI\_DBTYPE

This may take the value "sqlite3" or "postgres". Any other values will result in malfunction.

### SSREPI\_DBNAME

For sqlite3 this is the file location of the sqlite3 database. It is not used if SSREPI_DBTYPE is set to "postgres".

### SSREPI\_DEBUG	

This may take any value as long as it is defined. If it is defined then debug is assumed to be on.

## EXIT STATUS

## RETURN VALUE

## EXAMPLES

## FILES

Expects there to be eiether a sqllite3 database or a postgres database present. The sqlite3 database is specified in the enviroment variable, 

## AUTHORS

Doug Salt, Lorenzo Milazzo, Gary Polhill

## REPORTING BUGS

## BUGS

## COPYRIGHT

Copyright © 2022 The James Hutton Institute.  License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.

This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

## SEE ALSO

## HISTORY



