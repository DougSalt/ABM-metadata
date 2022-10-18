#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi

# This program is going to gather all the folksonomy metadata stuff into a
# graphviz diagram.

nodes = {
    'Tags': 'ID_TAG',
    'Applications': 'ID_APPLICATION',
    'ContainerTypes': 'ID_CONTAINER_TYPE',
    'Studies': 'ID_STUDY',
    'Documentation': 'ID_DOCUMENTATION',
    'StatisticalMethods': 'ID_STATISTICAL_METHOD',
    'VisualisationMethods': 'ID_VISUALISATION_METHOD',
    }

working_dir = os.getcwd()

conn = ssrepi.connect_db(working_dir)

original_nodes = ssrepi.get_nodes(conn, nodes, ssrepi.labels())
possible_edges = ssrepi.get_edges(conn, ssrepi.derive_edges(), original_nodes)
active_nodes = ssrepi.remove_orphans(original_nodes, possible_edges)
active_edges = ssrepi.remove_edges(active_nodes, possible_edges)
ssrepi.draw_graph(active_nodes,active_edges,output="finegrain.dot")

ssrepi.disconnect_db(conn)
