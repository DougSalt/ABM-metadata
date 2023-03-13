# Design Document

## Introduction 

The philosophy behind the design of this piece of code is that the
Python program does everything, including the maintenance and
creation of the database. My usual practice is to create the
database and run the program over the top of this. I have done it
this way because I have slightly broken the relational model. I am
allowing more than one primary key per table. This is always
because this is a multipart key and a linking relation
(many-to-many), but pure relational databases do not allow this.
This was forced on me by our standard [Social Simulation
REPository
Interface](Metadata_schema_version_2.0.0_documentation.docx).
Therefore it is curucial that the SSREPI library be responsible
for the creation of the database.

Each table maps to a class, each indivdual relations or set of column values
maps to an object of that class.

I have tried to automate as much of the path deriving and
diagramming behaviour from the definitions of the schema.

### Conventions

All the SQL in the code is capitalised. This makes it easy to pick up when
reading the code. This feature is used to grep properties of the created
database, so should not be broken. 

The terms schema and  table I will use interchangeably but amount to the same
thing. Strictly speaking a schema is a collection of tables. A relation is a
row in a table, an attribute, or column is a single value making up a relation.

Databases have a singular and plural. These follow the rules of English. It
makes the code harder but who gives a damn, this is my code and I will do it
the way I want to. Essentially what this boils down to classes and object
derived from an class are singular, actual relations are plural. For example
the Application schema defines the Applications relation). That is an
instantiation is a plural. I personally thinks this makes the code a bit more
readable, but I am weird and think colour should be spelled that way.
                                                                  
Each relation or row of a table is represented by an object, which each of the
columns or rows represented as an attribute of that object.

## The table superclass

Each relation is therefore a child object of the super class Table. Table
defines some default behaviours using class methods and default instance
methods.

These are:

All these methods can, obviously be overwritten by any sub-class    

This are:

+ def add(self, cur):
+ def query(self,cur):
+ def search(self,cur, equals):
+ def update(self,cur):
+ def getPrimaryKeys(self):
+ def count(cls, conn):
+ def foreignKeys(cls):
+ def is\_relation(cls):
+ def setValues(self, values = None):
+ def validate(self):
+ def myPrimaryKeys(self):
+ def myTableName(self):
+ def commonFields():
+ def createTable(cls, conn):

Generally the following methods are always overwritten by the subclass.

+ __init__(self, values = None):
+ primaryKeys(cls):
+ schema(class):
+ tableName(cls):
+ validate(self):

Optionally the following relation is sometimes overwritten by the subclass.

+ is\_relation

These are all subclasses of table:

+ Applications():
+ Arguments():
+ ArgumentValues():
+ Assumes():
+ Assumptions():
+ Computers():
+ Containers():
+ ContainerTypes():
+ Contents():
+ Contexts():
+ Contributors():
+ Dependencies():
+ Documentation():
+ Employs():
+ Entailments():
+ Implements():
+ Inputs():
+ Involvements():
+ Meets():
+ Models():
+ Parameters():
+ Persons():
+ PersonalData():
+ Pipelines():
+ Processes():
+ Products():
+ Projects():
+ Requirements():
+ Specifications():
+ StatisticalInputs():
+ StatisticalMethods():
+ StatisticalVariables():
+ Statistics():
+ Studies():
+ Tags():
+ TagMaps():
+ Users():
+ Uses():
+ Value():
+ Variables():
+ Visualisations():
+ VisualisationMethods():
+ VisualisationValues():

## Helper routines

+ initially\_populate\_db\_templ():
+ connect\_db():
+ disconnect\_db(conn):
+ create\_tables(conn):
+ set\_debug(value):
+ write\_all\_to\_db(ss\_rep, conn, order = None):
+ initially\_populate\_db(ssrep\_array):
+ studies\_table\_exists(conn):
+ print\_values(ssr\_dict):
+ is\_positive\_int(s):
+ iso8601(str):
+ ip(str):
+ mimetype(allowableMimeTypes):

## Graphing routines

+ graph():
+ derive\_edges():
+ derive\_edge(schema):
+ labels():
+ get\_label(schema):
+ get\_nodes(conn, nodes, labels):
+ draw\_nodes(conn, graph, nodes, labels):
+ format\_text(text, length=30):
+ get\_edges(conn, edges, activeNodes):
+ remove\_orphans(nodes, edges):
+ remove\_edges(nodes,edges):
+ save\_dot(nodes, edges, output=None):
+ draw\_graph (conn, nodes, output):

## Exceptions

class InvalidDBSpec(Exception):
class InvalidNode(Exception):
class InvalidEdge(Exception):

Each of the table methods are now described in detail.

