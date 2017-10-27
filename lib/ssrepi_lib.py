#!/usr/in/python

# file name: ssrepi_lib.py
# created: 20.04.15 - modified: 05.08.15

'''Social Simulation Repository Interface (SSRepI)'''

# ++ Social Simulations, Data Model (Metadata) ++

# J.G. Polhill et al. "Towards metadata standards for social
# simulation outputs" (in preparation)

# ++ metadata

__copyright__ = "Copyright 2015"
__license__ = "This program is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the Licence, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
__version__ = "1.1.7"
__authors__ = "Lorenzo Milazzo, J. Gary Polhill, Doug Salt"
__credits__ = ""

# The "SSRep" is the Repository for a Social Simulation.

# The "SSRepI" is a library to implement an interface between
# an application and the SSRep.

import sqlite3 as lite
import os, sys, subprocess, re, mimetypes, rfc3987, os.path, datetime, magic
import graphviz, getpass

db_file = 'ssrep.db'
if 'SSREP_DBNAME' in os.environ:
    db_file = os.environ['SSREP_DBNAME']


debug = False
if 'SSREP_DEBUG' in os.environ:
    db_file = os.environ['SSREP_DEBUG']

mime = magic.Magic(mime=True)
encoding = magic.Magic(mime_encoding=True)

mimetypes_map = {} 

# Create a mimetype dictionary.
for (key, value) in mimetypes.types_map.iteritems():
    mimetypes_map[value] = key

mimetypes_map["text/csv"] = ".csv"
mimetypes_map["text/x-perl"] = ".pl"
mimetypes_map["text/x-shellscript"] = ".sh"
mimetypes_map["application/x-directory"] = ""
mimetypes_map["application/x-executable"] = ""

# Regex for the LOCATOR field in Uses and Product
locator = re.compile('^(arg[0-9]*|opt=.+|env=.+|STDOUT|STDERR|CWD|CWD PATH REGEX(\:.*)?)$',re.IGNORECASE)

class InvalidEntity(Exception):
    pass

class Table:
    def __init__(self):
        self.DESCRIPTION = None
        self.ABOUT = None
        self.CREATED = None
        self.CREATOR = None
        self.MODIFIER = None
        self.MODIFIED = None

    def getDict(self):
        return self.__dict__

    def add(self, cur):

        self.CREATOR = getpass.getuser()
        self.CREATED = datetime.datetime.now().isoformat()
        self.validate()
        matches = self.getPrimaryKeys()
        if matches == "":
            raise InvalidEntity(
                "ERROR: No primary key value provided on add for " 
                + self.__class__.__name__)

        fields = ''
        values = ''
        for key, value in self.__dict__.items():
            fields = fields + key + ','
            if value == None or value == (None,):
                values = values + 'null,'
            else:
                values = values + '"%s",' % value
        insertSQL = ("INSERT INTO " + self.myTableName() + 
                 '(' + fields.strip(',') + ') VALUES (' + 
                values.strip(',') + ')')
        if debug:
            sys.stderr.write(insertSQL + '\n')
        cur.execute(insertSQL)

    def query(self,cur):
        matches = self.getPrimaryKeys()
        if matches == "":
            raise InvalidEntity(
                "ERROR: No primary key value provided on update for " 
                + self.__class__.__name__)
        
        getSQL = ("SELECT * " +
            " FROM " + self.myTableName() +
            " WHERE " + matches)
        if debug:
            sys.stderr.write(getSQL + '\n')
        cur.row_factory = lite.Row
        curry = cur.execute(getSQL)
        row = curry.fetchone()
        setValues = ""
        for key in row.keys():
            if self.__dict__[key] == None:
                self.__dict__[key] = row[key]
            elif (self.__dict__[key] != None and 
                isinstance(self.__dict__[key], int)):
                setValues = (setValues + key + "=" + 
                    str(self.__dict__[key]) + ",")

            else:
                setValues = (setValues + key + "='" + 
                    self.__dict__[key] + "',")
    def update(self,cur):
        matches = self.getPrimaryKeys()
        if matches == "":
            raise InvalidEntity(
                "ERROR: No primary key value provided on update for " 
                + self.__class__.__name__)
        
        getSQL = ("SELECT * " +
            " FROM " + self.myTableName() +
            " WHERE " + matches)
        if debug:
            sys.stderr.write(getSQL + '\n')
        cur.row_factory = lite.Row
        curry = cur.execute(getSQL)
        row = curry.fetchone()
        setValues = ""
        self.MODIFIER = getpass.getuser()
        self.MODIFIED = datetime.datetime.now().isoformat()
        for key in row.keys():
            if self.__dict__[key] == None:
                self.__dict__[key] = row[key]
            elif (self.__dict__[key] != None and 
                isinstance(self.__dict__[key], int)):
                setValues = (setValues + key + "=" + 
                    str(self.__dict__[key]) + ",")

            else:
                setValues = (setValues + key + "='" + 
                    self.__dict__[key] + "',")
        self.validate()
        setValues = setValues.strip(',')
        updateSQL = ("UPDATE " + self.myTableName() + 
                 " SET " + setValues + 
                 " WHERE " + matches)
        if debug:
            sys.stderr.write(updateSQL + '\n')
        try:
            cur.execute(updateSQL)
        except:
            print("Class: " + self.__class__.__name__ +
                  "Key: " + matches + ": Unable to update ")
            raise

    def getPrimaryKeys(self):
        for keyset in self.myPrimaryKeys():
            matches = ""
            incomplete = False
            for column in keyset:
                
                if self.__dict__[column] == None:
                    incomplete = True
                    break
                elif (matches != "" and
                    self.__dict__[column] != None and 
                    isinstance(self.__dict__[column], int)):
                    atches = (matches + " AND " + 
                            column + " = " + 
                        str(self.__dict__[column]))

                elif matches != "":
                    matches = (matches + " AND " + 
                        column + " = '" + 
                        self.__dict__[column] + "'")
                elif (self.__dict__[column] != None and 
                    isinstance(self.__dict__[column], int)):
                    matches = (column + " = " + 
                        str(self.__dict__[column]))

                else:
                    matches = (column + " = '" + 
                        self.__dict__[column] + "'")
            if incomplete == False:
                break;
            
        # Error condition is the an empty matches
        return matches
    @classmethod
    def foreignKeys(cls):

        line = cls.schema().splitlines()

        foreignKeys = []
        for i in range(1,  len(line) - 1):
            foreignKey = {}
            if re.search('^\s*FOREIGN\s+KEY\s*\(', line[i]):
                field = re.search(
                    '^\s*FOREIGN\s+KEY\s*\(\s*(\S*)\s*\)\s*$',
                    line[i])
                foreignKey["sourceTable"] = cls.tableName()
                foreignKey["sourceColumn"] = field.group(1)
                i = i + 1
                field = re.search(
                    '^\s*REFERENCES\s*(\S+)\s*\((.*)\)\s*(\,\s*)?$',
                    line[i])
                distal = {}
                foreignKey["targetTable"] = field.group(1)
                foreignKey["targetColumn"] = field.group(2)
                foreignKeys.append(foreignKey)
        return foreignKeys

    @classmethod
    def is_relation(cls):
        # The task here is simple. We need to determine whether this is
        # a mediating table. That it allows a many-to-many link between
        # two, or more, other tables

        # If this table has a single value in its primary key, then it
        # definitely is not a many-to-many, or one-to-many table, so

        if (len(cls.primaryKeys()) == 1
        and len(cls.primaryKeys()[0]) == 1):
            return False

        # I am a little wary here, because this doesn't cover the case
        # primaryKeys[>1][1], i.e., more than one primary key of
        # 1 column. Arguably this is silly and should never happen...
                
        if len(cls.primaryKeys()) > 1:
            for primaryKey in cls.primaryKeys():
                if len(primaryKey) == 1:
                    sys.exit("Serious problem with keys in " +
                    self.__class__)
    
        # So we have one or more  primary keys, consisting of at least 2
        # parts. If any of of these key are primary keys, then
        # this is not a many-to-many, and we move on to the next key.

        for primaryKey in cls.primaryKeys():
            for primaryKeyPart in primaryKey:
                primaryKeyFound = False
                for value in cls.foreignKeys():
                    if value["sourceColumn"] == primaryKeyPart:
                        primaryKeyFound=True
                        break
            if not primaryKeyFound:
                return False

        return True
    
    def setValues(self, values = None):
        if values != None:
            for key in values:
                if key.upper() in self.getDict():
                    self.__dict__[key.upper()] = values[key]
                else:
                    raise InvalidEntity("ERROR: Class: " + 
                        self.__class__.__name__ + 
                        ": Invalid column: " + 
                        key)
    def validate(self):
        if (self.ABOUT != None and 
        not rfc3987.match(self.ABOUT, "Absolute_IRI") and
        not rfc3987.match(self.ABOUT, "Absolute_URI")):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: ABOUT = ' +
                str(self.ABOUT))
        if (not iso8601(self.CREATED)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: CREATED = ' +
                str(self.CREATED))
        if (self.MODIFIED != None and 
            not iso8601(self.MODIFIED)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: MODIFIED = ' +
                str(self.MODIFIED))


    def myPrimaryKeys(self):
        return self.__class__.primaryKeys()

    def myTableName(self):
        return self.__class__.tableName()

    @staticmethod
    def commonFields():
        return """CREATED DATETIME NOT NULL,
CREATOR TEXT NOT NULL,
MODIFIED DATETIME,
MODIFIER TEXT,
DESCRIPTION TEXT,
ABOUT TEXT,"""

    @classmethod
    def createTable(cls, conn):
        with conn:
            cur = conn.cursor()
            cur.execute(cls.schema())
            conn.commit()

    @staticmethod
    def Applications():
        return "Application"
    @staticmethod
    def Arguments():
        return "Argument"
    @staticmethod
    def ArgumentValues():
        return "ArgumentValue"
    @staticmethod
    def Assumes():
        return "Assumes"
    @staticmethod
    def Assumptions():
        return "Assumption"
    @staticmethod
    def Computers():
        return "Computer"
    @staticmethod
    def Containers():
        return "Container"
    @staticmethod
    def ContainerTypes():
        return "ContainerType"
    @staticmethod
    def Contents():
        return "Content"
    @staticmethod
    def Contexts():
        return "Context"
    @staticmethod
    def Contributors():
        return "Contributor"
    @staticmethod
    def Dependencies():
        return "Dependency"
    @staticmethod
    def Documentation():
        return "Documentation"
    @staticmethod
    def Employs():
        return "Employs"
    @staticmethod
    def Entailments():
        return "Entailment"
    @staticmethod
    def Implements():
        return "Implements"
    @staticmethod
    def Inputs():
        return "Input"
    @staticmethod
    def Involvements():
        return "Involvement"
    @staticmethod
    def Meets():
        return "Meets"
    @staticmethod
    def Models():
        return "Model"
    @staticmethod
    def Parameters():
        return "Parameter"
    @staticmethod
    def Persons():
        return "Person"
    @staticmethod
    def PersonalData():
        return "PersonalData"
    @staticmethod
    def Pipelines():
        return "Pipeline"
    @staticmethod
    def Processes():
        return "Process"
    @staticmethod
    def Products():
        return "Product"
    @staticmethod
    def Projects():
        return "Project"
    @staticmethod
    def Requirements():
        return "Requirement"
    @staticmethod
    def Specifications():
        return "Specification"
    @staticmethod
    def StatisticalInputs():
        return "StatisticalInput"
    @staticmethod
    def StatisticalMethods():
        return "StatisticalMethod"
    @staticmethod
    def StatisticalVariables():
        return "StatisticalVariable"
    @staticmethod
    def Statistics():
        return "Statistics"
    @staticmethod
    def Studies():
        return "Study"
    @staticmethod
    def Tags():
        return "Tag"
    @staticmethod
    def TagMaps():
        return "TagMap"
    @staticmethod
    def Users():
        return "User"
    @staticmethod
    def Uses():
        return "Uses"
    @staticmethod
    def Value():
        return "Value"
    @staticmethod
    def Variables():
        return "Variable"
    @staticmethod
    def Visualisations():
        return "Visualisation"
    @staticmethod
    def VisualisationMethods():
        return "VisualisationMethod"
    @staticmethod
    def VisualisationValues():
        return "VisualisationValue"

