#!/usr/bin/env python3

# last modified: 10.08.15
# author: Doug Salt

import os, subprocess, sys
from glob import glob


import sqlite3
# working directory
working_dir = os.getcwd()
# source code
src_dir = working_dir + "/lib"
sys.path.append(src_dir)

import ssrepi_lib_1_1_6 as ssrepi

#--

# function to initialize the Repository for a Social Simulation
# (SSRep); >> note that the developer needs to customize this function
# for the specific application
    
# initial values

ssrep_array = [
	'Project.MIRACLE', ssrepi.Project({
			'ID_PROJECT': 'MIRACLE',
			'TITLE': 'MIning Relationships Among variables in large datasets from CompLEx systems'
			}),
	'Study.SSS-cluster2', ssrepi.Study({
			'ID_STUDY': 1,
			'LABEL': 'SSS-cluster2 Reconstruction',
			'description': 'This is a project to reconstructi the diagrams and results in Polhill et al. 2013',
			'START_TIME': '2016-05-11',
			'PROJECT': 'MIRACLE'
			}),

	'Application.SSS-cluster2.py', ssrepi.Application({
			'ID_APPLICATION': 'SSS-cluster2.py',
			'PURPOSE': """This code""",
			'VERSION': '1',
			'CALLS_PIPELINE': 'SSS-StopC2-Cluster-create.sh',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'python',
			'LOCATION': 'SSS-cluster2.py'
			}),

	'Specification.OS', ssrepi.Specification({
			'ID_SPECIFICATION': 'OS',
			'LABEL': 'Operating System Version',
			'VALUE': 'Centos 6.8 (Final)',
			}),

	'Specification.number_CPUs', ssrepi.Specification({
			'ID_SPECIFICATION': 'number_CPUs',
			'LABEL': 'Number of CPUs required',
			'VALUE': '64',
			}),

	'Specification.disk_space', ssrepi.Specification({
			'ID_SPECIFICATION': 'disk_space',
			'LABEL': 'Disk space',
			'VALUE': '10T',
			}),

	'Requirement.SSS-cluster2.py.number_CPUs', ssrepi.Requirement({
			'APPLICATION': 'SSS-cluster2.py',
			'MINIMUM': 'number_CPUs'
			}),

	'Requirement.SSS-cluster2.py.disk_space', ssrepi.Requirement({
			'APPLICATION': 'SSS-cluster2.py',
			'MINIMUM': 'disk_space'
			}),

	'Requirement.SSS-cluster2.py.OS', ssrepi.Requirement({
			'APPLICATION': 'SSS-cluster2.py',
			'EXACT': 'OS'
			}),

	'Pipeline.SSS-StopC2-Cluster-create.sh', ssrepi.Pipeline({
			'ID_PIPELINE':'SSS-StopC2-Cluster-create.sh',
			'DESCRIPTION': 'Sets up the SSS-StopC2-Cluster Model',
			'FIRST': 'SSS-StopC2-Cluster-create.sh',
			'NEXT': 'SSS-StopC2-Cluster-run.sh' 
			}),
	'Pipeline.SSS-StopC2-Cluster-run.sh', ssrepi.Pipeline({
			'ID_PIPELINE':'SSS-StopC2-Cluster-run.sh',
			'DESCRIPTION': 'Runs the SSS-StopC2-Cluster Model',
			'FIRST': 'SSS-StopC2-Cluster-run.sh',
			'NEXT': 'SSS-StopC2-Cluster-create2.sh'
			}),
	'Pipeline.SSS-StopC2-Cluster-create2.sh', ssrepi.Pipeline({
			'ID_PIPELINE':'SSS-StopC2-Cluster-create2.sh',
			'DESCRIPTION': 'Sets up the second part of SSS-StopC2-Cluster Model',
			'FIRST': 'SSS-StopC2-Cluster-create2.sh',
			'NEXT': 'SSS-StopC2-Cluster-run2.sh' 
			}),
	'Pipeline.SSS-StopC2-Cluster-run2.sh', ssrepi.Pipeline({
			'ID_PIPELINE':'SSS-StopC2-Cluster-run2.sh',
			'DESCRIPTION': 'Runs the second part of the SSS-StopC2-Cluster Model',
			'FIRST': 'SSS-StopC2-Cluster-run2.sh',
			'NEXT': 'analysege_gpLU2.pl'
			}),
	 'Pipeline.analysege_gpLU2.pl', ssrepi.Pipeline({
			'ID_PIPELINE':'analysege_gpLU2.pl',
			'DESCRIPTION': 'Runs the analysis script',
			'FIRST': 'analysege_gpLU2.pl',
			'NEXT': 'workflow.R'
			}),
	 'Pipeline.workflow.R', ssrepi.Pipeline({
			'ID_PIPELINE':'workflow.R',
			'DESCRIPTION': 'Pairs down the results',
			'FIRST': 'workflow.R',
			'NEXT': 'figure2-3part.R'
			}),
	 'Pipeline.figure2-3part.R', ssrepi.Pipeline({
			'ID_PIPELINE':'figure2-3part.R',
			'DESCRIPTION': 'Produces figure 3 in the paper',
			'FIRST': 'figure2-3part.R',
			'NEXT': 'nonlinearK4bsI.R'
			}),
	 'Pipeline.nonlinearK4bsI.R', ssrepi.Pipeline({
			'ID_PIPELINE':'nonlinearK4bsI.R',
			'DESCRIPTION': 'Produces raw data for table 4 in the paper',
			'FIRST': 'nonlinearK4bsI.R',
			'NEXT': 'table4.R'
			}),
	 'Pipeline.table4.R', ssrepi.Pipeline({
			'ID_PIPELINE':'table4.R',
			'DESCRIPTION': 'Produces table 4 in the paper',
			'FIRST': 'table4.R',
			'NEXT': 'figure2-3s.R'
			}),
	 'Pipeline.figure2-3s.R', ssrepi.Pipeline({
			'ID_PIPELINE':'figure2-3s.R',
			'DESCRIPTION': 'Produces figure 4 in the paper',
			'FIRST': 'figure2-3s.R',
			'NEXT': 'treehist3.pl'
			}),
	 'Pipeline.treehist3.pl', ssrepi.Pipeline({
			'ID_PIPELINE':'treehist3.pl',
			'DESCRIPTION': 'Produces figure 5 in the paper',
			'FIRST': 'treehist3.pl',
			'NEXT': 'figure2-3small.R'
			}),

	 'Pipeline.figure2-3small.R', ssrepi.Pipeline({
			'ID_PIPELINE':'figure2-3small.R',
			'DESCRIPTION': 'Produces the appendix in the paper',
			'FIRST': 'figure2-3small.R'
			}),

	'Person.doug_salt', ssrepi.Person({
			'ID_PERSON': 'doug_salt',
			'NAME': 'Doug Salt',
			'EMAIL': 'doug.salt@hutton.ac.uk'
			}),
	'Person.gary_polhill', ssrepi.Person({
			'ID_PERSON': 'gary_polhill',
			'NAME': 'J. Gary Polhill',
			'EMAIL': 'gary.polhill@hutton.ac.uk'
			}),
	'Person.lorenzo_milazzo', ssrepi.Person({
			'ID_PERSON': 'lorenzo_milazzo',
			'NAME': 'Lorenzo Milazzo',
			'EMAIL': 'lorenzo.milazzo@hutton.ac.uk'
			}),

	'User.ds42723', ssrepi.User({
			'ID_USER': 'ds42723',
			'HOME_DIR': '/home/ab/ds42723',
			'ACCOUNT_OF': 'doug_salt'
			}),
	'User.gp408285', ssrepi.User({
			'ID_USER': 'gp40285',
			'HOME_DIR': '/home/ab/gp',
			'ACCOUNT_OF': 'gary_polhill'
			}),

	'Computer.fgridln06', ssrepi.Computer({
			'ID_COMPUTER':  'fgridln06',
			'NAME': 'fgridln06',
			'HOST_ID': 'fgridln06.hutton.ac.uk',
			'IP_ADDRESS': '143.234.88.97',
			'MAC_ADDRESS': 'D4:AE:52:EA:79:CE'
			}),

	'Specification.fgridln06.OS', ssrepi.Specification({
			'ID_SPECIFICATION': 'fgridln06.OS',
			'SPECIFICATION_OF': 'fgridln06',
			'LABEL': 'Operating System Version',
			'VALUE': 'Centos 6.8 (Final)',
			}),

	'Specification.fgridln06.number_CPUs', ssrepi.Specification({
			'ID_SPECIFICATION': 'fgridln06.number_CPUs',
			'SPECIFICATION_OF': 'fgridln06',
			'LABEL': 'Number of CPUs required',
			'VALUE': '64',
			}),

	'Specification.fgridln06.disk_space', ssrepi.Specification({
			'ID_SPECIFICATION': 'fgridln06.disk_space',
			'SPECIFICATION_OF': 'fgridln06',
			'LABEL': 'Disk space',
			'VALUE': '55T',
			}),

	'Meets.disk_space.fgridln06.disk_space', ssrepi.Meets({	
			'COMPUTER_SPECIFICATION': 'fgridln06.disk_space',
			'REQUIREMENT_SPECIFICATION': 'disk_space'
			}),
	
	'Involvment.gary_polhill.1', ssrepi.Involvement({
			'ROLE': 'Original Author',
			'PERSON': 'gary_polhill',
			'STUDY': 1,
			}),
	'Involvment.doug_salt.1', ssrepi.Involvement({
			'ROLE': 'Implementor of the metadata gathering',
			'PERSON': 'doug_salt',
			'STUDY': 1,
			}),
	'Involvment.lorenzo_milazzo.1', ssrepi.Involvement({
			'ROLE': 'Original author of the metadata gathering program',
			'PERSON': 'lorenzo_milazzo',
			'STUDY': 1,
			}),
	'Documentation.specification', ssrepi.Documentation({
			"ID_DOCUMENTATION": "specification",
			"TITLE": "Reconstructing the diagrams and results in Polhill et al",
			"DATE": "2016-05-12",
			"DESCRIBES": 1,
			}),
	'Tag.Paper', ssrepi.Tag({
			"ID_TAG": "Paper",
			"LABEL": "Originally a paper"
			}),
	'TagMap.specification', ssrepi.TagMap({
			"TAG": "Paper",
			"DOCUMENTATION": "specification"
			}),
	'Tag.Program', ssrepi.Tag({
			"ID_TAG": "Program",
			"LABEL": "Some code"
			}),
	'Container.specification', ssrepi.Container({
			'ID_CONTAINER': 'specification',
			'LOCATION_TYPE': 'relative_ref',
			'LOCATION_DOCUMENTATION': 'specification',
			'LOCATION_VALUE': '/mnt/storage/SSS/Reconstructin%20the%20diagrams%20and%20results%20in%20Polhill%20et%20al.docx',
			'HELD_BY': 'doug_salt',
			'SOURCED_FROM': 'gary_polhill'
			}),

	'Contributor.gary_polhill.fearlus-1.1.5.2_spom-2.3', ssrepi.Contributor({
			'CONTRIBUTION': 'Author',
			'ALIAS': 'Gary',
			'CONTRIBUTOR': 'gary_polhill',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3'
			}),
	'Contributor.gary_polhill.SSS-StopC2-Cluster-run.sh', ssrepi.Contributor({
			'CONTRIBUTION': 'Author',
			'ALIAS': 'Gary',
			'CONTRIBUTOR': 'gary_polhill',
			'APPLICATION': 'SSS-StopC2-Cluster-run.sh'
			}),
	'Contributor.gary_polhill.SSS-StopC2-Cluster-create.sh', ssrepi.Contributor({
			'CONTRIBUTION': 'Author',
			'ALIAS': 'Gary',
			'CONTRIBUTOR': 'gary_polhill',
			'APPLICATION': 'SSS-StopC2-Cluster-create.sh'
			}),
	'Contributor.gary_polhill.SSS-StopC2-Cluster-expt.pl', ssrepi.Contributor({
			'CONTRIBUTION': 'Author',
			'ALIAS': 'Gary',
			'CONTRIBUTOR': 'gary_polhill',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl'
			}),
	'Contributor.gary_polhill.specification', ssrepi.Contributor({
			'CONTRIBUTION': 'Author',
			'ALIAS': 'Gary',
			'CONTRIBUTOR': 'gary_polhill',
			'DOCUMENTATION': 'specification'
			}),

	'Contributor.doug_salt.SSS-cluster2.py', ssrepi.Contributor({
			'CONTRIBUTION': 'Developer',
			'ALIAS': 'Doug',
			'CONTRIBUTOR': 'doug_salt',
			'APPLICATION': 'SSS-cluster2.py'
			}),

	'Application.analysege_gp.pl', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gp.pl',
			'PURPOSE': 'Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.',
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'LOCATION': 'analysege_gp.pl'
			}),
	'Container.analysege_gp.pl', ssrepi.Container({
			'ID_CONTAINER': 'analysege_gp.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_Script',
			'LOCATION_VALUE': '/home/ab/gp/swarm/fearlus/expt/SSS-cluster2/analysege_gp.pl'

			}),
	'Application.analysege_gp.pl(mac version)', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gp.pl(mac version)',
			'PURPOSE': """Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.
he Mac version of analysege_gp.pl correctly uses $report[3] rather than $report[1] when getting the income of land managers from ManagerIncomeReport. It also has a column heading for Expenditure, which the fgridlnX version does not. Further, it initialises $n_years to 0 in get_occupancy, which the fgridlnX version does not. Another difference is in the directory used for different batches of runs, which was due to the different ways the results were stored on different machines, and is unimportant.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'REVISION': 'analysege_gp.pl',
			'LOCATION': 'analysege_gp.pl(mac version)'
			}),
	'Application.analysege_gp2.pl', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gp2.pl',
			'PURPOSE': """Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.

