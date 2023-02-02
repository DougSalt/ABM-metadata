#!/usr/bin/env python3
"""
A program to count the rows in a specific database.
"""

__copyright__ = "Copyright 2022"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope thaGt it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = "Gary Polhill, Lorenzo Milazzo"
__modified__ = "2017-04-20"

debug=False

import os, sys, getopt, re
import inspect

# I am going to have to think of a better way of doing this. Need to 
# research site level Python paths. Additionally I only want to import
# some functionality. In this instance 

sys.path.append("lib")
import ssrepi



total = 0
conn = ssrepi.connect_db()
for name, cls in inspect.getmembers(ssrepi):
    if inspect.isclass(cls) and issubclass(cls, ssrepi.Table) and cls != ssrepi.Table:
        total = total + cls.count(conn)

print(total)
sys.exit(0)
#
