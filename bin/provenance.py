#!/usr/bin/env python

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi_lib as ssrepi

nodes = {
    'Persons': 'ID_PERSON',
    'Users': 'ID_USER',
    'Computers': 'ID_COMPUTER',
    'Applications': 'ID_APPLICATION',
    'Processes': 'ID_PROCESS',
    'Arguments': 'ID_ARGUMENT',
    'Specifications': 'ID_SPECIFICATION',
    'ArgumentValues': 'ID_ARGUMENT_VALUE',
    'Studies': 'ID_STUDY',
    'Containers': 'ID_CONTAINER',
    'VisualisationMethods': 'ID_VISUALISATION_METHOD',
    'StatisticalMethods': 'ID_STATISTICAL_METHOD',
    'Visualisations': 'ID_VISUALISATION',
    'Statistics': 'ID_STATISTIC',
    'Parameters': 'ID_PARAMETER',
    'StatisticalVariables': 'ID_STATISTICAL_VARIABLE',
    'Value': 'ID_VALUE'
    }


working_dir = os.getcwd()

db_specs = ssrepi.connect_db(working_dir)

originalNodes = ssrepi.get_nodes(db_specs[0], nodes, ssrepi.labels())
activeEdges = ssrepi.get_edges(db_specs[0], ssrepi.derive_edges(), originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="provenance.dot")

ssrepi.disconnect_db(db_specs[0])
