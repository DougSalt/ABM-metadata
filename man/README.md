# PURPOSE

This is the directory containing all the man pages for SSREPI provenance and
metadata framework.

To read a local man page then use the following command:

```
MANPATH=$MANPATH:. man the_man_page_in_question
```

The available man pages are:

+ ContainerTypes made from ContainerTypes.pl.md

+ analysis made from analysis.py.md
+ count made from count.py.md
+ create\_database made from create\_database.py.md
+ exists made from exists.py.md
+ fine\_grain made from fine\_grain.py.md
+ folksonomy made from folksonomy.py.md
+ get\_value made from get\_value.py.md
+ get\_values made from get\_values.py.md
+ next\_study made from next\_study.py.md
+ project made from project.py.md
+ project\_metadata made from project\_metadata.py.md
+ provenance made from provenance.py.md
+ services made from services.py.md
+ ssrepi made from ssrepi.py.md
+ tbox made from tbox.py.md
+ template.md made from template.md.py.md
+ update made from update.py.md
+ workflow made from workflow.py.md

+ path made from path.sh.md
+ ssrepi\_cli made from ssrepi\_cli.sh.md
+ trace made from trace.sh.md

To create the man pages after having edited one of the sources in this
directory then run:

```
make_man_pages.sh
```

This will format the man pages and deliver them to the man1 directory.

# MANIFEST

+ ContainerTypes.pl.md - markdown man page for command ContainerTypes.pl.
+ README.md - markdown man page for command README.
+ analysis.py.md - markdown man page for command analysis.py.
+ count.py.md - markdown man page for command count.py.
+ create\_database.py.md - markdown man page for command create\_database.py.
+ exists.py.md - markdown man page for command exists.py.
+ fine\_grain.py.md - markdown man page for command fine\_grain.py.
+ folksonomy.py.md - markdown man page for command folksonomy.py.
+ get\_value.py.md - markdown man page for command get\_value.py.
+ get\_values.py.md - markdown man page for command get\_values.py.
+ make\_man\_pages.sh - makes the man pages and delivers them to the directory `man1`.
+ man1 - the directory containing the final man pages.
+ next\_study.py.md - markdown man page for command next\_study.py.
+ project.py.md - markdown man page for command project.py.
+ project\_metadata.py.md - markdown man page for command project\_metadata.py.
+ provenance.py.md - markdown man page for command provenance.py.
+ services.py.md - markdown man page for command services.py.
+ ssrepi.py.md - markdown man page for command ssrepi.py.
+ tbox.py.md - markdown man page for command tbox.py.
+ template.md - markdown man page for command template.
+ update.py.md - markdown man page for command update.py.
+ workflow.py.md - markdown man page for command workflow.py.

+ path.sh.md - markdown man page for command path.sh.
+ trace.sh - markdown man page for command trace.sh.
+ ssrepi\_cli.sh.md - markdown man page for command ssrepi\_cli.sh.
