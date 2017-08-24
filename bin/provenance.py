#!/usr/bin/env python

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("/mnt/storage/doug/SSS/lib")
import ssrepi_lib_1_1_6 as ssrepi

# This program is going to gather all the folksonomy metadata stuff into a
# graphviz diagram.

nodes = {
    'Persons': 'ID_PERSON',
    'Users': 'ID_USER',
    'Computers': 'ID_COMPUTER',
    'Applications': 'ID_APPLICATION',
    'Processes': 'ID_PROCESS',
    'Arguments', 'ID_ARGUMENT',
    'Specifications': 'ID_SPECIFICATION',
    'ArgumentValues': 'ID_ARGUMENT_VALUE',
    'Studies': 'ID_STUDY',
    'Containers': 'ID_CONTAINER'
    'VisualisationMethods': 'ID_VISUALISATION_METHOD',
    'StatisticalMethods': 'ID_STATISTICAL_METHOD',
    'Visualisations': 'ID_VISUALISATION',
    'Statistics': 'ID_STATISTIC',
    'Parameters': 'ID_PARAMETER',
    'StatisticalVariables': 'ID_STATISTICAL_VARIABLE',
    'Values': 'ID_VALUE'
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
    'contributor to application': { 
        'join': {'source': 'Contributors(CONTRIBUTOR)',
                 'target': 'Contributors(APPLICATION)'
                 },
        'source': 'Persons(ID_PERSON)',
        'target': 'Applications(ID_APPLICATION)'
        },
    'involvement': { 
        'join': {'source': 'Involvements(PERSON)',
                 'target': 'Involvements(STUDY)'
                 },
        'source': 'Persons(ID_PERSON)',
        'target': 'Studies(ID_STUDY)'
        },
    'collection': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(INSTANCE)',
        'target': 'Containers(ID_CONTAINER)'
        },
    'sourced from': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(SOURCED_FROM)',
        'target': 'Persons(ID_PERSON)'
        },
    'location': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(LOCATION_DOCUMENTATION)',
        'target': 'Documentation(ID_DOCUMENTATION)'
        },
    'held by': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(HELD_BY)',
        'target': 'Persons(ID_PERSON)'
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
        'LABEL',
        'VALUE'
        ],
    'Computers': [
        'ID_COMPUTER',
        'NAME',
        'HOST_ID',
        'IP_ADDRESS',
        'MAC_ADDRESS'
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
    'Persons': [
        'ID_PERSON',
        'NAME',
        'EMAIL'
        ],
    'Studies': [
        'ID_STUDY',
        'LABEL',
        'DESCRIPTION',
        'START_TIME',
        'END_TIME'
        ],
    'Role': [
        'ROLE'
        ],
    'Contributors': [
        'ROLE'
        ],
     'StatisticalMethods' : [
	'ID_STATISTICAL_METHOD',
	'LABEL'
	],
     'VisualisationMethods' : [
	'ID_VISUALISATION_METHOD',
	'LABEL'
	]
    }


working_dir = os.getcwd()

db_specs = ssrepi.connect_db(working_dir)

originalNodes = ssrepi.get_nodes(db_specs[0], nodes, labels)
activeEdges = ssrepi.get_edges(db_specs[0], edges, labels, originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="provenance.dot")

ssrepi.disconnect_db(db_specs[0])
