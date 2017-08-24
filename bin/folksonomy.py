#!/usr/bin/env python

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi_lib as ssrepi

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


edges = { 
    'has container tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(CONTAINER)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'Containers(ID_CONTAINER)',
	'label':  'tag'
        },
    'has container type tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(CONTAINER_TYPE)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'ContainerTypes(ID_CONTAINER_TYPE)',
	'label':  'tag'
        },
    'has applicaton tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(APPLICATION)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'Applications(ID_APPLICATION)',
	'label':  'tag'
        },
    'has documentation tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(DOCUMENTATION)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'Documentation(ID_DOCUMENTATION)',
	'label':  'tag'
        },
    'has study tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(STUDY)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'Studies(ID_STUDY)',
	'label':  'tag'
        },
    'has statistical method tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(STATISTICAL_METHOD)'
                 },
        'source': 'Tags(ID_TAG)',
        'target': 'StatisticalMethods(ID_STATISTICAL_METHOD)',
	'label':  'tag'
        },
    'has visualisation method tag': { 
        'join': {
                'source': 'TagMaps(TAG)',
		'target': 'TagMaps(VISUALISATION_METHOD)'
                },
        'source': 'Tags(ID_TAG)',
        'target': 'VisualisationMethods(ID_VISUALISATION_METHOD)',
	'label':  'tag'
        }
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
    'Containers': [
        'ID_CONTAINER',
        'LOCATION_TYPE',
        'LOCATION_VALUE',
        'SIZE',
        'CREATION_TIME',
        'MODIFICATION_TIME',
        'UPDATE_TIME',
        'HASH'
        ],
    'ContainerTypes': [
        'ID_CONTAINER_TYPE',
        'DESCRIPTION',
        'FORMAT',
        'IDENTIFIER'
        ],
    'Documentation': [
        'ID_DOCUMENTATION',
        'TITLE',
        'DATE'
        ],
    'Studies': [
        'ID_STUDY',
        'LABEL',
        'DESCRIPTION',
        'START_TIME',
        'END_TIME'
        ],
     'StatisticalMethods' : [
	'ID_STATISTICAL_METHOD'
	],
     'VisualisationMethods' : [
	'ID_VISUALISATION_METHOD'
	],
     'Tags' : [
	'ID_TAG'
	]
    }

working_dir = os.getcwd()

db_specs = ssrepi.connect_db(working_dir)

originalNodes = ssrepi.get_nodes(db_specs[0], nodes, labels)
activeEdges = ssrepi.get_edges(db_specs[0], edges, labels, originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="folksonomy.dot")

ssrepi.disconnect_db(db_specs[0])
