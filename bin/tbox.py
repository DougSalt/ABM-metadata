#!/usr/bin/env python3

__copyright__ = "Copyright 2017"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.0.0"
__authors__ = "Doug Salt"
__credits__ = ""

import graphviz, os, sys, re, random, string

sys.path.append("lib")
import ssrepi

# This program is going to print the TBOX from the database schema definition.


print """
Prefix(:=<http://www.hutton.ac.uk/ds42723/ontologies/2017/7/ssrepi/tbox/1.0/>)
Prefix(owl:=<http://www.w3.org/2002/07/owl#>)
Prefix(rdf:=<http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
Prefix(xml:=<http://www.w3.org/XML/1998/namespace>)
Prefix(xsd:=<http://www.w3.org/2001/XMLSchema#>)
Prefix(rdfs:=<http://www.w3.org/2000/01/rdf-schema#>)


Ontology(<http://www.hutton.ac.uk/ds42723/ontologies/2017/7/ssrepi/tbox/1.0>

Declaration(Class(:Column))
Declaration(Class(:ForeignKey))
Declaration(Class(:PrimaryKey))
Declaration(Class(:Table))
Declaration(Class(:Key))
Declaration(ObjectProperty(:hasForeignKey))
Declaration(ObjectProperty(:hasPart))
Declaration(ObjectProperty(:hasPrimaryKey))
Declaration(ObjectProperty(:manyToMany))
Declaration(ObjectProperty(:partOf))
Declaration(ObjectProperty(:relation))
Declaration(DataProperty(:hasPrimaryKey))

# Object Property: :hasForeignKey (has foreign key)

AnnotationAssertion(rdfs:label :hasForeignKey "has foreign key"@en)
ObjectPropertyDomain(:hasForeignKey :Table)

# Object Property: :hasPart (has part)

AnnotationAssertion(rdfs:label :hasPart "has part"@en)
InverseObjectProperties(:hasPart :partOf)
ObjectPropertyDomain(:hasPart :Table)

# Object Property: :hasPrimaryKey (has primary key)

AnnotationAssertion(rdfs:label :hasPrimaryKey "has primary key"@en)
SubObjectPropertyOf(:hasPrimaryKey owl:topObjectProperty)
ObjectPropertyDomain(:hasPrimaryKey :Table)

# Object Property: :manyToMany (many to many)

AnnotationAssertion(rdfs:label :manyToMany "many to many"@en)
SubObjectPropertyOf(:manyToMany :relation)

# Object Property: :partOf (part of)

AnnotationAssertion(rdfs:label :partOf "part of"@en)

# Object Property: :relation (:relation)

ObjectPropertyDomain(:relation :Table)
ObjectPropertyRange(:relation :Table)

# Class: :ForeignKey (Foreign key)

AnnotationAssertion(rdfs:label :ForeignKey "Foreign key"@en)
SubClassOf(:ForeignKey :Key)

# Class: :PrimaryKey (Primary key)

AnnotationAssertion(rdfs:label :PrimaryKey "Primary key"@en)
SubClassOf(:PrimaryKey :Key)
"""

for edgeKey, edgeValue in ssrepi.derive_edges().items():
    
    source = edgeValue["source"]
    sourceKey = source[source.index("(") + 1:source.index(")")]
    sourceClass = getattr(ssrepi.Table, source[0:source.index("(")])()
    target = edgeValue["target"]
    targetKey = target[target.index("(") + 1:target.index(")")]
    targetClass = getattr(ssrepi.Table, target[0:target.index("(")])()
    targetPrimaryKey = targetClass + "_primary_key"
    sourceForeignKey = sourceClass + "_foreign_key"


    # You need to tidy this  up, because it is virtually impossible to read.

    objectPropertySubClass = None
    if "join" in edgeValue.keys():
        objectPropertySubClass = "manyToMany"
    else:
        objectPropertySubClass = "relation"
    print """
# Class: :""" + targetClass + """
Declaration(Class(:""" + targetClass + """))
SubClassOf(:""" + targetClass + """ :Table)

# Class: :""" + targetKey + """
Declaration(Class(:""" + targetKey + """))

Declaration(Class(:""" + targetPrimaryKey + """))
SubClassOf(:""" + targetPrimaryKey + """ :PrimaryKey)
AnnotationAssertion(rdfs:label :""" + targetPrimaryKey + """ "primary key of """ + targetClass + """ table"@en)

SubClassOf(:""" + targetKey + """ ObjectSomeValuesFrom(:partOf :""" + targetPrimaryKey + """))
SubClassOf(:""" + targetKey + """ :Column)

SubClassOf(:""" + targetClass + """ ObjectSomeValuesFrom(:hasPrimaryKey :""" + targetKey + """))
    
# Class: :""" + sourceClass + """ (:""" + sourceClass + """)
Declaration(Class(:""" + sourceClass + """))
SubClassOf(:""" + sourceClass + """ :Table)
    
# Class: :""" + sourceKey + """
Declaration(Class(:""" + sourceKey + """))
SubClassOf(:""" + sourceKey + """ :Column)
"""
    if "join" in edgeValue.keys():
        sourcePrimaryKey = sourceClass + "_primary_key"
        print """
Declaration(Class(:""" + sourcePrimaryKey + """))
SubClassOf(:""" + sourcePrimaryKey + """ :PrimaryKey)
AnnotationAssertion(rdfs:label :""" + sourcePrimaryKey + """ "primary key of """ + sourceClass + """ table"@en)
        SubClassOf(:""" + sourceKey + """ ObjectSomeValuesFrom(:partOf :""" + sourcePrimaryKey + """))
        SubClassOf(:""" + sourcePrimaryKey + """ ObjectSomeValuesFrom(:partOf :""" + sourceClass + """))
"""
    else:
        sourceForeignKey = sourceClass + "_foreign_key"
        print """
Declaration(Class(:""" + sourceForeignKey + """))
SubClassOf(:""" + sourceForeignKey + """ :ForeignKey)
AnnotationAssertion(rdfs:label :""" + sourceForeignKey + """ "foreign key of """ + sourceClass + """ table"@en)
        SubClassOf(:""" + sourceKey + """ ObjectSomeValuesFrom(:partOf :""" + sourceForeignKey + """))
        SubClassOf(:""" + sourceForeignKey + """ ObjectSomeValuesFrom(:partOf :""" + sourceClass + """))
"""

    print """
# Object Property: :""" + edgeKey + """
ObjectPropertyDomain(:""" + edgeKey + """ :""" + sourceClass + """)
ObjectPropertyRange(:""" + edgeKey + """ :""" + targetClass + """)
SubObjectPropertyOf(:""" + edgeKey + """ :""" + objectPropertySubClass + """)
"""
            
for realTableName, columns in ssrepi.labels().items():
    table = getattr(ssrepi.Table, realTableName)()
    print """
# Class: :""" + table + """
Declaration(Class(:""" + table + """))
SubClassOf(:""" + table + """ :Table)
"""
    for column in columns:
        print """
# Class: :""" + column + """
Declaration(Class(:""" + column + """))
SubClassOf(:""" + column + """ :Column)
SubClassOf(:""" + column + """ ObjectSomeValuesFrom(:partOf :""" + table + """))
"""

print ")";

