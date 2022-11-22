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

Each relation is therefore a child object of the super class Table. Table
defines some default behaviours using class methods and default instance
methods.

These are:

All these methods can, obviously be overwritten by any sub-class    

This are:

+ schema
+ is\_relation
