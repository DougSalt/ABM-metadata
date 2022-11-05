#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import sys

sys.path.append("lib")
import ssrepi

# This program is going to gather all the project metadata stuff into a
# graphviz diagram.

nodes = {
    'Persons': ['ID_PERSON'],
    'Projects': ['ID_PROJECT'],
    'Applications': ['name'],
    'Documentation': ['ID_DOCUMENTATION'],
    'Containers': ['ID_CONTAINER']
    }

conn = ssrepi.connect_db()
ssrepi.draw_graph(conn,nodes,output="project.dot")
ssrepi.disconnect_db(conn)
