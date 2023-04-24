# 2017-07-28

OK where you are at:

You are tryin to simplify the drawing, and have implemented the code to define all the possible edges (including 3 part relationships), although that is not implemented yet.

You are using new\_project.py to do this (considerably simplified from
project.py), but are stuck on the fact that it appears that the home key for
Containers apppears to be ID\_CONTAINER\_TYPES. So wrong. This is probably
something to do with foreignKeys in ssrep\_lib.py, but it needs investigating.

You have are doing a single run to generate diagrams, so do not clear out the directory.

# 2018-01-09

I tried a run before Xmas, and it looks like somebody stopped it, so I will try again.

# 2022-08-26

This is running on sqllite3, so the tasks are

1. debug the code so it is working on a local database
2. check the postgres setup is still working - this code appears to have disappeared.
3. use the example you have set up to run on postgres
4. learn flex and yacc to decompose and bash script - this will be useful for stuff elsewhere.

As of this date I have converted the code to python3 but there is still something wrong. I am not sure whether the conversion has introduced a bug or               

# 2022-08-16

Well that is a bit of blow. I am convinced I had mostly finished the coding for
postgres and indeed was ready to set it up and test, but it appears not, or the
code has been lost. I am getting an awful sense of deja-vu going through the
code, I know I made extensive notes about this, but cannot for the life of me,
find them.

# 2023-01-30

Loads of changing from the last entry. I have amended everything to now use
Postgres and Sqlite3. I am still re-running the original example (it is stuck
on the post processing at the moment).

Immediate to that I have been working on a paper for MABS (which I am now going
to miss - not necessarily a bad thing, and I still need to work on this paper)
Also working on the documentation for the plugin.

Last week I tided up the documentation.

Specificially, today I have added a new routine to count rows in the database

Okay thinking about SQL queries and in particular how to make these recursive (and if this is even possible, which I am not sure it is)

Okay you create a file called `trace.sql` and this will contain something like 

```
SELECT * from Containers where id_container = 'Containers.container_505627104';
```

You then run it using 

```
psql ssrepi -f trace.sql
```

The problem with this is that you need to know your foreign keys, so what you would need is a SQL statement generator, which you could do.

Ah ha. So you use the diagram generators to generate your SQL statements.

Brilliant. The work is mostly done.

# 2023-02-02

Tidied up the man page area today, so Marie could look at the repository, she has come back with really good suggestions,so I have included them here, so I don't lose them and can make them general targets. 

If you want me (or anyone else who is clueless) to use the code in it, I think that a “very Dummy starter guide” would be most helpful. Like if I wanted to start using it in one of my model, what I need to do in my model itself and for setting up the metadata database? (are all the installation listed compulsory (any version requirement)? Do I need to create the database using a specific code? Your “running the example” seems to imply using linux (may I request some explanation with the code lines examples?) ? Are all the installation underneath required for it? How do I need to amend my code?...).
Maybe all those info are already mostly there and just need a few extra sentence in plain English to help a novice find its way around it (?)
 
Anyway, see what fits with your workplan & which project example(s) you will be focusing on first. Maybe you don’t want to let us (novices) fully free yet with your code, and “dummy” guide would be for later on in your project. 😉
 
# 2023-02-13

I have been pondering graph databases, mainly because Gary asked me to, but I habecome fascinated by them. However, what I am going to do is convert the relational database I have produced from the provenance primitives I have created and convert it to a graph database, for easier querying. This is easy to do because you just take you diagramming tools and do one for the entire database.

It appears obvious that a relational database is largely useless for path based queriesi (which initially I confused with recursive queries).

# 2023-03-13

I am not updating this a much as I should. I finally have clear water when running the processing on this. The script doing the merging of the data was single threaded and taking way to long, so I parallised it. This is "working" inasmuch as it doesn't block properly at the moment. It will block until it has less than or equal to `SSREPI_MAX_PROCESSES` processes left and then continue. This is something I badly overlooked. So what I need to do is set a blank job with a dependency on all the jobs that go before it. 
