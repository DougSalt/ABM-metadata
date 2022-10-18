#!/usr/bin/env bash

#cat template.md > ContainerTypes.pl.md
#cat template.md > analysis.py.md
#cat template.md > create_database.py.md
#cat template.md > exists.py.md
#cat template.md > fine_grain.py.md
#cat template.md > folksonomy.py.md
#cat template.md > get_value.py.md
#cat template.md > get_values.py.md
#cat template.md > next_study.py.md
#cat template.md > path.sh.md
#cat template.md > project.py.md
#cat template.md > project_metadata.py.md
#cat template.md > provenance.py.md
#cat template.md > services.py.md
#cat template.md > tbox.py.md
#cat template.md > total.py.md
#cat template.md > update.py.md
#cat template.md > workflow.py.md
#
#cat template.md > ssrepi.py.md

ronn --roff ContainerTypes.pl.md 
ronn --roff analysis.py.md 
ronn --roff create_database.py.md 
ronn --roff exists.py.md 
ronn --roff fine_grain.py.md
ronn --roff folksonomy.py.md
ronn --roff get_value.py.md 
ronn --roff get_values.py.md
ronn --roff next_study.py.md
ronn --roff path.sh.md 
ronn --roff project.py.md
ronn --roff project_metadata.py.md
ronn --roff provenance.py.md
ronn --roff services.py.md
ronn --roff tbox.py.md 
ronn --roff total.py.md
ronn --roff update.py.md
ronn --roff workflow.py.md

ronn --roff ssrepi.py.md 
ronn --roff ssrepi_cli.sh.md 

mv ContainerTypes ContainerTypes.1
mv analysis analysis.1
mv create_database create_database.1
mv exists exists.1
mv fine_grain fine_grain.1
mv folksonomy folksonomy.1
mv get_value get_value.1
mv get_values get_values.1
mv next_study next_study.1
mv path path.1
mv project project.1
mv project_metadata project_metadata.1
mv provenance provenance.1
mv services services.1
mv tbox tbox.1
mv total total.1
mv update update.1
mv workflow workflow.1

mv ssrepi ssrepi.1
mv ssrepi_cli ssrepi_cl.1