# Specialisation of PROV:Entity
class Application(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_APPLICATION TEXT PRIMARY KEY, 
PURPOSE TEXT, 
VERSION TEXT, 
LICENCE TEXT, 
LANGUAGE TEXT, 
ENVS TEXT, 
CALLS_APPLICATION TEXT,
CALLS_PIPELINE TEXT,
REVISION TEXT, 
MODEL TEXT,
LOCATION TEXT)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_APPLICATION" ] ]
        
    def __init__(self, values = None):

        Table.__init__(self)
        self.ID_APPLICATION = None
        self.PURPOSE = None
        self.VERSION = None
        self.LICENCE = None
        self.LANGUAGE = None
        self.ENVS = None
        self.CALLS_APPLICATION = None # Foreign key in table Applications
        self.CALLS_PIPELINE = None # Foreign key in table Pipelines
        self.REVISION = None # Foreign key in table Applications
        self.MODEL =    None # Foreign key in table Models
        self.LOCATION = None # Foreign key in table Containers
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Applications"

    def validate(self):
        Table.validate(self)
        # TODO
        # language: dc:language
        # envs: regex based on:
        # for Unix:
        #      ENV_VAR1=some_value ENV_VAR2=some_other_value exectuable
        # or for Windows
        #      cmd /C "set ENV_VAR1=some_value && ENV_VAR2=some_other_value exectuable
        pass

class Argument(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_ARGUMENT TEXT PRIMARY KEY, 
TYPE TEXT, 
ORDER_VALUE TEXT, 
NAME TEXT, 
SEPARATOR TEXT, 
SHORT_NAME TEXT, 
SHORT_SEPARATOR TEXT, 
ARITY TEXT, 
ARGSEP TEXT, 
RANGE TEXT, 
APPLICATION TEXT,
VARIABLE TEXT,
--CONTAINER_TYPE TEXT,
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
--FOREIGN KEY (CONTAINER_TYPE)
--REFERENCES Variables(ID_CONTAINER_TYPE)
--DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VARIABLE)
REFERENCES Variables(ID_VARIABLE)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_ARGUMENT" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_ARGUMENT = None
        self.TYPE = None
        self.ORDER_VALUE = None
        self.NAME = None
        self.SEPARATOR = None
        self.SHORT_NAME = None
        self.SHORT_SEPARATOR = None
        self.ARITY = None
        self.ARGSEP = None
        self.RANGE = None
        self.VARIABLE = None # Foreing key in table Variables
        #self.CONTAINER_TYPE = None # Foreign key in table Variables
        self.APPLICATION = None # Foreign key in table Applications
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Arguments"

    def validate(self):
        Table.validate(self)
        if (self.TYPE.lower() != 'required' and    
            self.TYPE.lower() != 'option' and 
            self.TYPE.lower() != 'flag'):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: TYPE: ' +
                str(self.TYPE))
        if (self.ORDER_VALUE != None and
            not is_positive_int(self.ORDER_VALUE)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: ORDER_VALUE: ' +
                str(self.ORDER_VALUE))
        if (self.SEPARATOR != None and
            self.SEPARATOR != '=' and
            self.SEPARATOR != ' '):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: SEPARATOR: ' +
                str(self.SEPARATOR))
        if (not is_positive_int(self.ARITY) and
            self.ARITY != '?' and
            self.ARITY != '+' and
            self.ARITY != '*' and
            not re.search("\d+", self.ARITY)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: ARITY: ' + 
                str(self.ARITY))
#        sys.stderr.write("ARITY = " + self.ARITY + "\n")
#        if (is_positive_int(self.ARITY) and
#            self.ARITY > 1 and
#            self.ARGSEP == None):
#            raise InvalidEntity('ERROR: Class: ' + 
#                self.__class__.__name__ + 
#                ': Missing column: ARGSEP')
        
        # I have now decided that we are going to validate the
        # ArgumentValues.HAS_VALUE using a Perl regex, which will
        # found in RANGE in this table, so we need to validate that
        # this is a valid regex.

        if self.RANGE != None:
            try:
                    re.compile(self.RANGE)
            except re.error:

                if (self.RANGE.lower() != "table" and
                    self.RANGE != "IRI" and
                    self.RANGE != "absolute_IRI" and
                    self.RANGE != "irrelative_ref" and
                    self.RANGE != "irrelative_part" and
                    self.RANGE != "URI_reference" and
                    self.RANGE != "absolute_URI" and
                    self.RANGE != "URI" and
                    self.RANGE != "relative_ref" and
                    self.RANGE != "relative_part"):

                    raise InvalidEntity('ERROR: Class: ' + 
                        self.__class__.__name__ + 
                        ': Invalid column: RANGE: ' +
                        str(self.RANGE))
         # TODO validate the arity against separator and make
        # sure there is at least a short name or long name for
        # option or flag.
    
# Automatic population?
class ArgumentValue(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
HAS_VALUE TEXT,
CONTAINER TEXT,
FOR_PROCESS TEXT NOT NULL,
FOR_ARGUMENT TEXT NOT NULL,
CONSTRAINT ForProcessForArgumentHasValue
UNIQUE( FOR_PROCESS, FOR_ARGUMENT, HAS_VALUE ),
CONSTRAINT ForProcessForArgumentContainer
UNIQUE( FOR_PROCESS, FOR_ARGUMENT, CONTAINER ),
FOREIGN KEY (FOR_PROCESS)
REFERENCES Processes(ID_PROCESS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (FOR_ARGUMENT)
REFERENCES Arguments(ID_ARGUMENT)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "FOR_PROCESS", "FOR_ARGUMENT", "HAS_VALUE" ],
                 [ "FOR_PROCESS", "FOR_ARGUMENT", "CONTAINER" ] ]

        
    def __init__(self, values = None):
        Table.__init__(self)
        self.HAS_VALUE = None 
        self.FOR_PROCESS = None # Foreign key in table Processes
        self.FOR_ARGUMENT = None # Foreign key in table Arguments
        self.CONTAINER = None # Foreign key in table Containers
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "ArgumentValues"

    def validate(self):
        Table.validate(self)
        if self.FOR_ARGUMENT == None:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: FOR_ARGUMENT' +
                self.FOR_ARGUMENT)
        if self.FOR_PROCESS == None:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: FOR_PROCESS' +
                self.FOR_PROCESS)
        if ((self.HAS_VALUE == None and
             self.CONTAINER == None ) or
            (self.HAS_VALUE != None and
             self.CONTAINER != None )):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid columns: HAS_VALUE, CONTAINER;' +
                ' HAS_VALUE: ' + 
                self.HAS_VALUE +
                ', CONTAINER: ' +
                self.CONTAINER)
