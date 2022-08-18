#!/usr/bin/env python3

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi

# This program is going to gather all the analysis metadata stuff into a
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
db_specs = ssrepi.connect_db(working_dir)
originalNodes = ssrepi.get_nodes(db_specs[0], nodes, ssrepi.labels())
activeEdges = ssrepi.get_edges(db_specs[0], ssrepi.derive_edges(), originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="project_metadata.dot")

ssrepi.disconnect_db(db_specs[0])