On the Mac, I have analysege_gp2.pl, which is identical to the Mac version of analysege_gp.pl, except that it wrongly uses $report[1] to get the income.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'REVISION': 'analysege_gp.pl(mac version)',
			'LOCATION': 'analysege_gp2.pl'
			}),
	'Container.analysege_gp2.pl', ssrepi.Container({
			'ID_CONTAINER': 'analysege_gp2.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_Script',
			'LOCATION_VALUE': '/home/ab/gp/swarm/fearlus/expt/SSS-cluster2/mac-20150123/analysege_gp2.pl'

			}),

	'Application.analysege_gpLU.pl', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gpLU.pl',
			'PURPOSE': """Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.
On the Mac, I have analysege_gpLU.pl, which (when compared with the Mac version of analysege_gp.pl) seems to add functionality to compute the occupancy of each land use and add these to the columns reported. It further appears to contain some bug fixes:
o In get_income, if income is 0, it will not add $reward divided by $income to $total_preward 
o In get_extinction, it puts 'NA' if a species does not go extinct instead of 'no' 
o In get_occupancy, $shannon, $richness and $equitability are initialised to 0 rather than not defined on declaration.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'REVISION': 'analysege_gp.pl(mac version)',
			'LOCATION': 'analysege_gpLU.pl'
			}),


	'Application.analysege_gpLU2.pl', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gpLU2.pl',
			'PURPOSE': """Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.
