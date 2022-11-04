#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi

# This program is going to gather all the serivces metadata stuff into a
# graphviz diagram.

nodes = {
    'Applications': ['name'],
    'Computers': ['ID_COMPUTER'],
    'Specifications': ['ID_SPECIFICATION'],
    }

working_dir = os.getcwd()

conn = ssrepi.connect_db(working_dir)
ssrepi.draw_graph(conn, nodes, output="services.dot")
ssrepi.disconnect_db(conn)
