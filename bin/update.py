#!/usr/bin/env python3
"""A program to insert, or update values in the database, from the CLI
"""

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope thaGt it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = "Gary Polhill, Lorenzo Milazzo"
__modified__ = "2017-03-02"



import os, sys, getopt, re
import sqlite3
import psycopg2
from psycopg2.extras import RealDictCursor

# I am going to have to think of a better way of doing this. Need to 
# research site level Python paths. Additionally I only want to import
# some functionality. In this instance 

import ssrepi

table_parameter = re.compile(r'^--table=([A-Za-z0-9_]+)$')
column_parameter = re.compile(r'^([A-Za-z0-9_-]+)(=(.*?))$')


class IllegalArgumentError(ValueError):
	pass

def parameters(conn, argv):
	""" Variable parameters for updating the database.
	This will be of the form:

		--table=some_table_name
		[--column_name=some value]...

	It should be fairly evident that the parameters will change
	dependent upon the table.

	"""

	table = None
	for arg in argv:
		if len(table_parameter.match(arg).groups()) != 0:
			table = table_parameter.match(arg).group(1)
			break

	
	if table == None:
		raise IllegalArgumentError("No --table argument supplied")
	if ssrepi.debug:
		sys.stderr.write("Doing table: " + table + "\n")
	
	tableClass = None
	try:	
		tableClass = getattr(ssrepi, table)	
	except:
		raise IllegalArgumentError("Invalid table name: " + table)

	columns = {}
	for arg in re.split(r' --',' '.join(argv)):
		if ssrepi.debug:
			sys.stderr.write("Processing argument: " + arg + "\n")
		if table_parameter.match(arg):
			pass
		elif (column_parameter.match(arg).group(1) != None and 
		      column_parameter.match(arg).group(3) != None):
			col = column_parameter.match(arg).group(1).upper()
			col_argument = column_parameter.match(arg).group(3)
			# Now make sure this column actually exists
			try:
				cur = conn.cursor()
				mysql = None
				actual_columns = None
				if ssrepi.db_type == "sqlite3":
					mysql = 'PRAGMA TABLE_INFO("' + tableClass().tableName() + '")'
					cur.execute(mysql)
				else:
					mysql = "SELECT columns.column_name FROM information_schema.columns WHERE table_name = '" + tableClass().tableName().lower() + "'"
				cur.execute(mysql)
				result = cur.fetchall()
				if ssrepi.db_type == "sqlite3":
					actual_columns = [ row['name'] for row in result ]
				else:
					actual_columns = [ row['column_name'] for row in result ]
				if ssrepi.debug:
					sys.stderr.write(mysql + "\n")
				found = False
				for col_details in actual_columns:
					if ssrepi.debug:
						sys.stderr.write("Fields: " + str(col_details) + " on " + col.lower() + "\n")
					if col_details.lower() == col.lower():
						found = True
						break
				if not found:
					raise IllegalArgumentError("Invalid column: " + col + "\n")
				columns[col] = col_argument



			except IllegalArgumentError as e:
				sys.stderr.write("Error: " + str(e) + "\n")
				raise IllegalArgumentError("Unexpected error for querying column")
			except Exception as e:
				sys.stderr.write("Error: " + 
					type(e).__name__ + 
					" - " +
					str(e) + "\n")
				raise e
		else:
			raise IllegalArgumentError("Invalid parameter: " + arg)

	if len(columns.keys()) == 0:
		raise IllegalArgumentError("No valid columns supplied")

	# TODO - Table specific validation.
	if table == "ArgumentValue":
		pass
	return (table, columns)
		
if __name__ == "__main__":
	table = None
	colums = {}
	conn = ssrepi.connect_db()
	(table,columns) = parameters(conn,sys.argv[1:])
	tableClass = getattr(ssrepi, table)	
	row = tableClass(columns) 
	try:
		row.add(conn.cursor())
	except (sqlite3.IntegrityError, psycopg2.errors.UniqueViolation, psycopg2.errors.NotNullViolation) as e:
		try:
			row.update(conn.cursor())
		except:
			raise
	except Exception as e:
		sys.stderr.write("Error: " + 
			type(e).__name__ + 
			" - " +
			str(e))
		raise 
	ssrepi.disconnect_db(conn)
	result = re.sub(r' AND ',',', row.getPrimaryKeys())
	result = re.sub(r'^.* = ','',result)
	result = re.sub(r'[\'\"]','',result)
	if ssrepi.debug:
		sys.stderr.write("Printing: " + result + "\n")
	print(result)