On fgridlnX, I have analysege_gpLU2.pl. Apart from an irrelevant change for where to look for results from the second batch of runs, this computes the occupancy differently when compared with analysege_gpLU.pl, using $prop * $nspp for $this_occup[$i  1] instead of just $prop. This seems to correct for a division by $nspp in an earlier computation for $prop.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'REVISION': 'analysege_gpLU.pl',
			'LOCATION': 'analysege_gpLU2.pl'
			}),
	'Container.analysege_gpLU2.pl', ssrepi.Container({
			'ID_CONTAINER': 'analysege_gpLU2.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_Script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/analysege_gpLU2.pl'

			}),

	'Application.analysege_gpLU3.pl', ssrepi.Application( {
			'ID_APPLICATION': 'analysege_gpLU3.pl',
			'PURPOSE': """Works on the raw data, producing output in CSV format summarising the results from each run. It is this output that is used by many of the R scripts.
On fgridlnX, I have analysege_gpLU2.pl. Apart from an irrelevant change for where to look for results from the second batch of runs, this computes the occupancy differently when compared with analysege_gpLU.pl, using $prop * $nspp for $this_occup[$i  1] instead of just $prop. This seems to correct for a division by $nspp in an earlier computation for $prop.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl Script',
			'REVISION': 'analysege_gpLU2.pl',
			'LOCATION': 'analysege_gpLU3.pl'
			}),
	'Container.analysege_gpLU3.pl', ssrepi.Container({
			'ID_CONTAINER': 'analysege_gpLU3.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_Script',
			'LOCATION_VALUE': '/home/ab/gp/swarm/fearlus/expt/SSS-cluster2/analysege_gpLU3.pl'

			}),
	

	'Application.SSS-StopC2-Cluster-create.sh', ssrepi.Application({
			'ID_APPLICATION': 'SSS-StopC2-Cluster-create.sh',
			'PURPOSE': """Shell script to create the SSS preliminary experiments. These are designed to cover sinks/nosinks and RewardActivity/RewardSpecies, at various BETs and ASPs, and for flat and var2 market. There will be 20 runs each.""",
			'VERSION': '1',
			'CALLS_APPLICATION':  'SSS-StopC2-Cluster-expt.pl',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'bash',
			'LOCATION': 'SSS-StopC2-Cluster-create.sh'
			}),
	'Container.SSS-StopC2-Cluster-create.sh', ssrepi.Container({
			'ID_CONTAINER': 'SSS-StopC2-Cluster-create.sh',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Bash_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/SSS-StopC2-Cluster-create.sh'
			}),

	'Application.SSS-StopC2-Cluster-create2.sh', ssrepi.Application({
			'ID_APPLICATION': 'SSS-StopC2-Cluster-create2.sh',
			'PURPOSE': """Shell script to create the SSS preliminary experiments. These are designed to cover sinks/nosinks and RewardActivity/RewardSpecies, at various BETs and ASPs, and for flat and var2 market. There will be 20 runs each.""",
			'VERSION': '1',
			'CALLS_APPLICATION':  'SSS-StopC2-Cluster-expt.pl',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'bash',
			'LOCATION': 'SSS-StopC2-Cluster-create2.sh'
			}),
	'Container.SSS-StopC2-Cluster-create2.sh', ssrepi.Container({
			'ID_CONTAINER': 'SSS-StopC2-Cluster-create2.sh',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Bash_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/SSS-StopC2-Cluster-create2.sh'
			}),

	'Application.SSS-StopC2-Cluster-expt.pl', ssrepi.Application({
			'ID_APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'PURPOSE': """Perl script to create FEARLUS+SPOM parameter files for sources, sinks and sustainability book chapter experiments""",
			'VERSION': 'iii',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl',
			'LOCATION': 'SSS-StopC2-Cluster-expt.pl'
			}),
	'Container.SSS-StopC2-Cluster-expt.pl', ssrepi.Container({
			'ID_CONTAINER': 'SSS-StopC2-Cluster-expt.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_script',
			'LOCATION_VALUE': '/home/ab/gp/swarm/fearlus/expt/SSS-cluster2/mac-20150123/SSS-StopC2-Cluster-expt.pl'
			}),

	'Application.workflow.R', ssrepi.Application( {
			'ID_APPLICATION': 'workflow.R',
			'PURPOSE': """A small R script that emaulates what Gary did with the outputs from the model in an R script. That is it reconsturcts what he did originally in what we presume was an interactive R session. Essentially this scrpt takes the combined results from the model and 
1. Adds two empty columns TSNE.1.X and TSNE.1.Y - this were going to be used for visulisation of the data, but were late abaondoned. The columns have been retained, so that they do not mess up any subsequent programs that use the output.
2, Adds an incentive column.
3. Removes the high bankruptcy rates.
4. Removes high expenditure.
""",
			'VERSION': '1',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R Script',
			'LOCATION': 'workflow.R'
			}),

	'Container.workflow.R', ssrepi.Container({
			'ID_CONTAINER': 'workflow.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/workflow.R'
			}),


	'Uses.workflow.R.SSS-Cluster2-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'workflow.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-results.csv'
			}),

	'Uses.workflow.R.scenarios', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'workflow.R',
			'LOCATOR': 'arg2',
			'IN_FILE': 'scenarios',
			'CONTAINER_TYPE': 'scenarios'
			}),
	'ContainerType.scenarios', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'scenarios',
			'DESCRIPTION': """This is a CSV configuration file workflow.R. This file was derived from previous data and represents all the differing scenarious in which the paper Polhill et al (2013) - 'Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model'  was interested in.""",
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:scenarios.cfg'
			}), 


	'ContainerType.SSS-Cluster2-final-results.csv', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv',
			'DESCRIPTION': """The final product. This contains the results of all the runs of the model, excluding low bankruptcies, high expenditure and correlated with scenario.
			 """,
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:*.csv'
			}), 

	'Product.workflow.R.SSS-Cluster2-final-results.csv', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'workflow.R',
			'LOCATOR': 'arg3',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),

	'Application.figure2-3part.R', ssrepi.Application({
			'ID_APPLICATION': 'figure2-3part.R',
			'PURPOSE': """R Script to produce the graphs, specifically the figure 3 graphs in 'Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model' - Polhill et al (2013)""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R',
			'LOCATION': 'figure2-3part.R'
			}),
	'Container.figure2-3part.R', ssrepi.Container({
			'ID_CONTAINER': 'figure2-3part.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/figure2-3part.R'
			}),

	'Uses.figure2-3part.R.SSS-Cluster2-final-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'figure2-3part.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),
	'Uses.figure2-3part.R.figure3.cfg', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'figure2-3part.R',
			'LOCATOR': 'arg2',
			'IN_FILE': 'figure3.cfg',
			'CONTAINER_TYPE': 'figure3.cfg'
			}),
	'ContainerType.figure3.cfg', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'figure3.cfg',
			'DESCRIPTION': """A small CSV file for configuration indicating which scenarios should be graphed and between which ranges.
			 """,
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:figure.cfg'
			}), 

	'ContainerType.figure3.pdf', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'figure3.pdf',
			'DESCRIPTION': """Figure 3 in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'application/pdf',
			'IDENTIFIER': 'name:figure3.pdf'
			}), 
	'Product.figure2-3part.R.figure3.pdf', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'figure2-3part.R',
			'LOCATOR': 'arg3',
			'IN_FILE': 'figure3.pdf',
			'CONTAINER_TYPE': 'figure3.pdf'
			}),

	
	'Application.nonlinearK4bsI.R', ssrepi.Application({
			'ID_APPLICATION': 'nonlinearK4bsI.R',
			'PURPOSE': """Script to create a table of nonlinear tests for each scenario""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R',
			'LOCATION': 'nonlinearK4bsI.R'
			}),
	'Container.nonlinearK4bsI.R', ssrepi.Container({
			'ID_CONTAINER': 'nonlinearK4bsI.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/nonlinearK4bsI.R'
			}),

	'Uses.nonlinearK4bsI.R.SSS-Cluster2-final-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'nonlinearK4bsI.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),
	'ContainerType.table4.data.csv', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'table4.data.csv',
			'DESCRIPTION': """The raw data for table 4 in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:table4*data*csv'
			}), 
	'Product.nonlinearK4bsI.R.table4.data.csv', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'nonlinearK4bsI.R',
			'LOCATOR': 'arg2',
			'IN_FILE': 'table4.data.csv',
			'CONTAINER_TYPE': 'table4.data.csv'
			}),
	'Uses.table4.R.table4.data.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'table4.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'table4.data.csv',
			'CONTAINER_TYPE': 'table4.data.csv'
			}),
	'Product.table4.R.table4', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'table4.R',
			'LOCATOR': 'arg2',
			'IN_FILE': 'table4',
			'CONTAINER_TYPE': 'table4'
			}),
	'ContainerType.table4', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'table4',
			'DESCRIPTION': """Table 4 IN TEXT FORM in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:table4.csv'
			}), 

	'Application.table4.R', ssrepi.Application({
			'ID_APPLICATION': 'table4.R',
			'PURPOSE': """A small script to prodce a text version of the table found in 

Polhil et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model

The original diagram was done with a mixture of R and Excel. I have automated this part.""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R',
			'LOCATION': 'table4.R'
			}),
	'Container.table4.R', ssrepi.Container({
			'ID_CONTAINER': 'table4.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/table4.R'
			}),


	'Application.figure2-3s.R', ssrepi.Application({
			'ID_APPLICATION': 'figure2-3s.R',
			'PURPOSE': """This is a script to analyse the CSV file created by analysege_gp.pl from the output created by the runs themselves.""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R',
			'LOCATION': 'figure2-3s.R'
			}),
	'Container.figure2-3s.R', ssrepi.Container({
			'ID_CONTAINER': 'figure2-3s.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/figure2-3s.R'
			}),

	'Uses.figure2-3s.R.SSS-Cluster2-final-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'figure2-3s.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),
	'ContainerType.figure4.pdf', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'figure4.pdf',
			'DESCRIPTION': """Figure 4 in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'application/pdf',
			'IDENTIFIER': 'name:figure4*pdf'
			}), 
	'Product.figure2-3s.R.figure4.pdf', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'figure2-3s.R',
			'LOCATOR': 'arg8',
			'IN_FILE': 'figure4.pdf',
			'CONTAINER_TYPE': 'figure4.pdf'
			}),



	'Application.treehist3.pl', ssrepi.Application({
			'ID_APPLICATION': 'treehist3.pl',
			'PURPOSE': """Script to use R to draw a classification tree of some variables, and then draw boxplots of species and land use occupancy.""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'Perl',
			'LOCATION': 'treehist3.pl'
			}),
	'Container.treehist3.pl', ssrepi.Container({
			'ID_CONTAINER': 'treehist3.pl',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Perl_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/treehist3.pl'
			}),

	'Uses.treehist3.pl.SSS-Cluster2-final-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'treehist3.pl',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),
	'ContainerType.figure5.pdf', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'figure5.pdf',
			'DESCRIPTION': """The graphs in Figure 5 in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'application/pdf',
			'IDENTIFIER': 'name:*pdf'
			}), 
	'ContainerType.figure5.tree.pdf', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'figure5.tree.pdf',
			'DESCRIPTION': """The partition tree in Figure 5 in Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
			 """,
			'FORMAT': 'application/pdf',
			'IDENTIFIER': 'name:*pdf'
			}), 
	'Product.treehist3.pl.figure5.pdf', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'treehist3.pl',
			'LOCATOR': 'arg2',
			'IN_FILE': 'figure5.pdf',
			'CONTAINER_TYPE': 'figure5.pdf'
			}),
	'Product.treehist3.pl.figure5.tree.pdf', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'treehist3.pl',
			'LOCATOR': 'arg3',
			'IN_FILE': 'figure5.tree.pdf',
			'CONTAINER_TYPE': 'figure5.tree.pdf'
			}),


	'Application.figure2-3small.R', ssrepi.Application({
			'ID_APPLICATION': 'figure2-3small.R',
			'PURPOSE': """This is a script to analyse the CSV file created by analysege_gp.pl from the output created by the runs themselves.""",
			'VERSION': '1.0',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'R',
			'LOCATION': 'figure2-3small.R'
			}),
	'Container.figure2-3small.R', ssrepi.Container({
			'ID_CONTAINER': 'figure2-3small.R',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'R_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/figure2-3small.R'
			}),

	'Uses.figure2-3small.R.SSS-Cluster2-final-results.csv', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'figure2-3small.R',
			'LOCATOR': 'arg1',
			'IN_FILE': 'SSS-Cluster2-final-results.csv',
			'CONTAINER_TYPE': 'SSS-Cluster2-final-results.csv'
			}),
	'ContainerType.appendix.pdf', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'appendix.pdf',
			'DESCRIPTION': """The graphs in the appendix for Polhill et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model.
			 """,
			'FORMAT': 'application/pdf',
			'IDENTIFIER': 'name:*pdf'
			}), 
	'Product.figure2-3small.R.appendix.pdf', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'figure2-3small.R',
			'LOCATOR': 'arg3',
			'IN_FILE': 'appendix.pdf',
			'CONTAINER_TYPE': 'appendix.pdf'
			}),



	# 1 for each run
	# Positions 0-9
	'ContainerType.dir', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'dir',
			'FORMAT': 'application/x-directory',
			'IDENTIFIER': 'name:SSS_*_'
			}), 
	# 1 for each run
	# Positions 0-11
	# file name appears incorrect
	# The filename is incorrect as this is passed as a
	# variable in arguments to the model
	'ContainerType.top-level', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'top-level',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
			}), 
	# 1 for each run
	# Positions 10 - run
	'ContainerType.spom', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'spom',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_spom_*__________???.spom'
			}), 
	# 1 per directory
	'ContainerType.luhab', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'luhab',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_luhab___________.csv'
			}), 
	# 1 per directory
	'ContainerType.species', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'species',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_species_nosink__________.csv'
			}), 
	# 1 per directory
	'ContainerType.sink', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'sink',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_sink_nosink__________.csv'
			}), 
	# 1 for each run
	# Postions 0,10
	'ContainerType.patch', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'patch',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_patch_*__________???.csv$'
			}), 
	# 1 for each run
	# Positions 1-10
	# filename appears incorrect
	'ContainerType.fearlus', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'fearlus',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_fearlus__*_*_*_*_*_*_*_*_*_???.fearlus'
			}), 
	# 1 per directory.
	# Positions 8,9,10 - approval, iwealth, aspiration
	'ContainerType.top-level-subpop', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'top-level-subpop',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_top-level-subpop________*_*_*_.ssp'
			}), 
	# 1 per directory.
	# Positions 7,8,9 - approval, iwealth, aspiration
	'ContainerType.subpop', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'subpop',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_subpop________*_*_*_.sp'
			}), 
	# 1 per directory
	# Positions 7 - approval
	'ContainerType.event', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'event',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_event________*___.event'
			}), 
	# 1 per directory
	# Positions 7 - approval
	'ContainerType.trigger', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'trigger',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_trigger________*___.event'
			}), 
	# 1 per directory
	'ContainerType.climateprob', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'climateprob',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_climateprob___________.prob'
			}), 
	# 1 per directory
	'ContainerType.economyprob', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'economyprob',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_economyprob___________.prob'
			}), 
	# 1 per directory
	# Positions 2 - market
	'ContainerType.economystate', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'economystate',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_economystate______*_____.state'
			}), 
	# 1 per directory
	# Positions 2 - market
	'ContainerType.incometree', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'incometree',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_incometree______*_____.state'
			}), 
	# 1 per directory
	# Positions 2 - market
	'ContainerType.incomedata', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'incomedata',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_incomedata______*_____.data'
			}), 
	# 1 per directory
	'ContainerType.yieldtree', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'yieldtree',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_yieldtree___________.tree'
			}), 
	# 1 per directory
	'ContainerType.yielddata', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'yielddata',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_yielddata___________.data'
			}), 
	# 1 per run. 
	# This appears to be the land use initialisation file
	# for that particular directory for each run.
	'ContainerType.grid', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'grid',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_grid___________???.grd'
			}), 
	# 1 per directory.
	# Positions 1,2,3,4 - government, sink, market, zone
	'ContainerType.government', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'government',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_*______.gov'
			}), 
	# 1 per run
	# Filename appears to be incorrect
	# This appears to point to an output file
	# This file name is incorrect because this is passed as one
	# of the parameters to the model.
	'ContainerType.report-config', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'report-config',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
			}), 

	
	# Outputs from 'SSS-StopC2-Cluster-expt.pl',

	'Product.SSS-StopC2-Cluster-expt.pl.dir', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'LOCATOR': 'CWD',
			'CONTAINER_TYPE': 'dir'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.top-level', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'top-level',
			'CONTAINER_TYPE': 'top-level'
			}),

	'Product.SSS-StopC2-Cluster-expt.pl.spom', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'spom',
			'CONTAINER_TYPE': 'spom'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.luhab', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'luhab',
			'CONTAINER_TYPE': 'luhab'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.species', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'species',
			'CONTAINER_TYPE': 'species'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.sink', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'sink',
			'CONTAINER_TYPE': 'sink'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.patch', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'patch',
			'CONTAINER_TYPE': 'patch'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.fearlus', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'fearlus'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.top-level-subpop', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'top-level-subpop',
			'CONTAINER_TYPE': 'top-level-subpop'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.subpop', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'subpop',
			'CONTAINER_TYPE': 'subpop'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.event', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'event',
			'CONTAINER_TYPE': 'event'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.trigger', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'trigger',
			'CONTAINER_TYPE': 'trigger'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.climateprob', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'climateprob'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.economyprob', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'economyprob'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.economystate', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'economystate'
			}),

	'Product.SSS-StopC2-Cluster-expt.pl.incometree', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'incometree'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.incomedata', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'incomedata'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.yieldtree', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'yieldtree'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.yielddata', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'yielddata'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.grid', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'grid'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.government', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'government',
			'CONTAINER_TYPE': 'government'
			}),
	'Product.SSS-StopC2-Cluster-expt.pl.report-config', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'IN_FILE': 'report-config',
			'CONTAINER_TYPE': 'report-config'
			}),

	# Inputs to 'fearlus-1.1.5.2_spom-2.3',

	'Uses.fearlus-1.1.5.2_spom-2.3.dor', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LOCATOR': 'CWD',
			'CONTAINER_TYPE': 'dir'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.top-level', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LOCATOR': 'opt=-p',
			'IN_FILE': 'top-level',
			'CONTAINER_TYPE': 'top-level'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.spom', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'spom',
			'CONTAINER_TYPE': 'spom'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.luhab', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'luhab',
			'CONTAINER_TYPE': 'luhab'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.species', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'species',
			'CONTAINER_TYPE': 'species'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.sink', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'sink',
			'CONTAINER_TYPE': 'sink'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.patch', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'patch',
			'CONTAINER_TYPE': 'patch'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.fearlus', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'top-level',
			'CONTAINER_TYPE': 'fearlus'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.top-level-subpop', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'fearlus',
			'CONTAINER_TYPE': 'top-level-subpop'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.subpop', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'subpop',
			'CONTAINER_TYPE': 'subpop'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.event', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'event',
			'CONTAINER_TYPE': 'event'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.trigger', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'trigger',
			'CONTAINER_TYPE': 'trigger'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.climateprob', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'climateprob',
			'CONTAINER_TYPE': 'climateprob'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.economyprob', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'economyprob',
			'CONTAINER_TYPE': 'economyprob'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.economystate', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'economystate',
			'CONTAINER_TYPE': 'economystate'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.incometree', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'incometree',
			'CONTAINER_TYPE': 'incometree'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.incomedata', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'incomedata',
			'CONTAINER_TYPE': 'incomedata'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.yieldtree', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'yieldtree',
			'CONTAINER_TYPE': 'yieldtree'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.yielddata', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'yielddata',
			'CONTAINER_TYPE': 'yielddata'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.grid', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'grid',
			'CONTAINER_TYPE': 'grid'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.government', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'IN_FILE': 'government',
			'CONTAINER_TYPE': 'government'
			}),
	'Uses.fearlus-1.1.5.2_spom-2.3.report-config', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LOCATOR': 'opt=-R',
			'IN_FILE': 'report-config',
			'CONTAINER_TYPE': 'report-config'
			}),



	# Outputs
	# =======

	# 140 of these.
	# Positions 0-10 with 
	# These appear to be file name builders with the file name 
	# suffices of:
	#      _area.csv
	#      _extinct.csv
	#      _habgrid.csv
	#      _lspp.csv
	#      _nspp.csv
	#      _prop.csv
	#      _pspp.csv

	# These are taken care of from below.
	# These are output report files, as 7 x 20 = 140
	#'ContainerType.spomresult', ssrepi.ContainerType({
	#		'ID_CONTAINER_TYPE': 'spomresult',
	#		'FORMAT': 'text/plain',
	#		'IDENTIFIER': 'name:SSS_spomresult*csv'
	#		}), 
	# 1 per run
	# Filename appears to be incorrect
	# I think these are outputs.
	# This file name is incorrect because this is passed as one
	# of the parameters to the model.
	'ContainerType.report', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'report',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???.txt'
			}), 
	# 1 per run
	# The stdout file
	'ContainerType.out', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'out',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???.out'
			}), 
	# 1 per run
	# The error file
	'ContainerType.err', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'err',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???.err'

			}), 

	
	# Reports
	# =======

	# 1 per run
	# This is defined in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.report_grd', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'report_grd',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???.grd'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.propResultsFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'propResultsFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_prop.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.extinctionFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'extinctionFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_extinct.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.nbSpeciesFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'nbSpeciesFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_nspp.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.listSpeciesFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'listSpeciesFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_lspp.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.speciesPerPatchFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'speciesPerPatchFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_pspp.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.areaCurveFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'areaCurveFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_area.csv'
			}), 
	# 1 per run
	# This is the output defined in the
	# SSS_top-level_*_*_*_*_*_*_*_*_*_*_???.model'
	# which in turns points to 
	# SSS_spom_nosink__________???.spom
	# which contains this file name 
	# The parameters for this file are found in 
	# SSS_report_*_*_*_*_*_*_*_*_*_*_???.repcfg'
	'ContainerType.habitatGridOutputFile', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'habitatGridOutputFile',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS_report_*_*_*_*_*_*_*_*_*_*_???_habgrid.csv'
			}), 
	

	'Product.fearlus-1.1.5.2_spom-2.3.report', ssrepi.Product({
			'OPTIONALITY': 'always',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LOCATOR': 'opt=-r',
			'IN_FILE': 'report',
			'CONTAINER_TYPE': 'report'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.out', ssrepi.Product({
			'OPTIONALITY': 'always',
			'LOCATOR': 'STDOUT',
			'IN_FILE': 'out',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'out'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.err', ssrepi.Product({
			'OPTIONALITY': 'always',
			'LOCATOR': 'STDERR',
			'IN_FILE': 'err',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'err'
			}),

	'Product.fearlus-1.1.5.2_spom-2.3.report_grd', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'report-config',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'report_grd'
			}),
	

	'Product.fearlus-1.1.5.2_spom-2.3.propResultsFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'propResultsFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.extinctionFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'extinctionFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.nbSpeciesFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'nbSpeciesFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.listSpeciesFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'listSpeciesFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.speciesPerPatchFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'speciesPerPatchFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.areaCurveFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'areaCurveFile'
			}),
	'Product.fearlus-1.1.5.2_spom-2.3.habitatGridOutputFile', ssrepi.Product({
			'OPTIONALITY': 'always',
			'IN_FILE': 'spom',
			'APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'CONTAINER_TYPE': 'habitatGridOutputFile'
			}),


	'Uses.analysege_gpLU2.pl.report_grd', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'IN_FILE': 'report-config',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'report_grd'
			}),
	
	'Uses.analysege_gpLU2.pl.report', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'IN_FILE': 'report',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'report'
			}),

	'Uses.analysege_gpLU2.pl.propResultsFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'IN_FILE': 'spom',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'propResultsFile'
			}),
	'Uses.analysege_gpLU2.pl.extinctionFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'extinctionFile'
			}),
	'Uses.analysege_gpLU2.pl.nbSpeciesFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'nbSpeciesFile'
			}),
	'Uses.analysege_gpLU2.pl.listSpeciesFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'IN_FILE': 'spom',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'listSpeciesFile'
			}),
	'Uses.analysege_gpLU2.pl.speciesPerPatchFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'speciesPerPatchFile'
			}),
	'Uses.analysege_gpLU2.pl.areaCurveFile', ssrepi.Uses({
			'LOCATOR': 'CWD PATH REGEX',
			'OPTIONALITY': 'required',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'areaCurveFile'
			}),
	'Uses.analysege_gpLU2.pl.habitatGridOutputFile', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD PATH REGEX',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'habitatGridOutputFile'
			}),
	'Uses.analysege_gpLU2.pl.dir', ssrepi.Uses({
			'OPTIONALITY': 'required',
			'LOCATOR': 'CWD',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'dir'
			}),


	# Output from analsysege_gp.pl

	'ContainerType.SSS-Cluster2-results.csv', ssrepi.ContainerType({
			'ID_CONTAINER_TYPE': 'SSS-Cluster2-results.csv',
			'FORMAT': 'text/plain',
			'IDENTIFIER': 'name:SSS-Cluster2-results*csv'
			}), 


	'Product.analysege_gpLU2.pl.SSS-Cluster2-results.csv', ssrepi.Product({
			'OPTIONALITY': 'always',
			'LOCATOR': 'STDOUT',
			'APPLICATION': 'analysege_gpLU2.pl',
			'CONTAINER_TYPE': 'SSS-Cluster2-results.csv'
			}),


	# Variables
	# =========

	'Variable.sink', ssrepi.Variable({
			'ID_VARIABLE': 'sink',
			'NAME': 'File Type',
			'DATA_TYPE': '{\'NO\'}',
			}),
	'Variable.government', ssrepi.Variable({
			'ID_VARIABLE': 'government',
			'NAME': 'Government Type',
			'DATA_TYPE': '{\'clusterActivity\',\'ClusterSpecies\',\'RewardActivity\',\'RewardSpecies\'}',
			}),
	'Variable.zone', ssrepi.Variable({
			'ID_VARIABLE': 'zone',
			'NAME': 'Policy Zone',
			'DATA_TYPE': '{\'all\'}',
			}),
	'Variable.reward', ssrepi.Variable({
			'ID_VARIABLE': 'reward',
			'NAME': 'Reward Budget',
			'DATA_TYPE': '{1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0}',
			}),
	'Variable.ratio', ssrepi.Variable({
			'ID_VARIABLE': 'ratio',
			'NAME': 'Cluster Reward Ratio',
			'DATA_TYPE': '{1.0,2.0,10.0}',
			}),
	'Variable.market', ssrepi.Variable({
			'ID_VARIABLE': 'market',
			'NAME': 'Market',
			'DATA_TYPE': '{\'flat\',\'var2\'}',
			}),
	'Variable.bet', ssrepi.Variable({
			'ID_VARIABLE': 'bet',
			'NAME': 'Break even threshold',
			'DATA_TYPE': '{25.0,30.0}',
			}),
	'Variable.approval', ssrepi.Variable({
			'ID_VARIABLE': 'approval',
			'NAME': 'Approval',
			'DATA_TYPE': '{\'NO\'}',
			}),
	'Variable.iwealth', ssrepi.Variable({
			'ID_VARIABLE': 'iwealth',
			'NAME': 'Initial wealth',
			'DATA_TYPE': '{0.0}',
			}),
	'Variable.aspiration', ssrepi.Variable({
			'ID_VARIABLE': 'aspiration',
			'NAME': 'Aspiration threshold',
			'DATA_TYPE': '{1.0,5.0}',
			}),
	'Variable.run', ssrepi.Variable({
			'ID_VARIABLE': 'run',
			'NAME': 'Run number',
			'DATA_TYPE': 'xsd:nonNegativeInteger[>=1, <= 20]',
			}),

	'Content.spom.sink', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'spom',
			'VARIABLE': 'sink',
			'LOCATOR': 'split(\'_\')[2]'
			}),
	'Content.fearlus.government', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'fearlus',
			'VARIABLE': 'government',
			'LOCATOR': 'split(\'_\')[3]'
			}),
	'Content.government.zone', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'government',
			'VARIABLE': 'zone',
			'LOCATOR': 'split(\'_\')[4]'
			}),
	'Content.government.reward', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'government',
			'VARIABLE': 'reward',
			'LOCATOR': 'split(\'_\')[5]'
			}),
	'Content.economystate.market', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'economystate',
			'VARIABLE': 'market',
			'LOCATOR': 'split(\'_\')[7]'
			}),

	

	'Argument.government', ssrepi.Argument({
			'ID_ARGUMENT': 'government',
			'TYPE': 'required',
			'DESCRIPTION': 'Government Type',
			'RANGE': '{\'clusterActivity\',\'ClusterSpecies\',\'RewardActivity\',\'RewardSpecies\'}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '1',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'government'
			}),
	'Argument.sink', ssrepi.Argument({
			'ID_ARGUMENT': 'sink',
			'TYPE': 'required',
			'DESCRIPTION': 'File Type',
			'RANGE': '{\'NO\'}',
			'ARGSEP': 'white space',
			'ORDER_VALUE': '2',
			'ARITY': '1',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'sink'
			}),
	'Argument.market', ssrepi.Argument({
			'ID_ARGUMENT': 'market',
			'TYPE': 'required',
			'DESCRIPTION': 'Market',
			'RANGE': '{\'flat\',\'var2\'}',
			'ARGSEP': 'white space',
			'ORDER_VALUE': '3',
			'ARITY': '1',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'market'
			}),
	'Argument.zone', ssrepi.Argument({
			'ID_ARGUMENT': 'zone',
			'TYPE': 'required',
			'DESCRIPTION': 'Policy Zone',
			'RANGE': '{\'all\'}',
			'ARGSEP': 'white space',
			'ORDER_VALUE': '4',
			'ARITY': '1',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'zone'
			}),
	'Argument.reward', ssrepi.Argument({
			'ID_ARGUMENT': 'reward',
			'TYPE': 'required',
			'DESCRIPTION': 'Reward Budget',
			'RANGE': '{1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0}',
			'ARGSEP': 'white space',
			'ORDER_VALUE': '5',
			'ARITY': '1',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'reward'
			}),
	'Argument.ratio', ssrepi.Argument({
			'ID_ARGUMENT': 'ratio',
			'TYPE': 'required',
			'DESCRIPTION': 'Cluster Reward Ratio',
			'RANGE': '{1.0,2.0,10.0}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '6',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'ratio'
			}),
	'Argument.bet', ssrepi.Argument({
			'ID_ARGUMENT': 'bet',
			'TYPE': 'required',
			'DESCRIPTION': 'Break even threshold',
			'RANGE': '{25.0,30.0}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '7',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'bet'
			}),
	'Argument.approval', ssrepi.Argument({
			'ID_ARGUMENT': 'approval',
			'TYPE': 'required',
			'DESCRIPTION': 'Approval',
			'RANGE': '{\'NO\'}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '8',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'approval'
			}),
	'Argument.iwealth', ssrepi.Argument({
			'ID_ARGUMENT': 'iwealth',
			'TYPE': 'required',
			'DESCRIPTION': 'Initial wealth',
			'RANGE': '{0.0}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '9',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl',
			'VARIABLE': 'iwealth'
			}),

	'Argument.aspiration', ssrepi.Argument({
			'ID_ARGUMENT': 'aspiration',
			'TYPE': 'required',
			'DESCRIPTION': 'Aspiration threshold',
			'RANGE': '{1.0,5.0}',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '10',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl'  ,
			'VARIABLE': 'aspiration'
			}),
	'Argument.run', ssrepi.Argument({
			'ID_ARGUMENT': 'run',
			'TYPE': 'required',
			'DESCRIPTION': 'Run number',
			'RANGE': 'xsd:nonNegativeInteger[>=1, <= 20]',
			'ARGSEP': 'white space',
			'ARITY': '1',
			'ORDER_VALUE': '11',
			'APPLICATION': 'SSS-StopC2-Cluster-expt.pl' ,
			'VARIABLE': 'run'
			}),























	'Content.fearlus.bet', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'fearlus',
			'VARIABLE': 'bet',
			'LOCATOR': 'split(\'_\')[8]'
			}),
	'Content.subpop.approval', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'subpop',
			'VARIABLE': 'approval',
			'LOCATOR': 'split(\'_\')[9]'
			}),
	'Content.subpop.aspiration', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'subpop',
			'VARIABLE': 'aspiration',
			'LOCATOR': 'split(\'_\')[10]'
			}),
	'Content.subpop.iwealth', ssrepi.Content({
			'OPTIONALITY': 'always',
			'CONTAINER_TYPE': 'subpop',
			'VARIABLE': 'iwealth',
			'LOCATOR': 'split(\'_\')[11]'
			}),




	'Application.SSS-StopC2-Cluster-run.sh', ssrepi.Application({
			'ID_APPLICATION': 'SSS-StopC2-Cluster-run.sh',
			'PURPOSE': """Shell script to run the SSS experiments""",
			'VERSION': '1',
			'CALLS_APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'bash',
			'LOCATION': 'SSS-StopC2-Cluster-run.sh'
			}),
	'Container.SSS-StopC2-Cluster-run.sh', ssrepi.Container({
			'ID_CONTAINER': 'SSS-StopC2-Cluster-run.sh',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Bash_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/SSS-StopC2-Cluster-run.sh'
			}),

	'Application.SSS-StopC2-Cluster-run2.sh', ssrepi.Application({
			'ID_APPLICATION': 'SSS-StopC2-Cluster-run2.sh',
			'PURPOSE': """Shell script to run the SSS experiments""",
			'VERSION': '1',
			'CALLS_APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'LICENCE': 'GPLv3',
			'LANGUAGE': 'bash',
			'LOCATION': 'SSS-StopC2-Cluster-run2.sh'
			}),
	'Container.SSS-StopC2-Cluster-run2.sh', ssrepi.Container({
			'ID_CONTAINER': 'SSS-StopC2-Cluster-run2.sh',
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 'Bash_script',
			'LOCATION_VALUE': '/mnt/storage/doug/SSS/bin/SSS-StopC2-Cluster-run2.sh'
			}),

	'Application.fearlus-1.1.5.2_spom-2.3', ssrepi.Application({
			'ID_APPLICATION': 'fearlus-1.1.5.2_spom-2.3',
			'PURPOSE': """This file is part of FEARLUS/SPOM 1-1-5-2, an agent-based model of land use change and stochastic patch occupancy model""",
			'VERSION': '1.1.5.2_spom-2.3',
			'LICENCE': 'GPLv2',
			'LANGUAGE': 'Objective C',
			'LOCATION': 'fearlus-1.1.5.2_spom-2.3'
			}),
	'Container.fearlus-1.1.5.2_spom-2.3', ssrepi.Container({
			'ID_CONTAINER': 'fearlus-1.1.5.2_spom-2.3',
			'LOCATION_TYPE': 'relative_ref',
			'LOCATION_VALUE': '/home/ab/gp/swarm/fearlus/model1-1-5-2/fearlus-1.1.5.2_spom-2.3'
			})
	
	]


# function to update the SSRep; >> note that the developer needs to
# design and implement a set of update functions for the specific
# application

def updateSSRep(ss_rep, db_specs):
	return ss_rep
	
# function for process spawning - i.e. launch of an application
def spawnProcess(args):
	try:
		print(' '.join(args))
		rcode = subprocess.call(' '.join(args), shell=True)
        
	except OSError as error:
		print '>> OS error: {str1}'.format(str1=error)
	except:
		print '>> unexpected error:', sys.exc_info()[0]
		raise

		
def runMoranIndex(ss_rep, input_file):
	
	#Build the excution string
	execute = []
	if ss_rep['moran_species.R'].ENVS != None:
		execute.append(ss_rep['moran_species.R'].ENVS)
	execute.append(ss_rep['moran_species.R_container'].LOCATION_VALUE)
	execute.append(input_file)
	ss_rep[input_file] = ssrepi.Container({
			'ID_CONTAINER': input_file,
			'LOCATION_VALUE': input_file,
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 
			ss_rep['report_species_distribution'].ID_CONTAINER_TYPE
			})
	output_file = input_file + ".moran_index"
	execute.append(output_file)
	spawnProcess(execute)
	ss_rep[output_file] = ssrepi.Container({
			'ID_CONTAINER': output_file,
			'LOCATION_VALUE': output_file,
			'LOCATION_TYPE': 'relative_ref',
			'INSTANCE': 
			ss_rep['report_species_moran_index'].ID_CONTAINER_TYPE
			})
#--

data_dir = "/mnt/storage/doug/fgridln09/moran_species_reconstruction"

if __name__== "__main__":

	# initializing the (temporary) SS repository
	ss_rep = ssrepi.initially_populate_db(ssrep_array)

	# connecting to the SS db
	db_specs = ssrepi.connect_db(working_dir)
	# initializing the SS db
	ssrepi.init_db(db_specs[0])
	
#	inputs = [y for x in os.walk(data_dir) for y in glob(os.path.join(x[0], '*pspp.csv'))] 
	
#	for input_file in inputs:
#		runMoranIndex(ss_rep, input_file)

	# running the application #01 ...

	#runProcess01(ss_rep, working_dir)
	
	# updating the SS repository ...
	# the updates are performed by using the data associated
	# with the application run
	ss_rep = updateSSRep(ss_rep, db_specs)

	# running the application #02 ...
	# ... updating the SS repository ...
	# ... and so on ...
	
	# exporting the SS repository into the FSS database

	order = [ 
		'Project.MIRACLE', 
		'Study.SSS-cluster2', 
		'Variable.sink',
		'Variable.government',
		'Variable.zone',
		'Variable.reward',
		'Variable.ratio',
		'Variable.market',
		'Variable.bet',
		'Variable.approval',
		'Variable.iwealth',
		'Variable.aspiration',
		'Variable.run',
	 	'ContainerType.top-level',
	 	'ContainerType.spom',
	 	'ContainerType.luhab',
	 	'ContainerType.species',
	 	'ContainerType.sink',
	 	'ContainerType.patch',
	 	'ContainerType.fearlus',
	 	'ContainerType.top-level-subpop',
	 	'ContainerType.subpop',
	 	'ContainerType.event',
	 	'ContainerType.trigger',
	 	'ContainerType.climateprob',
	 	'ContainerType.economyprob',
	 	'ContainerType.economystate',
	 	'ContainerType.incometree',
	 	'ContainerType.incomedata',
	 	'ContainerType.yieldtree',
	 	'ContainerType.yielddata',
	 	'ContainerType.grid',
	 	'ContainerType.government',
	 	'ContainerType.report-config',
		'Person.gary_polhill',
		'Person.doug_salt',
		'Person.lorenzo_milazzo',
		'Container.SSS-StopC2-Cluster-expt.pl',
		'Application.fearlus-1.1.5.2_spom-2.3',
		'Application.SSS-StopC2-Cluster-expt.pl'
		]

	if ssrepi.studies_table_exists(db_specs[0])[0]:
		ssrepi.write_all_to_db(ss_rep, db_specs[0])
	else:
		ssrepi.create_tables(db_specs[0])
		ssrepi.write_all_to_db(ss_rep, db_specs[0])
		
	# disconnecting the SS db
	ssrepi.disconnect_db(db_specs[0])
