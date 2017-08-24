#!/usr/bin/env python

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys
sys.path.append("lib")
import ssrepi_lib as ssrepi

# This program is going to gather all the serivces metadata stuff into a
# graphviz diagram.

nodes = {
    'Applications': 'ID_APPLICATION',
    'Computers': 'ID_COMPUTER',
    'Specifications': 'ID_SPECIFICATION',
    }


working_dir = os.getcwd()
db_specs = ssrepi.connect_db(working_dir)
edges = ssrepi.derive_edges()
print ("\n\n\n\n\nSPRINKLES\n--------------------------------------")
for (key,value) in edges.items():
	print("\nedgeName = " + str(key))
	for edgeKey, edgeValue in value.items():
		print(str(edgeKey) + " = " + str(edgeValue))

ssrepi.disconnect_db(db_specs[0])