# Automatic population?
# Many-to-many
class Assumes(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
               """ + Table.commonFields() + """
PERSON TEXT, 
STATISTICS TEXT, 
VISUALISATION TEXT, 
ASSUMPTION TEXT NOT NULL,
VARIABLE TEXT,
CONSTRAINT AssumptionVariable
UNIQUE( ASSUMPTION, VARIABLE ),
CONSTRAINT AssumptionPerson
UNIQUE( ASSUMPTION, PERSON ),
CONSTRAINT AssumptionStatistics
UNIQUE( ASSUMPTION, STATISTICS ),
FOREIGN KEY (PERSON)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICS)
REFERENCES Statistics(ID_STATISTICS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION)
REFERENCES Visualisations (ID_VISUALISATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VARIABLE)
REFERENCES Variables(ID_VARIABLE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (ASSUMPTION)
REFERENCES Assumptions(ID_ASSUMPTION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ASSUMPTION", "VARIABLE" ], 
             [ "ASSUMPTION", "PERSON" ],
             [ "ASSUMPTION", "STATISTICS" ],
             [ "ASSUMPTION", "VISUALISATION" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.PERSON = None # Foreign key in table Persons
        self.STATISTICS = None # Foreign key in table Statistics
        self.VISUALISATION = None # Foreign key in table Visualisation
        self.VARIABLE = None # Foreign key in Variables
        self.ASSUMPTION = None # Foreign key in Assumptions
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "Assumes"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.PERSON != None:
            notNones += 1
        if self.STATISTICS != None:
            notNones += 1
        if self.VISUALISATION != None:
            notNones += 1
        if self.VARIABLE != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': violation of the primary key: ' +
                ' PERSON: ' +
                str(self.PERSON) +
                ' STATISTICS: ' + 
                str(self.STATISTICS) +
                'VISUALISATION: ' +
                str(self.VISUALISATION) +
                'VARIABLE: ' +
                str(self.VARIABLE))

class Assumption(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_ASSUMPTION TEXT PRIMARY KEY 
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_ASSUMPTION" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_ASSUMPTION = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Assumptions"

# Specialisation of PROV:Agent
# Automatic population?
class Computer(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_COMPUTER TEXT PRIMARY KEY, 
NAME TEXT NOT NULL, 
HOST_ID TEXT NOT NULL, 
IP_ADDRESS TEXT, 
MAC_ADDRESS TEXT
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_COMPUTER" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_COMPUTER = None
        self.NAME = None
        self.HOST_ID = None
        self.IP_ADDRESS = None
        self.MAC_ADDRESS = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Computers"

    def validate(self):
        Table.validate(self)
        # From https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address
        fqdn = re.compile(r"^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$")
        ip = re.compile(r"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
        if not fqdn.match(self.HOST_ID):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: HOST_ID = ' +
                self.HOST_ID)
#        if (self.IP_ADDRESS != None and
#            not ip(self.IP_ADDRESS)):
#            raise InvalidEntity('ERROR: Class: ' + 
#                self.__class__.__name__ + 
#                ': Invalid column: IP_ADDRESS = ' +
#                self.IP_ADDRESS)
#        # From https://stackoverflow.com/questions/4260467/what-is-a-regular-expression-for-a-mac-address
        mac_address = re.compile(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$')
        if (self.MAC_ADDRESS != None and
            not mac_address.match(self.MAC_ADDRESS)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: MAC_ADDRESS = ' +
                self.MAC_ADDRESS)

# Specialisation of PROV:Entity        
# Automatic population?
class Container(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_CONTAINER TEXT PRIMARY KEY, 
LOCATION_TYPE TEXT NOT NULL, 
LOCATION_VALUE TEXT NOT NULL, 
SIZE TEXT, 
ENCODING TEXT, 
CREATION_TIME TEXT, 
MODIFICATION_TIME TEXT, 
UPDATE_TIME TEXT, 
HASH TEXT, 
INSTANCE TEXT, 
LOCATION_APPLICATION TEXT, 
LOCATION_DOCUMENTATION TEXT, 
GENERATED_BY TEXT, 
REPOSITORY_OF TEXT, 
HELD_BY TEXT, 
SOURCED_FROM TEXT, 
OUTPUT_OF TEXT, 
COLLECTION TEXT,
FOREIGN KEY (INSTANCE) 
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (LOCATION_APPLICATION) 
REFERENCES Applications(ID_APPLICATION) 
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (LOCATION_DOCUMENTATION)
REFERENCES Documentation(ID_DOCUMENTATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (GENERATED_BY)
REFERENCES Studies(ID_STUDY)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (REPOSITORY_OF)
REFERENCES Studies(ID_STUDY)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (HELD_BY)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (SOURCED_FROM)
REFERENCES Persons(ID_PERSON)
FOREIGN KEY (OUTPUT_OF)
REFERENCES Processes(ID_PROCESS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (COLLECTION)
REFERENCES Containers(ID_CONTAINER)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_CONTAINER" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_CONTAINER = None
        self.LOCATION_TYPE = None
        self.LOCATION_VALUE = None
        self.SIZE = None
        self.ENCODING= None
        self.CREATION_TIME = None
        self.MODIFICATION_TIME = None
        self.UPDATE_TIME = None
        self.HASH = None
        self.INSTANCE =    None # Foreign key in table ContainerTypes
        self.LOCATION_APPLICATION = None # Foreign key in table Applications
        self.LOCATION_DOCUMENTATION = None # Foreign key in table Documentations
        self.GENERATED_BY = None # Foreign key in table Studies
        self.REPOSITORY_OF = None # Foreign key in table Studies
        self.HELD_BY = None # Foreign key in table Persons
        self.SOURCED_FROM = None # Foreign key in table Persons
        self.OUTPUT_OF = None # Foreign key in the Processes table
        self.COLLECTION = None # Foreign key in the Containers table
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Containers"

    def validate(self):
        Table.validate(self)
        # TODO
        # location_type: file, URI, IRI, remote file, table, ...
        # location_value: the value of location_type
        # hash: hashing-algo:hash
        if (self.LOCATION_TYPE != None and
            self.LOCATION_TYPE != "table" and
            self.LOCATION_TYPE != "IRI" and 
            self.LOCATION_TYPE != "absolute_IRI" and  
            self.LOCATION_TYPE != "irrelative_ref" and  
            self.LOCATION_TYPE != "irrelative_part" and  
            self.LOCATION_TYPE != "URI_reference" and
            self.LOCATION_TYPE != "absolute_URI" and
            self.LOCATION_TYPE != "URI" and
            self.LOCATION_TYPE != "relative_ref" and
            self.LOCATION_TYPE != "relative_part"):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Heckle Invalid column: LOCATION_TYPE = ' +
                str(self.LOCATION_TYPE))
        if ((   self.LOCATION_TYPE == "IRI" or
            self.LOCATION_TYPE == "absolute_IRI" or
            self.LOCATION_TYPE == "URI_reference" or
            self.LOCATION_TYPE == "absolute_URI" or
            self.LOCATION_TYPE == "URI") and 
            not rfc3987.match(self.LOCATION_VALUE, self.LOCATION_TYPE)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: LOCATION_VALUE = ' +
                str(self.LOCATION_VALUE))
        #local_file = re.compile('relative')
        # I don't know what I was thinking here.
        #if (local_file.match(self.LOCATION_TYPE) and
        #    os.path.isfile(self.LOCATION_VALUE)):
        #    self.stat()
        validsize = re.compile('^[0-9]+(\.[0-9]+)?(K|M|G|T|Ki|Mi|Gi|Ti)?$')
        if (self.SIZE != None and
            not validsize.match(str(self.SIZE))):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: SIZE = ' +
                self.SIZE)
        if (self.CREATION_TIME != None and 
            not iso8601(self.CREATION_TIME)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: CREATION_TIME = ' +
                self.CREATION_TIME)
        if (self.MODIFICATION_TIME != None and 
            not iso8601(self.MODIFICATION_TIME)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: MODIFICATION_TIME = ' +
                self.MODIFICATION_TIME)
        if (self.UPDATE_TIME != None and 
            not iso8601(self.UPDATE_TIME)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: UPDATE_TIME = ' +
                self.UPDATE_TIME)
        # I have left this commented out. You would think that
        # modification and update time would be subsequent to
        # creation time, but this is not always the case in
        # Unix, a file can be created (say by output) after an
        # earlier version was modified.

         # if (self.CREATION_TIME != None and
        #     self.MODIFICATION_TIME != None and
        #     self.MODIFICATION_TIME < self.CREATION_TIME):
        #     raise InvalidEntity('ERROR: Class: ' + self.__class__.__name__ + ': Invalid column: CREATION_TIME,MODIFICATION_TIME')
        # if (self.CREATION_TIME != None and
        #     self.UPDATE_TIME != None and
        #     self.UPDATE_TIME < self.CREATION_TIME):
        #     raise InvalidEntity('ERROR: Class: ' + self.__class__.__name__ + ': Invalid column: CREATION_TIME,UPDATE_TIME')
        if self.INSTANCE != None:
            # TODO
            # Eventually do an enquiry to make sure this
            # is of the correct encoding type, since we
            # have an active cursor.
            pass
            

    def stat(self):
        st = os.stat(self.LOCATION_VALUE)
        self.CREATION_TIME = datetime.datetime.fromtimestamp(st.st_ctime).isoformat()
        self.MODIFICATION_TIME =  datetime.datetime.fromtimestamp(st.st_mtime).isoformat()
        self.UPDATE_TIME =  datetime.datetime.fromtimestamp(st.st_atime).isoformat()
        self.SIZE = st.st_size
        self.ENCODING = encoding.from_file(self.LOCATION_VALUE)
        

# Possible specialisation of PROV:Entity
class ContainerType(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_CONTAINER_TYPE TEXT PRIMARY KEY,
FORMAT TEXT NOT NULL,
IDENTIFIER TEXT NOT NULL
)"""
    # This should probably be a static method as well, as it doesn't change
    # per instance.        

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_CONTAINER_TYPE" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_CONTAINER_TYPE = None
        self.FORMAT = None
        self.IDENTIFIER = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "ContainerTypes"


    def validate(self):
        Table.validate(self)
        if (self.FORMAT != None and
            not mimetype(self.FORMAT)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: FORMAT: ' +
                self.FORMAT)
        identifier_regex = re.compile(r'(magic|name)\:(.*)(\;(magic|name)\:(.*))*')
        if (self.IDENTIFIER != None and
            not identifier_regex.match(self.IDENTIFIER)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: IDENTIFIER :' +
                self.IDENTIFIER)

# Many-to-many
class Content(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
OPTIONALITY TEXT,
LOCATOR TEXT,
SPACE_LOCATOR TEXT,
TIME_LOCATOR TEXT,
LINK_LOCATOR TEXT,
AGENT_LOCATOR TEXT,
CONTAINER_TYPE TEXT,
VARIABLE TEXT,
VISUALISATION_METHOD TEXT,
CONSTRAINT ContainerTypeVariable
UNIQUE( CONTAINER_TYPE, VARIABLE ),
CONSTRAINT ContainerTypeVisualisationMethod
UNIQUE( CONTAINER_TYPE, VISUALISATION_METHOD ),
FOREIGN KEY (CONTAINER_TYPE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VARIABLE)
REFERENCES Variables(ID_VARIABLE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "CONTAINER_TYPE", "VARIABLE" ],
             [ "CONTAINER_TYPE", "VISUALISATION_METHOD" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.OPTIONALITY = None
        self.LOCATOR = None
        self.SPACE_LOCATOR = None
        self.TIME_LOCATOR = None
        self.LINK_LOCATOR = None
        self.AGENT_LOCATOR = None
        self.CONTAINER_TYPE = None # Foreign key in table ContainerTypes
        self.VARIABLE = None # Foreign key in table Variables
        self.VISUALISATION_METHOD = None # Foreign key in table VisualisationMethods
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Contents"

    def validate(self):
        Table.validate(self)
        # TODO
        # locator: table or csv file for now.
        # space_locator: variable.is_space then GIS format rule for obtaining spatial value
        # time_locator: variable.is_time then format rule for obtaining timestamp value.
        # link_locator: variable.is_time then format rule for obtaining link id value.
        # agent_locator: variable.is_time then format rule for obtaining agent ID value.
        if (self.OPTIONALITY != None and
            self.OPTIONALITY.lower() != 'always' and
            self.OPTIONALITY.lower() != 'depends'):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: OPTIONALITY: ' +
                self.OPTIONALITY)

# Automatic population?
class Context(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_CONTEXT TEXT PRIMARY KEY,
VALUE TEXT NOT NULL,
PART TEXT,
FOREIGN KEY (PART)
REFERENCES Contexts(ID_CONTEXT)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_CONTEXT" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_CONTEXT = None
        self.VALUE = None 
        self.PART = None # Foreign key in this table, Context
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Contexts"

# dc:contributor
# PROV:was-attributed-to
# Many-to-many
class Contributor(Table):

    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
CONTRIBUTION TEXT NOT NULL, 
ALIAS TEXT, 
CONTRIBUTOR TEXT NOT NULL, 
DOCUMENTATION TEXT, 
APPLICATION TEXT,
CONSTRAINT ContributorApplication
UNIQUE( CONTRIBUTOR, APPLICATION ),
CONSTRAINT ContributorDocumentation
UNIQUE( CONTRIBUTOR, APPLICATION ),
FOREIGN KEY (CONTRIBUTOR)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED
FOREIGN KEY (DOCUMENTATION)
REFERENCES Documentation(ID_DOCUMENTATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "CONTRIBUTOR", "APPLICATION" ],
             [ "CONTRIBUTOR", "DOCUMENTATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.CONTRIBUTION = None
        self.ALIAS = None
        self.CONTRIBUTOR = None # Foreign key in table Persons
        self.DOCUMENTATION = None # Foreign key in table Documentation
        self.APPLICATION = None # Foreign key in table Applications
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Contributors"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.DOCUMENTATION != None:
            notNones += 1
        if self.APPLICATION != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Ambiguous primary key: ' + 
                self.__class__.__name__ + 
                ': Invalid column: DOCUMENTATION: ' +
                self.DOCUMENTATION + 
                ', APPLICATION: ' +
                self.APPLICATION)

        
# Automatic population?
# Many-to-many
class Dependency(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
OPTIONALITY TEXT NOT NULL, 
DEPENDANT TEXT NOT NULL, 
DEPENDENCY TEXT NOT NULL,
PRIMARY KEY (DEPENDANT, DEPENDENCY),
FOREIGN KEY (DEPENDANT)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (DEPENDENCY)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "DEPENDANT", "DEPENDENCY" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.OPTIONALITY = None
        self.DEPENDANT = None # Foreign key in the table Applications
        self.DEPENDENCY = None # Foreign key in the table Applications
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "Dependencies"

    def validation(self):
        # TODO
        # optionality: 'required', 'optional' or condition, e.g arg3 == /\.png$/
        pass

# Specialisation of PROV:Entity
class Documentation(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_DOCUMENTATION TEXT PRIMARY KEY,
TITLE TEXT NOT NULL,
DATE TEXT,
DOCUMENTS TEXT,
DESCRIBES INTEGER,
FOREIGN KEY (DOCUMENTS)
REFERENCES Applications(ID_APPLICATION) 
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (DESCRIBES)
REFERENCES Studies(ID_STUDY) 
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_DOCUMENTATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_DOCUMENTATION = None
        self.TITLE = None
        self.DATE = None
        self.DOCUMENTS = None # Foreign key in table Applications
        self.DESCRIBES = None # Foreign key in table Studies
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "Documentation"

    def validate(self):
        Table.validate(self)
        # title: dc:title
        notNones = 0
        if self.DOCUMENTS != None:
            notNones += 1
        if self.DESCRIBES != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: ABOUT,DESCRIBES')
        if (self.DATE != None and
            not iso8601(self.DATE)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: DATE: ' +
                self.DATE)
            


# Many-to-many
class Employs(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
STATISTICAL_METHOD TEXT,
VISUALISATION_METHOD TEXT,
STATISTICAL_VARIABLE TEXT NOT NULL,
CONSTRAINT StatisticalVariableStatisticalMethod
UNIQUE( STATISTICAL_VARIABLE , STATISTICAL_METHOD),
CONSTRAINT StatisticalVariableVisualisationMethod
UNIQUE( STATISTICAL_VARIABLE , VISUALISATION_METHOD),
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICAL_VARIABLE)
REFERENCES StatisticalVariables(ID_STATISTICAL_VARIABLE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICAL_METHOD)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED
)"""
       
    @classmethod
    def primaryKeys(cls):
        return [ [ "STATISTICAL_VARIABLE", "STATISTICAL_METHOD" ],
             [ "STATISTICAL_VARIABLE", "VISUALISATION_METHOD" ] ]


    def __init__(self, values = None):
        Table.__init__(self)
        self.STATISTICAL_METHOD = None # Foreign key in table StatisticalMethods
        self.VISUALISATION_METHOD = None # Foreign key in table VisualisationMethods
        self.STATISTICAL_VARIABLE = None # Foreign key in table StatisticalVariables
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Employs"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.STATISTICAL_METHOD != None:
            notNones += 1
        if self.VISUALISATION_METHOD != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Ambiguous primary key: ' + 
                self.__class__.__name__ + 
                ': STATISTICAL_METHOD: ' +
                self.STATISTICAL_METHOD +
                ', VISUALISATION_METHOD: ' +
                self.VISUALISATION)

# Many-to-many
class Entailment(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
STATISTICAL_METHOD TEXT,
VISUALISATION_METHOD TEXT,
ASSUMPTION TEXT NOT NULL, 
CONSTRAINT AssumptionStatisticalMethod
UNIQUE( ASSUMPTION, STATISTICAL_METHOD ),
CONSTRAINT AssumptionVisualisationMethod
UNIQUE( ASSUMPTION, VISUALISATION_METHOD ),
FOREIGN KEY (STATISTICAL_METHOD)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (ASSUMPTION)
REFERENCES Assumptions(ID_ASSUMPTION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ASSUMPTION", "STATISTICAL_METHOD" ],
             [ "ASSUMPTION", "VISUALISATION_METHOD" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.STATISTICAL_METHOD = None # Foreign key in table StatisticalMethods
        self.VISUALISATION_METHOD = None # Foreign key in table VisualisationMethods
        self.ASSUMPTION = None # Foreign key in table Assumptions
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "Entailments"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.STATISTICAL_METHOD != None:
            notNones += 1
        if self.VISUALISATION_METHOD != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Ambiguous primary key: ' + 
                self.__class__.__name__ + 
                ': STATISTICAL_METHOD: ' +
                self.STATISTICAL_METHOD +
                ', VISUALISATION_METHOD: ' +
                self.VISUALISATION)

# Many-to-many
class Implements(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
FUNCTION TEXT,
LIBRARY TEXT,
STATISTICAL_METHOD TEXT,
VISUALISATION_METHOD TEXT,
APPLICATION TEXT NOT NULL,
CONSTRAINT ApplicationStatisticalMethod
UNIQUE( APPLICATION, STATISTICAL_METHOD ),
CONSTRAINT ApplicationVisualisationMethod
UNIQUE( APPLICATION, VISUALISATION_METHOD ),
FOREIGN KEY (STATISTICAL_METHOD)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
)"""
       
    @classmethod
    def primaryKeys(cls):
        return [ [ "APPLICATION", "STATISTICAL_METHOD" ],
             [ "APPLICATION", "VISUALISATION_METHOD" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.FUNCTION = None
        self.LIBRARY = None 
        self.STATISTICAL_METHOD = None # Foreign key in table StatisticalMethods
        self.VISUALISATION_METHOD = None # Foreign key in table VisualisationMethods
        self.APPLICATION = None # Foreign key in table Applications
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "Implements"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.STATISTICAL_METHOD != None:
            notNones += 1
        if self.VISUALISATION_METHOD != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Ambiguous primary key: ' + 
                self.__class__.__name__ + 
                ': STATISTICAL_METHOD: ' +
                str(self.STATISTICAL_METHOD) +
                ', VISUALISATION_METHOD: ' +
                str(self.VISUALISATION_METHOD))

# Automatic population?
# Many-to-many
class Input(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
USAGE TEXT NOT NULL, 
PROCESS TEXT NOT NULL, 
CONTAINER TEXT NOT NULL,
PRIMARY KEY (PROCESS, CONTAINER),
FOREIGN KEY (PROCESS)
REFERENCES Processes(ID_PROCESS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINER)
REFERENCES Containers(ID_CONTAINER)
DEFERRABLE INITIALLY DEFERRED
)"""
        
    @classmethod
    def primaryKeys(cls):
        return [ [ "PROCESS", "CONTAINER" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.USAGE = None
        self.PROCESS = None # Foreign key in table Processes
        self.CONTAINER = None # Foreign key in table Containers
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Inputs"

    def validate(self):
        Table.validate(self)
        if (self.USAGE.lower() != 'dependency' and
            self.USAGE.lower() != 'data'):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: USAGE: ' +
                self.USAGE)

# Many-to-many
class Involvement(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ROLE TEXT NGOT NULL, 
PERSON TEXT NOT NULL, 
STUDY INT NOT NULL,
PRIMARY KEY (PERSON, STUDY),
FOREIGN KEY (PERSON)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STUDY)
REFERENCES Studies(ID_STUDY)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "PERSON", "STUDY" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ROLE = None
        self.PERSON = None # Foreign key in table Persons
        self.STUDY = None # Foreign key in table Studies
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Involvements"


# Automatic population?
# Many-to-many
# Note both these are specifications
class Meets(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
COMPUTER_SPECIFICATION TEXT NOT NULL,
REQUIREMENT_SPECIFICATION TEXT NOT NULL,
PRIMARY KEY (COMPUTER_SPECIFICATION, REQUIREMENT_SPECIFICATION),
FOREIGN KEY(COMPUTER_SPECIFICATION)
REFERENCES Specifications(ID_SPECIFICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY(REQUIREMENT_SPECIFICATION)
REFERENCES Specifications(ID_SPECIFICATION)
DEFERRABLE INITIALLY DEFERRED
)"""
        
    @classmethod
    def primaryKeys(cls):
        return [ [ "COMPUTER_SPECIFICATION","REQUIREMENT_SPECIFICATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.COMPUTER_SPECIFICATION = None # Foreign key in the table Specifications
        self.REQUIREMENT_SPECIFICATION = None # Foreign key in the table Specifications
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Meets"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.COMPUTER_SPECIFICATION != None:
            notNones += 1
        if self.REQUIREMENT_SPECIFICATION != None:
            notNones += 1
        if notNones != 2:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: COMPUTER_SPECIFICATION,' +
                'REQUIREMENT_SPECIFICATION')
        
# Specialisation of PROV:Entity
class Model(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_MODEL TEXT PRIMARY KEY, 
APPLICATION TEXT,
COMSES TEXT,
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
)"""
        
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_MODEL" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_MODEL = None
        self.APPLICATION = None # Foreign key in the table Applications
        # comses: ID of model in CoMSES-Net table
        self.COMSES = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Models"

class Parameter(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PARAMETER TEXT PRIMARY KEY, 
DATA_TYPE TEXT NOT NULL,
STATISTICAL_METHOD TEXT,
VISUALISATION_METHOD TEXT,
FOREIGN KEY (STATISTICAL_METHOD)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_PARAMETER" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PARAMETER = None
        self.DATA_TYPE = None
        self.STATISTICAL_METHOD = None # Foreign key in table StatisticalMethods
        self.VISUALISATION_METHOD = None # Foreign key in table StatisticalMethods
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Parameters"

# Specialisation of PROV:Agent
class Person(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PERSON TEXT PRIMARY KEY, 
NAME TEXT NOT NULL, 
EMAIL TEXT NOT NULL
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_PERSON" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PERSON = None
        self.NAME = None
        self.EMAIL = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Persons"

    def validate(self):
        Table.validate(self)
        # From http://emailregex.com
        email = re.compile(r"(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)")
        if not email.match(self.EMAIL):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: EMAIL: ' +
                self.EMAIL)


class PersonalData(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PERSONAL_DATA TEXT PRIMARY KEY, 
LABEL TEXT NOT NULL,
VALUE TEXT NOT NULL, 
FOREIGN KEY (ABOUT)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_PERSONAL_DATA" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PERSONAL_DATA = None
        self.LABEL = None
        self.VALUE = None
        self.ABOUT = None # Foreign key in the Persons table
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "PersonalData"

# Specialisation of PROV:Entity
class Pipeline(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PIPELINE TEXT PRIMARY KEY, 
CALLS_APPLICATION TEXT,
CALLS_PIPELINE TEXT,
NEXT TEXT,
FOREIGN KEY (CALLS_APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CALLS_PIPELINE)
REFERENCES Pipelines(ID_PIPELINE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (NEXT)
REFERENCES Pipelines(ID_PIPELINE)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_PIPELINE" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PIPELINE = None
        self.CALLS_APPLICATION = None # Foreign key in the table Applications
        self.CALLS_PIPELINE = None # Foreign key in the table Pipelines
        self.NEXT = None # Foreign key in the table Pipelines
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Pipelines"

    def validate(self):
        Table.validate(self)
        if   ( self.CALLS_PIPELINE != None and
               self.CALLS_APPLICATION != None):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                   ": columns: Invalid primary key: " + 
                    " CALLS_APPLICATION: " + 
                str(self.CALLS_APPLICATION) +
                ", CALLS_PIPELINE: " + 
                str(self.CALLS_PIPELINE))

# Specialisation of PROV:Activity
# Automatic population?
class Process(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PROCESS TEXT PRIMARY KEY, 
START_TIME TEXT NOT NULL, 
END_TIME TEXT, 
ARGV TEXT, 
ENVIRONMENT TEXT,
WORKING_DIR TEXT NOT NULL, 
EXECUTABLE TEXT NOT NULL, 
USER TEXT NOT NULL, 
HOST TEXT NOT NULL, 
PARENT TEXT,
FOREIGN KEY (EXECUTABLE)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (USER)
REFERENCES Users(ID_USER)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (HOST)
REFERENCES Computers(ID_COMPUTER)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (PARENT)
REFERENCES Processes(ID_PROCESS)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ ["ID_PROCESS" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PROCESS = None
        self.START_TIME = None
        self.END_TIME = None
        self.ARGV = None
        self.ENVIRONMENT = None
        self.WORKING_DIR = None
        self.EXECUTABLE = None # Foreign key in the table Applications
        self.USER = None # Foreign key in the table Users
        self.HOST = None # Foreign key in the table Computers
        self.PARENT = None # Foreign key in the table Processes
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Processes"

    def validate(self):
        Table.validate(self)
        # working_dir: Unix or DOS path
        # argv: regex
        # envs: regex based on:
        # for Unix:
        #      ENV_VAR1=some_value ENV_VAR2=some_other_value exectuable
        # or for Windows
        #      cmd /C "set ENV_VAR1=some_value && ENV_VAR2=some_other_value exectuable
        if self.START_TIME != None and not iso8601(self.START_TIME):
            raise InvalidEntity('ERROR: Class: ' + 
                    self.__class__.__name__ + 
                       ": column: START_TIME " + 
                        ": invalid value: " + 
                    str(self.START_TIME))
        if self.END_TIME != None:
            if not iso8601(self.END_TIME):
                raise InvalidEntity('ERROR: Class: ' + 
                    self.__class__.__name__ + 
                    ': Invalid column: END_TIME' +
                    str(self.END_TIME))
            # This next line is bogus and will not work.
            if (self.START_TIME != None and
                self.START_TIME > self.END_TIME):
                raise InvalidEntity('ERROR: Class: ' + 
                    self.__class__.__name__ + 
                    ': Invalid column: START_TIME = ' + 
                    str(self.START_TIME) +
                    ' and END_TIME = ' + 
                    str(self.END_TIME))

# Many-to-many
class Product(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
OPTIONALITY TEXT, 
LOCATOR TEXT,
APPLICATION TEXT NOT NULL,
CONTAINER_TYPE TEXT NOT NULL,
IN_FILE TEXT,
PRIMARY KEY (APPLICATION, CONTAINER_TYPE),
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINER_TYPE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (IN_FILE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ ["APPLICATION", "CONTAINER_TYPE" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.OPTIONALITY = None
        self.LOCATOR = None
        self.APPLICATION = None # Foreign key in the table Applications
        self.CONTAINER_TYPE = None # Foreign key in the table ContainerTypes
        self.IN_FILE = None # Foreign key in the table Containers
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Products"

    def validate(self):
        Table.validate(self)
        if (self.OPTIONALITY.lower() != 'always' and
            self.OPTIONALITY.lower() != 'depends'):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: OPTIONALITY: ')
        if (self.LOCATOR != None and 
            not locator.match(self.LOCATOR)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: LOCATOR: ' + 
                self.LOCATOR)

# Specialisation of PROV Activity
class Project(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_PROJECT TEXT PRIMARY KEY, 
TITLE TEXT NOT NULL, 
FUNDER TEXT,
GRANT_ID TEXT,
STUDY INT,
FOREIGN KEY(STUDY)
REFERENCES Studies(ID_STUDY)
DEFERRABLE INITIALLY DEFERRED 
)"""

    @classmethod
    def primaryKeys(cls):
        return [ ["ID_PROJECT" ] ]
        
    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_PROJECT = None
        self.TITLE = None
        self.FUNDER = None
        self.GRANT_ID = None
        self.STUDY = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Projects"

        
# Many-to-many
class Requirement(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
APPLICATION TEXT NOT NULL, 
MATCH TEXT,
MINIMUM TEXT,
EXACT TEXT,
CONSTRAINT ApplicationMath
UNIQUE( APPLICATION, MATCH),
CONSTRAINT ApplicationExact
UNIQUE( APPLICATION, EXACT),
CONSTRAINT ApplicationMinimum
UNIQUE( APPLICATION, MINIMUM),
FOREIGN KEY (MATCH)
REFERENCES Specifications(ID_SPECIFICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (MINIMUM)
REFERENCES Specifications(ID_SPECIFICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (EXACT)
REFERENCES Specifications(ID_SPECIFICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "APPLICATION", "MATCH" ],
             [ "APPLICATION", "EXACT" ],
             [ "APPLICATION", "MINIMUM" ] ]  

        

    def __init__(self, values = None):
        Table.__init__(self)
        self.APPLICATION = None # Foreign key of the table Applications
        self.MATCH = None # Foreign key of the table Specifications
        self.MINIMUM = None # Foreign key of the table Specifications
        self.EXACT = None # Foreign key of the table Specifications
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Requirements"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.MINIMUM != None:
            notNones += 1
        if self.MATCH != None:
            notNones += 1
        if self.EXACT != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: MINIMUM,MATCH,EXACT')

class Specification(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_SPECIFICATION TEXT PRIMARY KEY, 
VALUE TEXT NOT NULL,
SPECIFICATION_OF TEXT,
FOREIGN KEY (SPECIFICATION_OF)
REFERENCES Computers(ID_COMPUTER)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_SPECIFICATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_SPECIFICATION = None
        self.VALUE = None
        self.SPECIFICATION_OF = None # Foreign key of the table Specifications
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Specifications"

    #def validate(self):
        # TODO
        # value if this is the target of a match requirement,
        # then this may be a regex, otherwise it should be
        # some form of number.
        # No validation of foreign keys as there is additional many-to-many
        # keys from the "Requirements" table.

# Automatic population?
# Many-to-many

# This links Visualisation and Statistics to the an actual value, and as such
# represents an instantiation and extends the provenance into fine grain.

class StatisticalInput(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
VISUALISATION TEXT,
STATISTICS TEXT,
VALUE TEXT NOT NULL,
CONSTRAINT ValueStatistics
UNIQUE( VALUE, STATISTICS ),
CONSTRAINT ValueVisualisation
UNIQUE( VALUE, VISUALISATION ),
FOREIGN KEY (VISUALISATION) 
REFERENCES Visualisations(ID_VISUALISATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICS)
REFERENCES Statistics(ID_STATISTICS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VALUE)
REFERENCES Value(ID_VALUE)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "VALUE", "STATISTICS" ],
             [ "VALUE", "VISUALISATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.STATISTICS = None # Foreign key in the table Statistics
        self.VISUALISATION = None # Foreign key in the table Visualisation
        self.VALUE = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "StatisticalInputs"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.STATISTICS != None:
            notNones += 1
        if self.VISUALISATION != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + self.__class__.__name__ + ': Invalid column: STATISTICS,VISUALISATION')

class StatisticalMethod(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_STATISTICAL_METHOD TEXT PRIMARY KEY
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_STATISTICAL_METHOD" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_STATISTICAL_METHOD = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "StatisticalMethods"

# Names the output of a StatisticalMethod
class StatisticalVariable(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_STATISTICAL_VARIABLE TEXT PRIMARY KEY,
DATA_TYPE TEXT NOT NULL,
GENERATED_BY TEXT,
FOREIGN KEY (GENERATED_BY)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_STATISTICAL_VARIABLE" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_STATISTICAL_VARIABLE = None
        self.DATA_TYPE = None
        self.GENERATED_BY = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "StatisticalVariables"
        
# Specialisation of PROV:Activity
# Automatic population?
class Statistics(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_STATISTICS TEXT PRIMARY KEY,
DATE TEXT,
QUERY TEXT,
USED TEXT NOT NULL,
FOREIGN KEY (USED)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_STATISTICS" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_STATISTICS = None
        self.DATE = None
        self.QUERY = None
        self.USED = None # Foreign key from the table  StatisticalMethods 
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Statistics"

    def validate(self):
        Table.validate(self)
        if (self.DATE != None and
            not iso8601(self.DATE)):
            raise InvalidEntity('ERROR: Class: ' + self.__class__.__name__ + ': Invalid column: DATE')

# Specialisation of PROV:Activity
class Study(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_STUDY INTEGER PRIMARY KEY, 
LABEL TEXT NOT NULL, 
START_TIME TEXT NOT NULL, 
END_TIME TEXT, 
PROJECT TEXT, 
PART INT,
FOREIGN KEY (PROJECT)
REFERENCES Projects(ID_PROJECT) 
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (PART)
REFERENCES Studies(ID_STUDY) 
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_STUDY" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        # As all this  is held in memory, the  next key has to
        # be calculated -  this means that autoincrment should
        # not be used.

        self.ID_STUDY = 0
        self.LABEL = None
        self.START_TIME = None
        self.END_TIME = None
        self.PROJECT =  None # Foreign key in table Projects
        self.PART = None # Foreign key in table Studies
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Studies"

    def validate(self):
        Table.validate(self)
        if (self.START_TIME != None and
        not iso8601(self.START_TIME)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: START_TIME: ' +
                self.START_TIME)
        if self.END_TIME != None:
            if not iso8601(self.END_TIME):
                raise InvalidEntity('ERROR: Class: ' + 
                    self.__class__.__name__ + 
                    ': Invalid column: END_TIME: ' +
                    self.END_TIME)
            if self.START_TIME > self.END_TIME:
                raise InvalidEntity('ERROR: Class: ' + 
                    self.__class__.__name__ + 
                    ': Invalid column: START_TIME,END_TIME: ' +
                    self.START_TIME +
                    ' ' +  
                    self.END_TIME)
        notNones = 0
        if self.PROJECT != None:
            notNones += 1
        if self.PART != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Must have one of column: PROJECT,PART')

class Tag(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_TAG TEXT PRIMARY KEY
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_TAG" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_TAG = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Tags"


# Many-to-many
class TagMap(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
TARGET_TAG TEXT NOT NULL,
TAG TEXT,
CONTAINER_TYPE TEXT,
ASSUMPTION TEXT,
APPLICATION TEXT,
CONTAINER TEXT,
VISUALISATION_METHOD TEXT,
STATISTICAL_METHOD TEXT,
DOCUMENTATION TEXT,
PERSON TEXT,
STUDY TEXT,
CONSTRAINT TargetTagContainerType
UNIQUE( TARGET_TAG, CONTAINER_TYPE ),
CONSTRAINT TargetTagTag
UNIQUE( TARGET_TAG, TAG ),
CONSTRAINT TargetTagApplciation
UNIQUE( TARGET_TAG, APPLICATION ),
CONSTRAINT TargetTagContainer
UNIQUE( TARGET_TAG, CONTAINER ),
CONSTRAINT TargetTagDocumentation
UNIQUE( TARGET_TAG, DOCUMENTATION ),
CONSTRAINT TargetTagStudy
UNIQUE( TARGET_TAG, STUDY ),
CONSTRAINT TargetTagAssumption
UNIQUE( TARGET_TAG, ASSUMPTION),
CONSTRAINT TargetTagStatisticalMethod
UNIQUE( TARGET_TAG, STATISTICAL_METHOD ),
CONSTRAINT TargetTagPerson
UNIQUE( TARGET_TAG, PERSON ),
CONSTRAINT TargetTagVisualisationMethod
UNIQUE( TARGET_TAG, VISUALISATION_METHOD ),
FOREIGN KEY (TARGET_TAG)
REFERENCES Tags(ID_TAG)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (TAG)
REFERENCES Tags(ID_TAG)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINER_TYPE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINER)
REFERENCES Containers(ID_CONTAINER)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (DOCUMENTATION)
REFERENCES Documentation(ID_DOCUMENTATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICAL_METHOD)
REFERENCES StatisticalMethods(ID_STATISTICAL_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
FOREIGN KEY (STUDY)
REFERENCES Studies(ID_STUDY)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (PERSON)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (ASSUMPTION)
REFERENCES Assumptions(ID_ASSUMPTION)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "TARGET_TAG", "CONTAINER_TYPE" ],
             [ "TARGET_TAG", "TAG"    ],
             [ "TARGET_TAG", "APPLICATION"    ],
             [ "TARGET_TAG", "CONTAINER" ],
             [ "TARGET_TAG", "DOCUMENTATION" ],
             [ "TARGET_TAG", "STUDY" ],
             [ "TARGET_TAG", "ASSUMPTION" ],
             [ "TARGET_TAG", "STATISTICAL_METHOD" ],
             [ "TARGET_TAG", "PERSON" ],
             [ "TARGET_TAG", "VISUALISATION_METHOD" ] ]


    def __init__(self, values = None):
        Table.__init__(self)
        self.TARGET_TAG = None  # Foreign key of the table Tags
        self.TAG = None  # Foreign key of the table Tags
        self.CONTAINER_TYPE = None  # Foreign key of the table ContainerTypes
        self.APPLICATION = None  # Foreign key of the table Applications
        self.CONTAINER = None  # Foreign key of the table Containers
        self.ASSUMPTION = None  # Foreign key of the table Containers
        self.PERSON = None  # Foreign key of the table Containers
        self.DOCUMENTATION = None  # Foreign key of the table Documentation
        self.VISUALISATION_METHOD = None  # Foreign key of the table Documentation
        self.STATISTICAL_METHOD = None  # Foreign key of the table Documentation
        self.STUDY = None  # Foreign key of the table Studies
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "TagMaps"

    def validate(self):
        Table.validate(self)
        notNones = 0
        if self.CONTAINER_TYPE != None:
            notNones += 1
        if self.APPLICATION != None:
            notNones += 1
        if self.CONTAINER != None:
            notNones += 1
        if self.DOCUMENTATION != None:
            notNones += 1
        if self.STATISTICAL_METHOD != None:
            notNones += 1
        if self.VISUALISATION_METHOD != None:
            notNones += 1
        if self.PERSON != None:
            notNones += 1
        if self.ASSUMPTION != None:
            notNones += 1
        if self.STUDY != None:
            notNones += 1
        if self.TAG != None:
            notNones += 1
        if notNones != 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Ambiguous primary key: ' +
                " CONTAINER_TYPE: " +
                str(self.CONTAINER_TYPE) +
                " APPLICATION: " +
                str(self.APPLICATION) +
                " CONTAINER: " +
                str(self.CONTAINER) +
                " DOCUMENTATION: " +
                str(self.DOCUMENTATION) +
                " STATISTICAL_METHOD: " +
                str(self.STATISTICAL_METHOD) +
                " VISUALISATION_METHOD: " +
                str(self.VISUALISATION_METHOD) +
                " PERSON: " +
                str(self.PERSON) +
                " ASSUMPTION: " +
                str(self.ASSUMPTION) +
                " STUDY: " +
                str(self.STUDY) +
                " TAG: " +
                str(self.TAG))

# Specialisation of PROV:Agent
# Automatic population?
class User(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_USER TEXT PRIMARY KEY, 
HOME_DIR TEXT NOT NULL, 
ACCOUNT_OF TEXT,
FOREIGN KEY (ACCOUNT_OF)
REFERENCES Persons(ID_PERSON)
DEFERRABLE INITIALLY DEFERRED
)"""
    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_USER" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_USER = None
        self.HOME_DIR = None
        self.ACCOUNT_OF = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Users"

# Many-to-many
class Uses(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
OPTIONALITY TEXT,
LOCATOR TEXT,
APPLICATION TEXT NOT NULL,
CONTAINER_TYPE TEXT NOT NULL,
IN_FILE TEXT,
PRIMARY KEY (APPLICATION, CONTAINER_TYPE),
FOREIGN KEY (APPLICATION)
REFERENCES Applications(ID_APPLICATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINER_TYPE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (IN_FILE)
REFERENCES ContainerTypes(ID_CONTAINER_TYPE)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "APPLICATION", "CONTAINER_TYPE" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.OPTIONALITY = None
        self.LOCATOR = None
        self.APPLICATION = None # Foreign key in the table Applications
        self.CONTAINER_TYPE = None # Foreign key in the table ContainerType
        self.IN_FILE = None # Foreign key in the table Containers
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Uses"

    def validate(self):
        Table.validate(self)
        if (self.OPTIONALITY.lower() != 'required' and
            self.OPTIONALITY.lower() != 'optional' and
            self.OPTIONALITY.lower() != 'depends'):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: OPTIONALITY: ' +
                self.OPTIONALITY)
        # Cannot do a database query to check for presence of IN_FILE,
        # so will have to rely on the constraints when the the 
        # database is committed
        if (self.LOCATOR != None and
            not locator.match(self.LOCATOR)):
            raise InvalidEntity('ERROR: Class: ' + self.__class__.__name__ + ': Invalid column: LOCATOR')
            
# Specialisation of PROV:Entity
# Automatic population?
class Value(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
VALUE TEXT NOT NULL,
FORMAT TEXT,
UNITS TEXT,
VARIABLE TEXT,
STATISTICAL_VARIABLE TEXT,
PARAMETER TEXT,
STATISTICAL_PARAMETER TEXT,
VISUALISATION_PARAMETER TEXT,
RESULT_OF TEXT,
CONTAINED_IN TEXT,
TIME TEXT,
SPACE TEXT,
AGENT TEXT,
LINK TEXT,
CONSTRAINT ValueVariable
UNIQUE (VALUE, VARIABLE),
CONSTRAINT ValueStatisticalParameter
UNIQUE (VALUE, STATISTICAL_VARIABLE),
CONSTRAINT ValueParameter
UNIQUE (VALUE, PARAMETER),
CONSTRAINT ValueStatisitcialParameter
UNIQUE (VALUE, STATISTICAL_PARAMETER),
CONSTRAINT ValueVisualisationParameter
UNIQUE (VALUE, VISUALISATION_PARAMETER),
CONSTRAINT ValueResultOf
UNIQUE (VALUE, RESULT_OF),
FOREIGN KEY (VARIABLE)
REFERENCES Variables(ID_VARIABLE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICAL_VARIABLE)
REFERENCES StatisticalVariables(ID_STATISTICAL_VARIABLE)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (PARAMETER)
REFERENCES Parameters(ID_PARAMETER)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (STATISTICAL_PARAMETER)
REFERENCES Statistics(ID_STATISTICS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (VISUALISATION_PARAMETER)
REFERENCES Visualisations(ID_VISUALISATION)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (RESULT_OF)
REFERENCES Statistics(ID_STATISTICS)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINED_IN) 
REFERENCES Containers(ID_CONTAINER)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (TIME)
REFERENCES Contexts(ID_CONTEXT)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (SPACE)
REFERENCES Contexts(ID_CONTEXT)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (AGENT)
REFERENCES Contexts(ID_CONTEXT)
DEFERRABLE INITIALLY DEFERRED
FOREIGN KEY (LINK)
REFERENCES Contexts(ID_CONTEXT)
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "VALUE", "VARIABLE"  ],
                 [ "VALUE", "STATISTICAL_VARIABLE"  ],
                 [ "VALUE", "PARAMETER"  ],
                 [ "VALUE", "STATISTICAL_PARAMETER"  ],
                 [ "VALUE", "VISUALISATION_PARAMETER"  ],
                 [ "VALUE", "RESULT_OF"  ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        # One of time, space, agent or link must not be null.
        self.VALUE = None
        self.FORMAT = None
        self.UNITS = None
        self.VARIABLE = None # Foreign key in the table Variables
        self.STATISTICAL_VARIABLE = None # Foreign key in the table StatisticalVariables
        self.PARAMETER = None # Foreign key in the table Parameters
        self.STATISTICAL_PARAMETER = None # Foreign key in the table Statistics
        self.VISUALISATION_PARAMETER = None # Foreign key in the table Visualisations
        self.RESULT_OF = None # Foreign key in the table Statistics
        self.CONTAINED_IN = None # Foreign key in the table Containers
        self.TIME = None # Foreign key in the table Contexts
        self.SPACE = None # Foreign key in the table Contexts
        self.AGENT = None # Foreign key in the table Contexts
        self.LINK = None # Foreign key in the table Contexts
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Value"

        
class Variable(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_VARIABLE TEXT PRIMARY KEY,
DATA_TYPE TEXT,
IS_AGENT INTEGER,
IS_LINK INTEGER,
IS_SPACE INTEGER,
IS_TIME INTEGER
)"""

    def __init__(self, values = None):
        Table.__init__(self)
        # only one of is_agent, is_link, is_space or is_time can have value 1,
        # the others must be zero
        self.ID_VARIABLE = None
        self.DATA_TYPE = None
        self.IS_AGENT = 0 # '[0,1]'
        self.IS_LINK = 0 #'[0,1]'
        self.IS_SPACE = 0  # '[0,1]'
        self.IS_TIME = 0 # '[0,1]'
        Table.setValues(self,values)

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_VARIABLE" ] ]

    @classmethod
    def tableName(cls):
        return "Variables"


    def validate(self):
        Table.validate(self)
        total = self.IS_AGENT + self.IS_LINK + self.IS_SPACE + self.IS_TIME
        if total > 1:
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Only one of the following may be true: ' +
                ' IS_AGENT: ' +
                self.IS_AGENT, +
                ', IS_LINK: ' +
                self.IS_LINK +
                ', IS_SPACE: ' +
                self.IS_SPACE +
                ', IS_TIME: ' +
                self.IS_TIME)
            
# Specialisation of PROV:Activity
# Automatic population?
class Visualisation(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_VISUALISATION TEXT PRIMARY KEY, 
VISUALISATION_METHOD TEXT NOT NULL, 
DATE TEXT NOT NULL, 
QUERY TEXT NOT NULL, 
CONTAINED_IN TEXT NOT NULL,
FOREIGN KEY (VISUALISATION_METHOD)
REFERENCES VisualisationMethods(ID_VISUALISATION_METHOD)
DEFERRABLE INITIALLY DEFERRED,
FOREIGN KEY (CONTAINED_IN) 
REFERENCES Containers(ID_CONTAINER)
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_VISUALISATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_VISUALISATION = None
        self.VISUALISATION_METHOD = None
        self.QUERY = None
        self.DATE = None
        self.CONTAINED_IN = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "Visualisations"

    def validate(self):
        Table.validate(self)
        if (not iso8601(self.DATE)):
            raise InvalidEntity('ERROR: Class: ' + 
                self.__class__.__name__ + 
                ': Invalid column: DATE = ' +
                self.DATE)

class VisualisationMethod(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
ID_VISUALISATION_METHOD TEXT PRIMARY KEY
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "ID_VISUALISATION_METHOD" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.ID_VISUALISATION_METHOD = None
        Table.setValues(self,values)

    @classmethod
    def tableName(cls):
        return "VisualisationMethods"


# Many-to-many
class VisualisationValue(Table):
    @classmethod
    def schema(cls):
        return """CREATE TABLE IF NOT EXISTS """ + cls.tableName() + """ (
""" + Table.commonFields() + """
VALUE TEXT NOT NULL,
VISUALISATION TEXT NOT NULL,
PRIMARY KEY (VALUE, VISUALISATION),
FOREIGN KEY (VALUE)
REFERENCES Value(ID_VALUE),
FOREIGN KEY (VISUALISATION) 
REFERENCES Visualisations(ID_VISUALISATION) 
DEFERRABLE INITIALLY DEFERRED
)"""

    @classmethod
    def primaryKeys(cls):
        return [ [ "VALUE", "VISUALISATION" ] ]

    def __init__(self, values = None):
        Table.__init__(self)
        self.VALUE = None # Foreign key in the table Value
        self.VISUALISATION = None # Foreign key in the table Visualisations
        Table.setValues(self,values)
        
    @classmethod
    def tableName(cls):
        return "VisualisationValues"

# function to initialize the Repository for a Social Simulation (SSRep)
# >> note that this is only a template; the definition of this function
# depends on the events/activities of the workflow

#def initially_populate_db_templ():
    
    
#    ssrep = {
#        'Application01': application(), 
#        'Argument01': argument(), 
#        'ArgumentValue01': argumentValue(), 
#        'Assumes01': assumes(), 
#        'Assumption01': assumption(), 
#        'Computer01': computer(), 
#        'Container01': container(), 
#        'ContainerType01': containerType(), 
#        'Content01': content(), 
#        'Context01': context(), 
#        'Contributor01': contributor(), 
#        'Dependency01': dependency(), 
#        'Documentation01': documentation(), 
#        'Employs01': employs(), 
#        'Entailment01': entailment(), 
#        'Implements01': implements(), 
#        'Input01': input(),
#        'Involvement01': involvement(), 
#        'Meets01': meets(), 
#        'Model01': model(), 
#        'Person01': person(), 
#        'PersonalData01': personalData(), 
#        'Pipeline01': pipeline(), 
#        'Process01': process(),
#        'Product01': product(), 
#        'Project01': project(), 
#        'Requirement01': requirement(), 
#        'Specification01': specification(), 
#        'StatsticalInput01': statisticalInput(), 
#        'StatisticalMethod01': statisticalMethod(), 
#        'StatisticalVariable01': statisticalVariable(), 
#        'Statistics01': statistics(), 
#        'Study01': study(), 
#        'TagMap01': tagMap(), 
#        'Tag01': tag(),  
#        'User01': user(), 
#        'Uses01': uses(), 
#        'Value01': value(), 
#        'Variable01': variable(), 
#        'Visualisation01': visualisation(), 
#        'VisualisationMethod01': visualisationMethod(),
#        'VisualisationValue01': visualisationValue()
#        }
#    
#    return ss_rep


# ++ Database
# db type: SQLite



def connect_db(working_dir):
    """function to create a connection with a SQLite db
    """
    conn = None
    sqlite_vers = None

    # SSRep database (SQLite db), FQFN
    db_fqfn = os.path.join(working_dir, db_file)

    try:
        # I/O processing, connecting to db
        conn = lite.connect(db_fqfn)
        # This next statement is very important as it turns off
        # Python's sqlite module's rather random transaction
        # methodology.
        conn.isolation_level = None

        cur = conn.cursor()    
        cur.execute('SELECT SQLITE_VERSION()')
        sqlite_vers = cur.fetchone()

    except lite.Error, e:
        print "error %s:" % e.args[0]
        sys.exit(1)
    
    finally:
        return (conn, db_fqfn, sqlite_vers)


def init_db(conn):
    """Function to initialize the SQLite db
    """
    with conn:
        cur = conn.cursor()
        # enabling foreign key support     
        cur.execute("PRAGMA foreign_keys = ON")


def disconnect_db(conn):
    """Function to disconnect the SQLite db
    """
    conn.close()

# functions to generate the tables
def create_tables(conn):
    """Creates all the tables for the Repository for a Social Simulation database
    """
    Application.createTable(conn)
    Argument.createTable(conn)
    ArgumentValue.createTable(conn)
    Assumes.createTable(conn)
    Assumption.createTable(conn)
    Computer.createTable(conn)
    Container.createTable(conn)
    ContainerType.createTable(conn)
    Content.createTable(conn)
    Context.createTable(conn)
    Contributor.createTable(conn)
    Dependency.createTable(conn)
    Documentation.createTable(conn)
    Employs.createTable(conn)
    Entailment.createTable(conn)
    Implements.createTable(conn)
    Input.createTable(conn)
    Involvement.createTable(conn)
    Meets.createTable(conn)
    Model.createTable(conn)
    Parameter.createTable(conn)
    Person.createTable(conn)
    PersonalData.createTable(conn)
    Pipeline.createTable(conn)
    Process.createTable(conn)
    Product.createTable(conn)
    Project.createTable(conn)
    Requirement.createTable(conn)
    Specification.createTable(conn)
    StatisticalInput.createTable(conn)
    StatisticalMethod.createTable(conn)
    StatisticalVariable.createTable(conn)
    Statistics.createTable(conn)
    Study.createTable(conn)
    Tag.createTable(conn)
    TagMap.createTable(conn)
    User.createTable(conn)
    Uses.createTable(conn)
    Value.createTable(conn)
    Variable.createTable(conn)
    Visualisation.createTable(conn)
    VisualisationMethod.createTable(conn)
    VisualisationValue.createTable(conn)

    
#--

# functions to add a new record to the tables

#--
        
def set_debug(value):

    if value != True and value != False:
        raise 
    global debug
    debug = value

def write_all_to_db(ss_rep, conn, order = None):
    """function to export the SS Repository into a SQLite database
    >> note that this is only a template; the definition of this function
    depends on the events/activities of the workflow
    """
    with conn:
        
        global debug
        cur = conn.cursor()
        if order != None:
            unprocessed = {}
            for key in ss_rep:
                unprocessed[key] = 1
            for key in order:
                if debug:
                    sys.stderr.write("Doing ordered %s" % key)
                    sys.stderr.write("======================")
                    for k,v in ss_rep[key].__dict__.iteritems():
                        print ("%s = %s" % (k,v))
                del unprocessed[key]

                ss_rep[key].add(cur)
            for key in unprocessed:
                if debug:
                    sys.stderr.write("Doing remaining %s" % key)
                    sys.stderr.write("======================")
                    for k,v in ss_rep[key].__dict__.iteritems():
                        sys.stderr.write("%s = %s" % (k,v))
                ss_rep[key].add(cur)
                
        else:
            try:
                cur.execute('BEGIN');
                for key in ss_rep:
                    if debug:
                        sys.stderr.write("Row = %s" % key)
                        ss_rep[key].add(cur)
                cur.execute('COMMIT')
            except lite.OperationalError as e:
                for key in e:
                    sys.stderr.write("Key = " + key)
                sys.stderr.write( e.message)
                sys.stderr.write("DANGER Will Robinson!")
                sys.exit(1)
            except lite.Error, e:
                sys.stderr.write("error %s:" % e.args[0])
                sys.exit(1)
    
        # If isolation_level is not set then you have to
        # commit the changes in a certain order. This are
        # listed below inasmuch as these contain virtually no
        # values, so this order is in no way guaranteed to
        # work, if the tables actually contain real data. This
        # is why I chose deferrable foreign key and took over
        # the transaction management.
            
#--

# ...XX...
# ++ WORK IN PROGRESS ++
# (missing features, possible extensions, ...)

# - functions to create tables; functions to add records to the tables;
#   so far, only 12 of 34 tables have these functions already implemented;

# - procedures for database normalization in order to minimize data redundancy
#   (e.g. by checking the IDs in each tables);


# Helper Functions
# ================

# Function to validate the database intialisation specification.
# This used to be done as a dictionary, but there is no way of validating
# duplicated for dictionairies in Python, so we must enter the specification
# as an array, then create a dictionary from it, making sure there are no
# duplicates, for both the dictionary key and the database keys. This 
# was not part of the specification, but I have done this, as the intialisation
# specification is getting unduly large.

class InvalidDBSpec(Exception):
    pass

def initially_populate_db(ssrep_array):

    if len(ssrep_array) % 2 != 0:
        raise InvalidDBSpec('ERROR: Odd number of entries in spec.' +
            ' Cannot build dictonary')

    ssrep = {};

    for i in range(0, len(ssrep_array) - 1, 2):
        if ssrep_array[i] in ssrep:
            raise InvalidDBSpec('ERROR: Duplicate dictionary ' +
                'key: ' + ssrep_array[i])
        ssrep[ssrep_array[i]] = ssrep_array[i  + 1]
    return ssrep

def studies_table_exists(conn):
    """Function to check if the table "Study" already exists; the function
    returns: 1) the test result; 2) the ID of the last study stored into
    the SQLite db
    """

    existence = False
    id_study_last = None

    with conn:
        cur = conn.cursor()    
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='Studies'")
    qresult = cur.fetchone()
    if (qresult != None):
        existence = True
        cur.execute("SELECT MAX(ID_STUDY) FROM Studies")
        qresult = cur.fetchone()
        id_study_last = qresult[0]
    conn.commit()
    if id_study_last == None:
        id_study_last = 0
    return (existence, id_study_last)

def print_values(ssr_dict):
    """A function which returns a nicely formatted string, dependent upon the columns
    updated for use in an INSERT statement.
    """
    
def is_positive_int(s):
    """A function to get a positive integer
    """
    try:
        int(s)
        if s > 0:
            return True
        else:
            return False
    except ValueError:
        return False

def iso8601(str):
    """
    Adapted from https://pypi.python.org/pypi/iso8601
    
        I adapted this because his version was not strict. This one
        is.

    Note we don't need the Python place holders, but I will leave
    them because I think it makes the string a bit clearer.
    
    """
    
    ISO8601_REGEX = re.compile(
         r"""
         (?P<year>[0-9]{4})
         (
             (
                 (-(?P<monthGdash>[0-9]{2}))
                 |
                 (?P<month>[0-9]{2})
                 (?!$)  # Don't allow YYYYMM
             )
             (
                 (
                     (-(?P<daydash>[0-9]{2}))
                     |
                     (?P<day>[0-9]{2})
                 )
                 (
                     (
                         (?P<separator>[T])
                         (?P<hour>[0-9]{2})
                         (:{0,1}(?P<minute>[0-9]{2})){0,1}
                         (
                             :{0,1}(?P<second>[0-9]{1,2})
                             ([.,](?P<second_fraction>[0-9]+)){0,1}
                         ){0,1}
                         (?P<timezone>
                             Z
                             |
                             (
                                 (?P<tz_sign>[-+])
                                 (?P<tz_hour>[0-9]{2})
                                 :{0,1}
                                 (?P<tz_minute>[0-9]{2}){0,1}
                             )
                         ){0,1}
                     ){0,1}
                 )
             ){0,1}  # YYYY-MM
         ){0,1}  # YYYY only
         $
         """,re.VERBOSE)
    if ISO8601_REGEX.match(str):
        return True
    return False

def ip(str):
    """
    Checks for a valid IP address
    Lifted wholesale from https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
    """
    IPV6_or_IPV4_REGEX = re.compile(r"""
             # IPv6 RegEx
             (
                  ([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|          # 1:2:3:4:5:6:7:8
                  ([0-9a-fA-F]{1,4}:){1,7}:|                         # 1::                              1:2:3:4:5:6:7::
                  ([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|         # 1::8             1:2:3:4:5:6::8  1:2:3:4:5:6::8
                  ([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|  # 1::7:8           1:2:3:4:5::7:8  1:2:3:4:5::8
                  ([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|  # 1::6:7:8         1:2:3:4::6:7:8  1:2:3:4::8
                  ([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|  # 1::5:6:7:8       1:2:3::5:6:7:8  1:2:3::8
                  ([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|  # 1::4:5:6:7:8     1:2::4:5:6:7:8  1:2::8
                  [0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|       # 1::3:4:5:6:7:8   1::3:4:5:6:7:8  1::8  
                  :((:[0-9a-fA-F]{1,4}){1,7}|:)|                     # ::2:3:4:5:6:7:8  ::2:3:4:5:6:7:8 ::8       ::     
                  fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|     # fe80::7:8%eth0   fe80::7:8%1     (link-local IPv6 addresses with zone index)
                  ::(ffff(:0{1,4}){0,1}:){0,1}
                  ((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
                  (25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|          # ::255.255.255.255   
                                                                     # ::ffff:255.255.255.255  
                                                                     # ::ffff:0:255.255.255.255  (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
                  ([0-9a-fA-F]{1,4}:){1,4}:
                  ((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
                  (25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])           # 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
                  )
             |
             # IPv4 RegEx
             (
                  ((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])
             )
        """,re.VERBOSE)
    if IPV6_or_IPV4_REGEX.match(str):
        return True
    return False

def mimetype(allowableMimeTypes):
    """From https://www.iana.org/assignments/media-types/media-types.xhtml
    """
    
    global mimetypes_map
    
    for str in allowableMimeTypes.split(";"):
        if str.lower() not in mimetypes_map:
            return False
    return True

tidySpace = re.compile(r'\s+')

class InvalidNode(Exception):
    pass

class InvalidEdge(Exception):
    pass

def graph():

    return graphviz.Digraph(comment='Workflow')

def derive_edges():

    edges = {} 
    edges.update(derive_edge(Application.schema()))
    edges.update(derive_edge(Argument.schema()))
    edges.update(derive_edge(ArgumentValue.schema()))
    edges.update(derive_edge(Assumes.schema()))
    edges.update(derive_edge(Assumption.schema()))
    edges.update(derive_edge(Computer.schema()))
    edges.update(derive_edge(Container.schema()))
    edges.update(derive_edge(ContainerType.schema()))
    edges.update(derive_edge(Content.schema()))
    edges.update(derive_edge(Context.schema()))
    edges.update(derive_edge(Contributor.schema()))
    edges.update(derive_edge(Dependency.schema()))
    edges.update(derive_edge(Documentation.schema()))
    edges.update(derive_edge(Employs.schema()))
    edges.update(derive_edge(Entailment.schema()))
    edges.update(derive_edge(Implements.schema()))
    edges.update(derive_edge(Input.schema()))
    edges.update(derive_edge(Involvement.schema()))
    edges.update(derive_edge(Meets.schema()))
    edges.update(derive_edge(Model.schema()))
    edges.update(derive_edge(Parameter.schema()))
    edges.update(derive_edge(Person.schema()))
    edges.update(derive_edge(PersonalData.schema()))
    edges.update(derive_edge(Pipeline.schema()))
    edges.update(derive_edge(Process.schema()))
    edges.update(derive_edge(Product.schema()))
    edges.update(derive_edge(Project.schema()))
    edges.update(derive_edge(Requirement.schema()))
    edges.update(derive_edge(Specification.schema()))
    edges.update(derive_edge(StatisticalInput.schema()))
    edges.update(derive_edge(StatisticalMethod.schema()))
    edges.update(derive_edge(StatisticalVariable.schema()))
    edges.update(derive_edge(Statistics.schema()))
    edges.update(derive_edge(Study.schema()))
    edges.update(derive_edge(Tag.schema()))
    edges.update(derive_edge(TagMap.schema()))
    edges.update(derive_edge(User.schema()))
    edges.update(derive_edge(Uses.schema()))
    edges.update(derive_edge(Value.schema()))
    edges.update(derive_edge(Variable.schema()))
    edges.update(derive_edge(Visualisation.schema()))
    edges.update(derive_edge(VisualisationMethod.schema()))
    edges.update(derive_edge(VisualisationValue.schema()))
    return edges

def derive_edge(schema):
    """
    This is a dictionary indexed on the name of the edge
    Each edge value is a dictionary which may have one of three indexes

    + join
    + source
    + target
    + id

    The values of these dictionaries may contain a single value, as in 
    the case of source and target, otherwise "join" is another dictionary.

    The simple values in id, source and target contain a single entry in
    the form:

    table(column_name)

    The "source" specifies the source table of the edge
    The "target" specifies the target table of the edge
    The "id" specifies the where you will find the origin in the source
    table
    """
    edge = {}
    node = re.search(
        'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+(\S*)\s*\(\s*$',
        schema, re.MULTILINE)    
    if node == None:
        sys.exit("No create table statement for " + schema)
    table = globals()[getattr(Table, node.group(1))()]
    if table.is_relation():
        
        # Two foreign keys will provide a single link.
        # All combinations of foreign keys will be valid many-to-many links

        theKeys = table.foreignKeys()

        # Fsck me, you can use "range" to single loop over zero. How crap
        # is that? So rather than using a for loop, I have to use a bloody
        # while construction. Nowt like consistency is there?
        i = 0
        while i <= len(theKeys) - 2:
            j = i
            while j <= len(theKeys) - 1:
                edgeDetail = {}
                join = {}
                join["source"] = (theKeys[i]["sourceTable"] + "(" +
                    theKeys[i]["sourceColumn"] + ")")                
                join["target"] = ( theKeys[j]["sourceTable"] + "(" +
                    theKeys[j]["sourceColumn"] + ")")                
                edgeDetail["join"] = join
                edgeDetail["source"] = (theKeys[i]["targetTable"] +
                    "(" + theKeys[i]["targetColumn"] + ")")
                edgeDetail["target"] = (theKeys[j]["targetTable"] +
                    "(" + theKeys[j]["targetColumn"] + ")")
                edge[(table.__name__ + "-to-" + 
                    theKeys[j]["targetTable"]).lower()] = edgeDetail                
                j = j + 1
            i = i + 1
    else:
        for key in table.foreignKeys():
            edgeDetail = {}
            targetTable = globals()[getattr(Table, key["sourceTable"])()]
            edgeDetail["source"] = (
                key["sourceTable"] + "(" + 
                key["sourceColumn"] + ")")
            edgeDetail["target"] = (
                key["targetTable"] + "(" + 
                key["targetColumn"] + ")")
            edgeDetail["id"] = ( table.tableName() + 
                "(" + ",".join(table.primaryKeys()[0]) +")" )
            edge[key["sourceColumn"].lower()] = ( edgeDetail )                

    return edge

def labels():

    labels = {} 
    labels.update(get_label(Application.schema()))
    labels.update(get_label(Argument.schema()))
    labels.update(get_label(ArgumentValue.schema()))
    labels.update(get_label(Assumes.schema()))
    labels.update(get_label(Assumption.schema()))
    labels.update(get_label(Computer.schema()))
    labels.update(get_label(Container.schema()))
    labels.update(get_label(ContainerType.schema()))
    labels.update(get_label(Content.schema()))
    labels.update(get_label(Context.schema()))
    labels.update(get_label(Contributor.schema()))
    labels.update(get_label(Dependency.schema()))
    labels.update(get_label(Documentation.schema()))
    labels.update(get_label(Employs.schema()))
    labels.update(get_label(Entailment.schema()))
    labels.update(get_label(Implements.schema()))
    labels.update(get_label(Input.schema()))
    labels.update(get_label(Involvement.schema()))
    labels.update(get_label(Meets.schema()))
    labels.update(get_label(Model.schema()))
    labels.update(get_label(Parameter.schema()))
    labels.update(get_label(Person.schema()))
    labels.update(get_label(PersonalData.schema()))
    labels.update(get_label(Pipeline.schema()))
    labels.update(get_label(Process.schema()))
    labels.update(get_label(Product.schema()))
    labels.update(get_label(Project.schema()))
    labels.update(get_label(Requirement.schema()))
    labels.update(get_label(Specification.schema()))
    labels.update(get_label(StatisticalInput.schema()))
    labels.update(get_label(StatisticalMethod.schema()))
    labels.update(get_label(StatisticalVariable.schema()))
    labels.update(get_label(Statistics.schema()))
    labels.update(get_label(Study.schema()))
    labels.update(get_label(Tag.schema()))
    labels.update(get_label(TagMap.schema()))
    labels.update(get_label(User.schema()))
    labels.update(get_label(Uses.schema()))
    labels.update(get_label(Value.schema()))
    labels.update(get_label(Variable.schema()))
    labels.update(get_label(Visualisation.schema()))
    labels.update(get_label(VisualisationMethod.schema()))
    labels.update(get_label(VisualisationValue.schema()))
    return labels

def get_label(schema):
    """
    A dictionary keyed on table name, followed by a list containing
    columns
    """
    lines = schema.splitlines()
    node = re.search(
        'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+(.*)\s*\(\s*$',
        lines[0])
    if node != None:
        table = node.group(1).strip()
        foreignKeys = []
        fields = {}
        for line in lines[1:]:
            if re.search('^\s*FOREIGN\s+KEY\s*\(', line):
                field = re.search(
                    '^\s*FOREIGN\s+KEY\s*\((.*)\)\s*$',
                    line)
                foreignKeys.append(field.group(1))
            elif (re.search('^\s*CONSTRAINT', line)
            or  re.search('^\s*DEFERRABLE', line)
            or  re.search('^\s*PRIMARY', line)
            or  re.search('^--', line)
            or  re.search('^\s*UNIQUE', line)
            or  re.search('\)\s*$', line)
            or  re.search('^\s*REFERENCES', line)):
                pass
            else:
                fields[(line.split()[0])] = True
        for foreignKey in foreignKeys:
            del fields[foreignKey]
        
    return  { table :  fields.keys() }

def get_nodes(conn, nodes, labels):
    with conn:
        activeNodes = {}    

        cur = conn.cursor()
        for node in nodes:
            if labels[node] == None:
                sys.exit('Problem with ' + node + ': no labels provided')
                 
            cur.execute('SELECT ' + ','.join(labels[node]) + ' FROM ' + node)
            rows = cur.fetchall()

            for row in rows:
                i = 0
                nodeText = "" 
                while i < len(row):
                    if row[i] == None:
                        pass
                    elif nodes[node] == labels[node][i]:
                        className = row[i]
                        nodeText = node + '\\n' + str(row[i]) + nodeText
                    else:
                        nodeText = (nodeText + '\\n' + 
                            labels[node][i] + ' = ' + format_text(row[i]))
                    i = i + 1

            # Should really do something here if className
            # is null - although this will just exception if empty.
            # Actually this indicates something is amiss, so 
            # it is correct behaviour to exception. 
            # It means that something is not lining up in
            # labels and nodes.
            activeNodes[(str(node),str(className))] = nodeText 

    return activeNodes;

def draw_nodes(conn, graph, nodes, labels):
    activeNodes = get_nodes(conn, nodes, labels)
    for activeNode in activeNodes:
        graph.node(str(activeNode[0]) + '.' +  
            str(activeNode[1]), activeNodes[activeNode])
    return activeNodes
    
def format_text(str, length=30):
    # Remove any daft formatting and blank spacing.
    str = ' '.join(str.splitlines())
    tokens = re.split(tidySpace,str)
    output = ''
    lineLength = 0
    for token in tokens:
        if lineLength + len(token) > length:
            output = output + "\\n" + token
            lineLength = len(token)
        else:
            output = output + " " + token
            lineLength = lineLength + 1 + len(token)
    return output

    

def get_edges(conn, edges, labels, activeNodes):
    with conn:

        # Because edges being dealt with in this function are either
        # one-to-one or one-to-many, then because of the possibility
        # of the latter you have to detect the link from the target ID to
        # the source ID, which must perforce give a one-to-one linkage.

        # The join subclause is a relational device which is a link in-
        # stantiated as a table, and in this case we have:

        # source -> join.source <=> join.target -> target 

        cur = conn.cursor()
        activeEdges = {}
        for (classType,className) in activeNodes:
            for edge in edges:
                found = re.search('^(.*)\((.*)\)$',edges[edge]['target'])
                if not found:
                    raise InvalidEdge
                targetTable = found.group(1) 
                targetRow = found.group(2)
                if targetTable != classType:
                    continue
                found = re.search('^(.*)\((.*)\)$',edges[edge]['source'])
                if not found:
                    raise InvalidEdge
                sourceTable = found.group(1)
                sourceRow = found.group(2)
                sys.stderr.write("edge = " + str(edges[edge]) + "\n")
                if 'join' in edges[edge]:
                    found = re.search('^(.*)\((.*)\)$',edges[edge]['join']['target'])
                    if not found:
                        raise InvalidEdge
                    mediatorTargetTable = found.group(1) 
                    mediatorTargetRow = found.group(2)
                    found = re.search('^(.*)\((.*)\)$',edges[edge]['join']['source'])
                    if not found:
                        raise InvalidEdge
                    mediatorSourceTable = found.group(1)
                    mediatorSourceRow = found.group(2)
                    # This is where you need to do it. You need to pick out all the information here and do the necessary sql select and then encode it.
                    sql_string = ("SELECT " +  
                                sourceRow + 
                                " FROM " +
                                sourceTable + ',' + mediatorSourceTable +
                                " WHERE " +
                                sourceTable + "." + sourceRow +
                                " = " +
                                mediatorSourceTable + '.' + mediatorSourceRow +
                                " AND " +
                                mediatorTargetTable + '.' + mediatorTargetRow +
                                " = '" +
                                 str(className) +
                                "'")
                    if debug:
                        sys.stderr.write(sql_string)
                    cur.execute(sql_string)
                else:
                    found = re.search('^(.*)\((.*)\)$',edges[edge]['id'])
                    if not found:
                        raise InvalidEdge
                    idTable = found.group(1)
                    idRow= found.group(2)
                    if idTable != sourceTable:
                        raise InvalidEdge

                    cur.execute("SELECT " +  
                                idRow + 
                                " FROM " +
                                sourceTable +
                                " WHERE " +
                                sourceRow +
                                " = '" +
                                str(className) +
                                "'")

                rows = cur.fetchall()
                for row in rows:
                    label = edge
                    if 'label' in edges[edge]:
                        label = edges[edge]['label']
                    if ('direction' in edges[edge] and
                        edges[edge]['direction'] == 'reverse'):
                        activeEdges[((classType ,str(className)),
                            (sourceTable, str(row[0])))] = label
                    else:
                        activeEdges[((sourceTable, str(row[0])),
                            (classType, str(className)))] = label
                          
        

    return activeEdges
                
def draw_edges(conn, graph, edges, labels, activeNodes):
    with conn:
        activeEdges = get_edges(conn, edges, labels, activeNodes)
        for activeEdge in activeEdges:
            label=activeEdges[activeEdge]
            graph.edge(activeEdge[0][0] + '.' + activeEdge[0][1],
                   activeEdge[1][0] + '.' + activeEdge[1][1],
                   label=label)
        return graph;

def remove_orphans(nodes, edges):
    nodesLeft = nodes.copy()
    result = nodes.copy()
    for edge in edges:
        if edge[0] in nodesLeft:
            del nodesLeft[edge[0]]
        if edge[1] in nodesLeft:
            del nodesLeft[edge[1]]
    for orphan in nodesLeft:
        del result[orphan] 
    return result


def draw_graph(nodes, edges, output=None):

    graph = graphviz.Digraph()
    
    for node in nodes:
                graph.node(str(node[0]) + '.' +  str(node[1]), nodes[node])
    for edge in edges:
        graph.edge(edge[0][0] + '.' + edge[0][1],
               edge[1][0] + '.' + edge[1][1],
                   label=edges[edge])

    if output == None:
        print graph
    else:
        graph.save(output)
