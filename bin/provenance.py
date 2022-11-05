#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import sys

sys.path.append("lib")
import ssrepi

nodes = {
    'Persons': ['ID_PERSON'],
    'Users': ['ID_USER'],
    'Computers': ['ID_COMPUTER'],
    'Applications': ['name'],
    'Processes': ['ID_PROCESS'],
    'Arguments': ['ID_ARGUMENT'],
    'Specifications': ['ID_SPECIFICATION'],
    'ArgumentValues': ['ID_ARGUMENT_VALUE'],
    'Studies': ['ID_STUDY'],
    'Containers': ['ID_CONTAINER'],
    'VisualisationMethods': ['ID_VISUALISATION_METHOD'],
    'StatisticalMethods': ['ID_STATISTICAL_METHOD'],
    'Visualisations': ['ID_VISUALISATION'],
    'Statistics': ['ID_STATISTIC'],
    'Parameters': ['ID_PARAMETER'],
    'StatisticalVariables': ['ID_STATISTICAL_VARIABLE'],
    'Value': ['ID_VALUE']
    }


conn = ssrepi.connect_db()
ssrepi.draw_graph(conn,nodes,output="provenance.dot")
ssrepi.disconnect_db(conn)
