#!/usr/bin/env bash

# To read a local man page then use the following command:

# MANPATH=$MANPATH:. man *the_man_page_in_question*

# Comment the following out when initially creating the man pages. DO NOT DO
# THIS IF THERE IS ANY USER GENERATED CONTENT IN THESE FILES.

#cat template.md > ContainerTypes.pl.md
#cat template.md > analysis.py.md
#cat template.md > count.py.md
#cat template.md > create_database.py.md
#cat template.md > exists.py.md
#cat template.md > finegrain.py.md
#cat template.md > folksonomy.py.md
#cat template.md > get_value.py.md
#cat template.md > get_values.py.md
#cat template.md > next_study.py.md
#cat template.md > project.py.md
#cat template.md > project_metadata.py.md
#cat template.md > provenance.py.md
#cat template.md > services.py.md
#cat template.md > ssrepi.py.md
#cat template.md > tbox.py.md
#cat template.md > update.py.md
#cat template.md > workflow.py.md

#cat template.md > ssrepi_cli.sh.md
#cat template.md > path.sh.md
#cat template.md > trace.sh.md

ronn --roff ContainerTypes.pl.md 
ronn --roff analysis.py.md 
ronn --roff count.py.md 
ronn --roff create_database.py.md 
ronn --roff exists.py.md 
ronn --roff finegrain.py.md
ronn --roff folksonomy.py.md
ronn --roff get_value.py.md 
ronn --roff get_values.py.md
ronn --roff next_study.py.md
ronn --roff project.py.md
ronn --roff project_metadata.py.md
ronn --roff provenance.py.md
ronn --roff services.py.md
ronn --roff tbox.py.md 
ronn --roff update.py.md
ronn --roff workflow.py.md
ronn --roff ssrepi.py.md 

ronn --roff path.sh.md 
ronn --roff ssrepi_cli.sh.md 
ronn --roof trace.sh.md

mkdir man1 2>/dev/null

mv ContainerTypes man1/ContainerTypes.1
mv analysis man1/analysis.1
mv count man1/count.1
mv create_database man1/create_database.1
mv exists man1/exists.1
mv finegrain man1/finegrain.1
mv folksonomy man1/folksonomy.1
mv get_value man1/get_value.1
mv get_values man1/get_values.1
mv next_study man1/next_study.1
mv project man1/project.1
mv project_metadata man1/project_metadata.1
mv provenance man1/provenance.1
mv services man1/services.1
mv ssrepi man1/ssrepi.1
mv tbox man1/tbox.1
mv update man1/update.1
mv workflow man1/workflow.1

mv path man1/path.1
mv trace man1/trace.1
mv ssrepi_cli man1/ssrepi_cli.1

