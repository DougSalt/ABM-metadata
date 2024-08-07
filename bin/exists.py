#!/usr/bin/env python3
"""A program to determine if a value exists in a database, from the CLI
"""

__copyright__ = "Copyright 2022"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope thaGt it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = "Gary Polhill, Lorenzo Milazzo"
__modified__ = "2017-04-20"


debug=False

import os, sys, getopt, re
import sqlite3

# I am going to have to think of a better way of doing this. Need to 
# research site level Python paths. Additionally I only want to import
# some functionality. In this instance 

sys.path.append("lib")
import ssrepi

table_parameter = re.compile(r'^--table=([A-Za-z0-9_]+)$')
column_parameter = re.compile(r'^([A-Za-z0-9_-]+)(=(.*?))?$')


class IllegalArgumentError(ValueError):
    pass

def parameters(conn, argv):
    """ Variable parameters for obtaining to check whether a record exists or  not
    This will be of the form:

        --table=some_table_name
        [--column_name=some value]...

    This will return 0 if the record exists non-zero otherwise.
    """

    table = None
    for arg in argv:
        if len(table_parameter.match(arg).groups()) != 0:
            table = table_parameter.match(arg).group(1)
            break

    
    if table == None:
        raise IllegalArgumentError("No --table argument supplied")
    if debug:
        sys.stderr.write("Doing table: " + table + "\n")
    
    tableClass = None
    try:    
        tableClass = getattr(ssrepi, table)    
    except:
        raise IllegalArgumentError("Invalid table name: " + table)

    columns = {}
    for arg in re.split(r' --',' '.join(argv)):
        if debug:
            sys.stderr.write("Processing argument: " + arg + "\n")
        if table_parameter.match(arg):
            pass
        elif column_parameter.match(arg).group(1) != None:
            col = column_parameter.match(arg).group(1).upper()
            col_argument = None
            if column_parameter.match(arg).group(3) != None:
                col_argument = column_parameter.match(arg).group(3)
            # Now make sure this column actually exists
            try:
                cur = conn.cursor()
                actual_columns = None
                if ssrepi.db_type == "sqlite3":
                    mysql = 'PRAGMA TABLE_INFO("' + tableClass().tableName() + '")'
                else:
                    mysql = "SELECT columns.column_name FROM information_schema.columns WHERE table_name = '" + tableClass().tableName().lower() + "'"
                cur.execute(mysql)
                result = cur.fetchall()
                if ssrepi.db_type == "sqlite3":
                    actual_columns = [ row['name'] for row in result ]
                else:
                    actual_columns = [ row['column_name'] for row in result ]
                found = False
                for col_details in actual_columns:
                    if col_details.lower() == col.lower():
                        found = True
                        break
                if not found:
                    raise IllegalArgumentError("Invalid column: " + col)
                columns[col] = col_argument

            except:
                raise IllegalArgumentError("Unexpected error for querying column")
            
        else:
            raise IllegalArgumentError("Invalid parameter: " + arg)

    if len(columns.keys()) == 0:
        raise IllegalArgumentError("No valid columns supplied")

    # TODO - Table specific validation.
    if table == "ArgumentValue":
        pass
    return (table,columns)
        
if __name__ == "__main__":
    columns = {}
    conn = ssrepi.connect_db()
    (table,columns) = parameters(conn,sys.argv[1:])
    tableClass = getattr(ssrepi, table)    
    row = tableClass(columns) 
    try:    
        result = row.query(conn.cursor())
    except: 
        print(False)
        ssrepi.disconnect_db(conn)
        sys.exit(0)
    ssrepi.disconnect_db(conn)
    print(True)
    sys.exit(0)
