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


edges = { 
    'specification of': {
        'id': 'Specifications(ID_SPECIFICATION)',
        'source': 'Specifications(SPECIFICATION_OF)',
        'target': 'Computers(ID_COMPUTER)'
        },
    'dependency': { 
        'join': {'source': 'Dependencies(DEPENDANT)',
                 'target': 'Dependencies(DEPENDENCY)'
                 },
        'source': 'Applications(ID_APPLICATION)',
        'target': 'Applications(ID_APPLICATION)'
        },
    'meets': { 
        'join': {'source': 'Meets(COMPUTER_SPECIFICATION)',
                 'target': 'Meets(REQUIREMENT_SPECIFICATION)'
                 },
        'source': 'Specifications(ID_SPECIFICATION)',
        'target': 'Specifications(ID_SPECIFICATION)',
        },
    'exact': {
        'join': {'source': 'Requirements(APPLICATION)',
                 'target': 'Requirements(EXACT)'
                 },
        'source': 'Applications(ID_APPLICATION)',
        'target': 'Specifications(ID_SPECIFICATION)'
        },
    'minimum': {
        'join': {'source': 'Requirements(APPLICATION)',
                 'target': 'Requirements(MINIMUM)'
                 },
        'source': 'Applications(ID_APPLICATION)',
        'target': 'Specifications(ID_SPECIFICATION)'
        },
    'match': {
        'join': {'source': 'Requirements(APPLICATION)',
                 'target': 'Requirements(MATCH)'
                 },
        'source': 'Applications(ID_APPLICATION)',
        'target': 'Specifications(ID_SPECIFICATION)'
        },

    }
       

# This next dictionary affects how the diagram is labelled.  If the
# entry appears here then it will be used as a label.  Consequently to
# adjust, or add then change this dictionary.  Obviously bearing in
# mind that any entry in this array has to be for a valid table and an
# attribute for that table.

# Also note that some of these tables constitute edges rather than
# nodes, so it might be edges that are labelled with the information
# below.

labels = { 
    'Applications': [
        'ID_APPLICATION',
        'PURPOSE',
        'VERSION',
        'LICENCE',
        'LANGUAGE',
        ],
    'Specifications': [
        'ID_SPECIFICATION',
        'VALUE'
        ],
    'Computers': [
        'ID_COMPUTER',
        'NAME',
        'HOST_ID',
        'IP_ADDRESS',
        'MAC_ADDRESS'
        ]
    }

working_dir = os.getcwd()

db_specs = ssrepi.connect_db(working_dir)

originalNodes = ssrepi.get_nodes(db_specs[0], nodes, labels)
activeEdges = ssrepi.get_edges(db_specs[0], edges, originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="services.dot")

ssrepi.disconnect_db(db_specs[0])
