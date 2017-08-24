2017-07-28

OK where you are at:

You are tryin to simplify the drawing, and have implemented the code to define all the possible edges (including 3 part relationships), although that is not implemented yet.

You are using new_project.py to do this (considerably simplified from project.py), but are stuck on the fact that it appears that the home key for Containers apppears to be ID_CONTAINER_TYPES. So wrong. This is probably something to do with foreignKeys in ssrep_lib.py, but it needs investigating.

You have are doing a single run to generate diagrams, so do not clear out the directory.

The above was solved. We now have a problem with one-to-many links (it is like I am redoing my relatoinal education all over again). So in the derive_edge routine, you need to create another route to deterimine if the table is one to many (class method) and then set up the edge using the foreign keys from the ends of the relation.
