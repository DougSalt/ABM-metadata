#!/usr/bin/env python

__copyright__ = "Copyright 2016"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""


import os, sys

sys.path.append("lib")
import ssrepi_lib as ssrepi

# This program is going to gather all the project metadata stuff into a
# graphviz diagram.

nodes = {
    'Persons': 'ID_PERSON',
    'Applications': 'ID_APPLICATION',
    'Projects': 'ID_PROJECT',
    'Studies': 'ID_STUDY',
    'Documentation': 'ID_DOCUMENTATION',
    'Containers': 'ID_CONTAINER'
    }


edges = { 
    'contributor to application': { 
        'join': {'source': 'Contributors(CONTRIBUTOR)',
                 'target': 'Contributors(APPLICATION)'
                 },
        'source': 'Persons(ID_PERSON)',
        'target': 'Applications(ID_APPLICATION)'
        },
    'contributor to document': { 
        'join': {'source': 'Contributors(CONTRIBUTOR)',
                 'target': 'Contributors(DOCUMENTATION)'
                 },
        'source': 'Persons(ID_PERSON)',
        'target': 'Documentation(ID_DOCUMENTATION)'
        },
    'involvement': { 
        'join': {'source': 'Involvements(PERSON)',
                 'target': 'Involvements(STUDY)'
                 },
        'source': 'Persons(ID_PERSON)',
        'target': 'Studies(ID_STUDY)'
        },
    'held by': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(HELD_BY)',
        'target': 'Persons(ID_PERSON)'
        },
    'sourced from': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(SOURCED_FROM)',
        'target': 'Persons(ID_PERSON)'
        },
    'documents': {
        'id': 'Documentation(ID_DOCUMENTATION)',
        'source': 'Documentation(DOCUMENTS)',
        'target': 'Applications(ID_APPLICATION)'
        },
    'describes': {
        'id': 'Documentation(ID_DOCUMENTATION)',
        'source': 'Documentation(DESCRIBES)',
        'target': 'Studies(ID_STUDY)'
        },
    'location': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(LOCATION_DOCUMENTATION)',
        'target': 'Documentation(ID_DOCUMENTATION)'
        },
    'collection': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(COLLECTION)',
        'target': 'Containers(ID_CONTAINER)'
        },
    'repository of': {
        'id': 'Containers(ID_CONTAINER)',
        'source': 'Containers(REPOSITORY_OF)',
        'target': 'Studies(ID_STUDY)'
        },
    'part': {
        'id': 'Studies(ID_STUDY)',
        'source': 'Studies(PART)',
        'target': 'Studies(ID_STUDY)'
        },
    'component': {
        'id': 'Studies(ID_STUDY)',
        'source': 'Studies(PROJECT)',
        'target': 'Projects(ID_PROJECT)'
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
    'Documentation': [
        'ID_DOCUMENTATION',
        'TITLE',
        'DATE'
        ],
    'Persons': [
        'ID_PERSON',
        'NAME',
        'EMAIL'
        ],
    'Projects': [
        'ID_PROJECT',
        'TITLE',
        'FUNDER',
        'GRANT_ID'        
        ],
    'Studies': [
        'ID_STUDY',
        'LABEL',
        'DESCRIPTION',
        'START_TIME',
        'END_TIME'
        ],
    'Contributors': [
        'ROLE'
        ]
    }

working_dir = os.getcwd()

db_specs = ssrepi.connect_db(working_dir)

originalNodes = ssrepi.get_nodes(db_specs[0], nodes, labels)
activeEdges = ssrepi.get_edges(db_specs[0], edges, labels, originalNodes)
activeNodes = ssrepi.remove_orphans(originalNodes, activeEdges)
ssrepi.draw_graph(activeNodes,activeEdges,output="project_metadata.dot")

ssrepi.disconnect_db(db_specs[0])
