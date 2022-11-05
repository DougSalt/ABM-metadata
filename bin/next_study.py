#!/usr/bin/env python3
"""A program to return the next study number to the CL@I
"""

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope thaGt it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = "Gary Polhill, Lorenzo Milazzo"
__modified__ = "2017-04-27"


import sys

# I am going to have to think of a better way of doing this. Need to 
# research site level Python paths. Additionally I only want to import
# some functionality. In this instance 

sys.path.append("lib")
import ssrepi

if __name__ == "__main__":
	table = None
	colums = {}
	conn = ssrepi.connect_db()
	(existence, nextStudy) = ssrepi.studies_table_exists(conn)
	print(nextStudy + 1)
