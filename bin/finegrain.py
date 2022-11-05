#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import sys

sys.path.append("lib")
import ssrepi

# The value part of the nodes key are the parts of the data that you want # emboldened if they are present. Note this can be a singleton or a list.

nodes = {
    'Applications': ['name'],
    'Containers': ['ID_CONTAINERS'],
    'ContainerTypes': ['ID_CONTAINER_TYPE'],
    'Contents': ['ID_CONTENT'],
    'StatisticalMethods': ['ID_STATISTICAL_METHOD'],
    'StatisticalVariables': ['ID_STATISTICAL_VARIABLE'],
    'VisualisationMethods': ['ID_VISUALISATION_METHOD'],
    'Parameters': ['ID_PARAMETERS'],
    'Persons': ['ID_PERSON'],
    'Visualisations': ['ID_VISULISATION'],
    'Assumptions': ['assumption', 'variable', 'person', 'statistics', 'visualisation'],
    'Statistics': ['ID_STATISTICS'],
    'Variables': ['ID_VARIABLE'],
    'Contexts': ['ID_CONTEXT'],
    'Value': ['ID_VALUE'],
    }

conn = ssrepi.connect_db()
ssrepi.draw_graph(conn,nodes,output="finegrain.dot")
ssrepi.disconnect_db(conn)
