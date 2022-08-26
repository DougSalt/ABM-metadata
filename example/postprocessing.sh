#!/bin/bash

# This is the workflow script used tie all the results together in the post
# processing for this experiment.

# This worries me slightly, because I thought the original experiments were run
# on fgridln06, but I have store the files and run everything on fgridln01. I
# think this may be convention, but I will have to confirm this with Gary

# Author: Doug Salt

# Date: Jan 2017


export PATH=bin:lib:$PATH

. lib/ssrepi_lib.sh

VERSION=1.0
LICENCE=GPLv3
ME=$(SSREPI_application \
        --language=bash \
        --version=$VERSION \
        --licence=$LICENCE )
[ -n "$ME" ] || exit -1

SSREPI_contributor $ME ds42723 Author
SSREPI_contributor $ME ds42723 Developer

# Requirements for this script
# ============================

# Software

required_perl=$(SSREPI_require_minimum perl "5.0")
required_python=$(SSREPI_require_minimum python "2.6.6")
required_shell=$(SSREPI_require_exact shell '/bin/bash')
required_R=$(SSREPI_require_minimum R 3.3.3)
required_os=$(SSREPI_require_exact os Linux)

# Hardware

required_disk_space=$(SSREPI_require_minimum disk_space 20G)
required_nof_cpus=$(SSREPI_require_minimum nof_cpus $NOF_CPUS)
required_memory=$(SSREPI_require_minimum memory 4G)

# Make sure this script meets the requirements.

if SSREPI_fails_minimum_requirement $required_perl $(perl -e 'print $];')
then
        (>&2 echo "$0: Minimum requirement for Perl failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_python \
	$(python --version 2>&1 | cut -f2 -d' ')
then
        (>&2 echo "$0: Minimum requirement for Python failed")
        exit -1
fi

# Don't need to check the shell as the hashbang insists we are running
# under bash, so we just need to set the meets criterion.

SSREPI_meets $required_shell

if SSREPI_fails_exact_requirement $required_os $(uname)
then
        (>&2 echo "$0: Exact requirement for the OS failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_R \
        $(R --version | head -1 | awk '{print $3}')
then
        (>&2 echo "$0: Exact requirement for R failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_disk_space \
	$(df -k . | tail -1 | awk '{print $1}')
then
        (>&2 echo "$0: Minimum requirement for disk space failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_memory \
        $(cat /proc/meminfo | grep MemTotal | awk '{print $2}')000
then
        (>&2 echo "$0: Minimum requirement for memory failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_nof_cpus \
        $(($(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1) + 1))
then
        (>&2 echo "$0: Minimum requirement for number of cpus failed")
        exit -1
fi

# Methods
# =======

aic_id=$(SSREPI_statistical_method aic "The Akaike information criterion (AIC) 
	is a measure of the relative quality of statistical models for a 
	given set of data. Given a collection of models for the data, AIC 
	estimates the quality of each model, relative to each of the other 
	models. Hence, AIC provides a means for model selection.")

bic_id=$(SSREPI_statistical_method bi "Bayesian information criterion (BIC) 
	or Schwarz criterion (also SBC, SBIC) is a criterion for model 
	selection among a finite set of models; the model with the lowest 
	BIC is preferred.")

edf_id=$(SSREPI_statistical_method edf " empirical distribution function is the
	distribution function associated with the empirical measure of a
	sample. This cumulative distribution function is a step function that
	jumps up by 1/n at each of the n data points. Its value at any 
	specified value of the measured variable is the fraction of 
	observations of the measured variable that are less than or equal to 
	the specified value.")

anova_gam_id=$(SSREPI_statistical_method "anova.gam" "Performs
	hypothesis tests relating to one or more fitted gam objects.")

recursive_partitioning_id=$(SSREPI_statistical_method "recursive partioning" \
	"Recursive partitioning for classification,
	regression and survival trees.  An implementation of most of the
	functionality of the 1984 book by Breiman, Friedman, 
	Olshen and Stone.")

sunflower_plot_id=$(SSREPI_visualisation_method \
	"Sunflower plot" \
	"Looks like a sunflower drawn in a 2D space. The sunflower plots 
	are used as variants of scatter plots to display bivariate 
	distribution. When the density of data increases in a particular 
	region of a plot, it becomes hard to read.")

general_additive_model_id=$(SSREPI_visualisation_method \
	"General additive method" \
	"A generalized additive model (GAM) is a generalized linear model 
	in which the linear predictor depends linearly on unknown smooth 
	functions of some predictor variables, and interest focuses on 
	inference about these smooth functions.")

# I really don't like the nomenclature here. I think the conventions adopted
# are totally confusing, but I will go with them.

# In finegrain and analysis it is the Values table we are interested in.

# Process level settings

# + Visualisation -> StatitisticalInput -> Value
# + Statistics -> StatitisticalInput -> Value

# (StatisticalVariable(generated_by) -> StatisticalMethod) ->

# So I have sorted out StatisticalVariable. This is any variable generated a
# statistical method, which can be used (via employs) by a method, and in fact,

# Parameters deal purely with methods. I am presuming all these may
# take values at run time.

# Parameters
# ==========

par_partitioning_complexity_id=$(SSREPI_parameter complexity \
	"Prune all nodes with a complexity less than cp from the output." \
	"x \in \Re: x \in [0,1]" \
	--statistical_method="$recursive_partitioning_id")

# So a variable is in a container of some description and can act as an 
# input to VisualisationMethod, as opposed to a parameter, which is provided
# as an argument. Fair enough. 

# Variables
# =========

var_scenario_id=$(SSREPI_variable  \
	scenario  \
	"The combination of government, market, 
		break-even threshold and aspiration" String \
	$sunflower_plot_id \
	)


# Statistical Variables
# =====================

# These are produced by a statiscal method only.



# Create a pipeline for this script

next=$(SSREPI_create_pipeline $ME)
[ -n "$next" ] || exit -1

THIS_PROCESS=$(SSREPI_process)
[ -n "$THIS_PROCESS" ] || exit -1


# analysege_gpLU2.pl
# ==================

some_script=$(SSREPI_call_perl_script ./bin/analysege_gpLU2.pl \
		--description="
Analysis script to analyse results from SSS runs. The output is a CSV format
summary of the results from each run, listing the parameters first, then
the results: the number of bankruptcies, the amount of land use change,
the year of extinction of each species, and the abundance of each species.

Number of species at a given time step
Level of occupancy at each time step
Shannon index and evenness measure
")
[ -n "$some_script" ] || exit -1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Arguments
# ---------

experiment=$(SSREPI_argument \
        --id_argument=experiment \
        --description="The experimental run for this model. In the range 1-9." \
        --application=$some_script \
        --type=required \
        --order=1 \
        --arity=1 \
        --range="^[0-9]$")
[ -n "$experiment" ] || exit -1

# Input types
# -----------

SSS_report_id=$(SSREPI_input_type $some_script \
        SSS_report \
        "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].txt")
[ -n "$SSS_report_id" ] || exit -1

SSS_report_grd_id=$(SSREPI_input_type $some_script \
        SSS_report_grd \
        "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].grd")
[ -n "$SSS_report_grd_id" ] || exit -1

SSS_spomresult_extinct_id=$(SSREPI_input_type $some_script \
        SSS_spomresult_extinct \
        "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_extinct_id" ] || exit -1

SSS_spomresult_lspp_id=$(SSREPI_output_type $ME \
        SSS_spomresult_lspp \
        "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-lspp.csv")
[ -n "$SSS_spomresult_lspp_id" ] || exit -1

# Output types
# ------------

result_id=$(SSREPI_output_type  $some_script result "^(batch1|batch2).csv$")
[ -n "$result_id" ] || exit -1

# Metadata
# --------

analysege_gpLU2_id=$(SSREPI_statistical_method \
	"Post-run analysis script" \
	"The output is a CSV format
 summary of the results from each run, listing the parameters first, then
 the results: the number of bankruptcies, the amount of land use change,
 the year of extinction of each species, and the abundance of each species.

 Number of species at a given time step
 Level of occupancy at each time step
 Shannon index and evenness measure.")

svar_bankruptcies_id=$(SSREPI_statistical_variable \ \
	bankruptcies \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_land_use_change_id=$(SSREPI_statistical_variable \
	land_use_change \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu1_id=$(SSREPI_statistical_variable \
	occupancy_lu1 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu2_id=$(SSREPI_statistical_variable \
	occupancy_lu2 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu3_id=$(SSREPI_statistical_variable \
	occupancy_lu3 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu4_id=$(SSREPI_statistical_variable \
	occupancy_lu4 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu5_id=$(SSREPI_statistical_variable \
	occupancy_lu5 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_lu6_id=$(SSREPI_statistical_variable \
	occupancy_lu6 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_1_id=$(SSREPI_statistical_variable \
	extinction_spp_1 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)


svar_extinction_spp_2_id=$(SSREPI_statistical_variable \
	extinction_spp_2 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_3_id=$(SSREPI_statistical_variable \
	extinction_spp_3 \
	"Some documentary explanation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_4_id=$(SSREPI_statistical_variable \
	extinction_spp_4 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_5_id=$(SSREPI_statistical_variable \
	extinction_spp_5 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_6_id=$(SSREPI_statistical_variable \
	extinction_spp_6 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_7_id=$(SSREPI_statistical_variable \
	extinction_spp_7 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_8_id=$(SSREPI_statistical_variable \
	extinction_spp_8 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_9_id=$(SSREPI_statistical_variable \
	extinction_spp_9 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_extinction_spp_10_id=$(SSREPI_statistical_variable \
	extinction_spp_10 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)


svar_occupancy_spp_1_id=$(SSREPI_statistical_variable \
	occupancy_spp_1 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_2_id=$(SSREPI_statistical_variable \
	occupancy_spp_2 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_3_id=$(SSREPI_statistical_variable \
	occupancy_spp_3 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_4_id=$(SSREPI_statistical_variable \
	occupancy_spp_4 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_5_id=$(SSREPI_statistical_variable \
	occupancy_spp_5 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_6_id=$(SSREPI_statistical_variable \
	occupancy_spp_6 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_7_id=$(SSREPI_statistical_variable \
	occupancy_spp_7 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_8_id=$(SSREPI_statistical_variable \
	occupancy_spp_8 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_9_id=$(SSREPI_statistical_variable \
	occupancy_spp_9 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_occupancy_spp_10_id=$(SSREPI_statistical_variable \
	occupancy_spp_10 \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_Shannon_id=$(SSREPI_statistical_variable \
	Shannon \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_Equitability_id=$(SSREPI_statistical_variable \
	Equitability \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

svar_richness_id=$(SSREPI_statistical_variable \
	richness \
	"Some documentation." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
	)

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_value $some_process $experiment 8

#for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
#do
#  for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
#  do
#    for sink in nosink
#    do
#      for market in flat var2
#      do
#        for bet in 25.0 30.0
#        do
#          for asp in 1.0 5.0
#          do
#            for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
#            do
#              for rat in 1.0 2.0 10.0
#              do
for run in 001
do
  for govt in ClusterActivity 
  do
    for sink in nosink
    do
      for market in flat var2
      do
        for bet in 25.0 
        do
          for asp in 1.0
          do
            for rwd in 1.0
            do
              for rat in 1.0
              do
		DIR="SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_"
		IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.txt"
		IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.grd";
		IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-extinct.csv";
		IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-lspp.csv";

		SSREPI_input $some_script $some_process $SSS_report_id $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_report_grd_id $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_sompresult_extinct_id eport $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_spomresult_lspp_id $DIR/$IN_1
              done
            done
          done
        done
      done
    done
  done
done

perl ./bin/analysege_gpLU2.pl 8 > batch1.csv
statiscs_set_1=$(SSREPI_statistics statistics.$(uniq)\
	"$analysege_gpLU2_id" \
	"perl ./bin/analysege_gpLU2.pl 8") 

SSREPI_output $some_script $some_process $result_id batch1.csv

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null

)
[ $? -eq 0 ] || exit -1

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_value $some_process $experiment 9

#for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
#do
#  for govt in RewardActivity RewardSpecies
#  do
#    for sink in nosink
#    do
#      for market in flat var2
#      do
#        for bet in 25.0 30.0
#	do
#	  for asp in 1.0 5.0
#	  do
#	    for rwd in 15.0 20.0 25.0 30.0 40.0 50.0 100.0
#	    do
#	      for rat in 1.0 
#	      do
for run in 001
do
  for govt in RewardActivity
  do
    for sink in nosink
    do
      for market in flat var2
      do
        for bet in 25.0
	do
	  for asp in 1.0
	  do
	    for rwd in 15.0
	    do
	      for rat in 1.0 
	      do
		DIR="SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_"
		IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.txt"
		IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.grd";
		IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-extinct.csv";
		IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-lspp.csv";

		SSREPI_input $some_script $some_process $SSS_report_id $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_report_grd_id $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_sompresult_extinct_id eport $DIR/$IN_1
		SSREPI_input $some_script $some_process $SSS_spomresult_lspp_id $DIR/$IN_1
	      done
	    done
	  done
	done
      done
    done
  done
done

analysege_gpLU2.pl 9 > batch2.csv
statiscs_set_2=$(SSREPI_statistics statistics.$(uniq)\
	"$analysege_gpLU2_id" \
	"perl ./bin/analysege_gpLU2.pl 9") 

SSREPI_output $some_script $some_process $result_id batch2.csv

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# I am not bothering to put the os command into the pipeline.
# It is arguable whether it needs to be documented or not.

# Merge
# =====

some_command=$(SSREPI_call_elf $(which tail))
[ -n "$some_command" ] || exit -1


# Input types
# -----------

result_id=$(SSREPI_input_type  $some_command result '^(batch1|batch2).csv$')
[ -n "$result_id" ] || exit -1


# Output types
# ------------

all_results_id=$(SSREPI_output_type  $some_command all_results ^all_results.csv$)
[ -n "$all_results_id" ] || exit -1

# Argument types
# --------------

arg_input_file_id=$(SSREPI_argument \
        --id_argument=arg_result \
        --description="Some file" \
        --application=$some_command \
	--container_type=$result_id \
        --type=required \
        --order=1 \
        --arity="+" \
        --range=relative_ref)
[ -n "$arg_input_file_id" ] || exit -1

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_input $some_command $some_process $result_id batch1.csv
SSREPI_input $some_command $some_process $result_id batch2.csv

tail -n +2 batch1.csv > all_results.csv
tail -n +3 batch2.csv >> all_results.csv

SSREPI_output $some_command $some_process $all_results_id all_results.csv

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# postprocessing.R
# ================

some_script=$(SSREPI_call_R_script $(which postprocessing.R) \
		--licence=$LICENCE \
		--version=1.0 \
		--description="
	A small R script that emaulates what Gary did with the outputs from the
	model in an R script. That is it reconstructs what he did
	originally in what we presume was an interactive R
	session. Essentially this scrpt takes the combined results from the
	model and:

	1. Adds two empty columns TSNE.1.X and TSNE.1.Y - this were going to be
	used for visualisation of the data, but were late abaondoned. The columns have
	been retained, so that they do not mess up any subsequent programs that use the
	output.

	2. Adds an incentive column.

	3. Removes the high bankruptcy rates.

	4. Removes high expenditure.")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

# Input and output types have to be created first as the arguments to
# a function can access an output/input type. In this case the results
# files have already been defined above.

all_results_id=$(SSREPI_input_type  $some_script all_results '^all_results.csv$')
[ -n "$all_results_id" ] || exit -1

scenarios_id=$(SSREPI_input_type $some_script scenarios '^cfg/scenarios.cfg$')
[ -n "$scenarios_id" ] || exit -1

# Output types
# ------------

final_results_id=$(SSREPI_output_type $some_script final_results ^final_results.csv$)
[ -n "$final_results_id" ] || exit -1

# Arguments
# ---------

arg_all_results=$(SSREPI_argument \
        --id_argument=arg_result \
        --description="All the results from all the runs" \
        --application=$some_script \
	--container_type=$all_results_id \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_all_results" ] || exit -1


arg_scenarios=$(SSREPI_argument \
        --id_argument=scenarios \
        --description="The scenarios that are required for processing" \
        --application=$some_script \
	--container_type=$scenarios_id \
        --type=required \
        --order=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_scenarios" ] || exit -1

arg_final_results=$(SSREPI_argument \
        --id_argument=experiment \
        --description="The actual results from which diagrams will be created." \
        --application=$some_script \
	--container_type=$final_results_id \
        --type=required \
        --order=3 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_input_file $some_script $some_process $all_results_id $arg_all_results all_results.csv
SSREPI_argument_input_file $some_script $some_process $scenarios_id $arg_scenarios cfg/scenarios.cfg

postprocessing.R all_results.csv cfg/scenarios.cfg final_results.csv

SSREPI_argument_output_file $some_script $some_process $final_results_id $arg_final_results final_results.csv

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# ============
# # Diagrams #
# ============

# Figure 3
# ========

some_script=$(SSREPI_call_R_script $(which figure2-3part.R) \
		--description="This needs filling in.")
[ -n "$some_script" ] || exit -1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input_type $some_script final_results \
	'^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

figure3_cfg_id=$(SSREPI_input_type $some_script figure3_cfg \
	'^cfg\/figure3\.cfg$')
[ -n "$figure3_cfg_id" ] || exit -1

# Output types
# ------------

figure3_id=$(SSREPI_input_type $some_script figure3 '^figure3.pdf$')
[ -n "$figure3_id" ] || exit -1

# Argument types
# --------------

arg_final_results=$(SSREPI_argument \
        --id_argument=arg_final_results \
        --description="Results files with selected scenarios" \
        --application=$some_script \
	--container=$final_results_file \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_figure3_cfg=$(SSREPI_argument \
        --id_argument=figure3_cfg \
        --description="Configuration to pick correct scenarios for figure 3" \
        --application=$some_script \
        --type=required \
        --order=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure3_cfg" ] || exit -1

arg_figure3=$(SSREPI_argument \
        --id_argument=figure3 \
        --description="Figure 3 pdf" \
        --application=$some_script \
        --type=required \
        --order=1 \
        --arity=3 \
        --range=relative_ref)
[ -n "$arg_figure3" ] || exit -1

# Metadata
# --------

visualisation_method_figure3_id=$(SSREPI_visualisation_method \
	"figure 3" \
	"A sunflower plot with curve fitting, plotting incentive (x-axis)
	against landscape scale species richness (y-axis)")

SSREPI_implements $some_script \
	--visualisation_method="$visualisation_method_figure3_id"

SSREPI_implements $some_script \
	--visualisation_method="$sunflower_plot_id"
SSREPI_implements $some_script \
	--statistical_method="$recursive_partitioning_id"
SSREPI_implements $some_script \
	--visualisation_method="$general_additive_models_id"

var_min_incentive_id=$(SSREPI_variable \
	figure3_min_incentive \
	"Minimum value for horizontal axis in figure 3" \
	"\Z_{\ne 0}" \
	$sunflower_plot_id)

var_max_incentive_id=$(SSREPI_variable \
	figure3_max_incentive \
	"Max value for horizontal axis in figure 3" \
	"\Z_{\ne 0}" \
	"$sunflower_plot_id")

con_figure3_sunflower_plot_id=$(SSREPI_content \
	--visualisation_method="$sunflower_plot_id" \
	--container_type=$figure3_id )

con_scenario_id=$(SSREPI_content \
	--variable=$var_scenario_id \
	--container_type=$figure3_id \
	--locator='grep -v ^scenario | cut -f1 -d,')

con_min_incentive_id=$(SSREPI_content \
	--variable=$var_min_incentive_id \
	--container_type=$figure3_id \
	--locator='grep -v ^scenario | cut -f2 -d,')

con_max_incentive_id=$(SSREPI_content \
	--variable=$var_max_incentive_id \
	--container_type=$figure3_id \
	--locator='grep -v ^scenario | cut -f3 -d,')

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_input_file $some_script $some_process \
	$final_results_id $arg_final_results final_results.csv
SSREPI_argument_input_file $some_script $some_process \
	$figure3_cfg_id $arg_figure3_cfg cfg/figure3.cfg

figure2-3part.R final_results.csv cfg/figure3.cfg figure3.pdf

SSREPI_argument_output_file $some_script $some_process \
	$figure3_id $arg_figure3 figure3.pdf

some_visualisation=$(SSREPI_visualisation \
	visualisation.$(uniq) \
	$sunflower_plot_id \
	"figure2-3part.R final_results.csv cfg/figure3.cfg figure3.pdf" \
	figure3.pdf)

SSREPI_value "A/F/30/1" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 2 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 10 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
SSREPI_value "A/V/30/1" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 2 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 15 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
SSREPI_value "CA/F/25/5" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 1 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 10 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
SSREPI_value "O/F/30/5" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 1 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 8 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
SSREPI_value "O/V/25/1" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 1 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 5 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
SSREPI_value "CO/V/25/5" \
	--contained_in=figure3.pdf \
	--variable=$var_scenario_id
SSREPI_value 0.1 \
	--contained_in=figure3.pdf \
	--variable=$var_min_incentive_id
SSREPI_value 0.8 \
	--contained_in=figure3.pdf \
	--variable=$var_max_incentive_id
	
SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# table 4 for presentation
# ========================

some_script=$(SSREPI_call_R_script $(which nonlinearK4bsI.R) \
		--description="This needs supplying")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input_type $some_script final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

table4_id=$(SSREPI_output_type $some_script table4 '^table4.csv$')
[ -n "$table4_id" ] || exit -1

# Argument types
# --------------

arg_final_results=$(SSREPI_argument \
        --id_argument=final_results \
        --description="Results files with selected scenarios" \
        --application=$some_script \
	--container=$final_results_file \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_table4=$(SSREPI_argument \
        --id_argument=table4 \
        --description="Results for table 4 in the paper" \
        --application=$some_script \
	--container=$table4_id \
        --type=required \
        --order=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

# Metadata
# --------

SSREPI_implements $some_script \
	--statistical_method="$aic_id"
SSREPI_implements $some_script \
	--statistical_method="$bic_id"
SSREPI_implements $some_script \
	--statistical_method="$edf_id"
SSREPI_implements $some_script \
	--statistical_method="$anova_gam_id"

(
some_process=$(SSREPI_process=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_input_file $some_script $some_process $final_results_id $arg_final_results final_results.csv

nonlinearK4bsI.R final_results.csv table4.csv

SSREPI_argument_output_file $some_script $some_process $table4_id $arg_table4 table4.csv

SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $aic_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $bic_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $edf_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $anova_gam_id 

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)

# table 4 paper CSV
# =================

some_script=$(SSREPI_call_R_script $(which table4.R) \
		--description="Need to put some explanation here.")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

table4_id=$(SSREPI_input_type $some_script table4 '^table4.csv$')

# Output types
# ------------

table4_paper_id=$(SSREPI_input_type $some_script table4_paper '^table4.paper.csv$')

# Argument types
# --------------

arg_table4=$(SSREPI_argument \
        --id_argument=table4 \
        --description="Unprocessed table 4" \
        --application=$some_script \
	--container=$table4_id \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

arg_table4_paper=$(SSREPI_argument \
        --id_argument=table4_paper \
        --description="Results for table 4 in the paper" \
        --application=$some_script \
	--container=$table4_paper_id \
        --type=required \
        --order=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_output_file $some_script $some_process $table4_id $arg_table4 table4.csv

table4.R table4.csv table4.paper.csv

SSREPI_argument_output_file $some_script $some_process $table4_paper_id $arg_table4_paper table4.paper.csv

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# figure 4
# ========

some_script=$(SSREPI_call_R_script $(which figure2-3s.R) \
		--description="Need some stuff here.")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input_type $some_script final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

figure4_id=$(SSREPI_input_type $some_script figure4 '^figure4.*\.pdf$')
[ -n "$figure4_id" ] || exit -1

# Argument types
# --------------

arg_splits=$(SSREPI_argument \
        --id_argument=splits \
        --description="I think this might be split the data" \
        --application=$some_script \
	--name="--splits" \
        --type=flag \
        --arity=0 )
[ -n "$arg_splits" ] || exit -1

arg_final_results=$(SSREPI_argument \
        --id_argument=final_results \
        --description="Results files with selected scenarios" \
        --application=$some_script \
	--container=$final_results_file \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_main_scenario=$(SSREPI_argument \
        --id_argument=main_scenario \
        --description="Main scenario" \
        --application=$some_script \
        --type=required \
        --order=2 \
        --arity=1 \
        --range='^.*$')
[ -n "$arg_main_scenario" ] || exit -1

arg_small_scenarios=$(SSREPI_argument \
        --id_argument=small_scenarios \
        --description="Small scenarios" \
        --application=$some_script \
        --type=required \
        --order=3 \
        --arity=5 \
	--argsep=' ' \
        --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$')
[ -n "$arg_small_scenarios" ] || exit -1

arg_figure4=$(SSREPI_argument \
        --id_argument=figure5 \
        --description="PDF for figure 4" \
        --application=$some_script \
        --type=required \
        --order=4 \
	--container=$figure4_id \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure4" ] || exit -1

# Metadata
# --------

SSREPI_implements $some_script --visualisation_method=$sunflower_plot_id

con_figure4_sunflower_plot_id=$(SSREPI_content \
	--visualisation_method=$sunflower_plot_id \
	--container_type=$figure4_id )

con_varscenario_id=$(SSREPI_content \
	--variable=$var_scenario_id \
	--container_type=$figure4_id \
	--locator='grep -v ^scenario | cut -f1 -3,')

(

some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_value $some_process $arg_splits 
SSREPI_argument_value $some_process $arg_main_scenario Richness
SSREPI_argument_value $some_process $arg_small_scenarios \
	"A/F/25/5 A/F/25/1 A/F/30/5 O/F/25/5 CA/F/25/5"
SSREPI_argument_input_file $some_script $some_process $final_results_id \
	$arg_final_results final_results.csv

figure2-3s.R -splits final_results.csv Richness \
	A/F/25/5 A/F/25/1 A/F/30/5 O/F/25/5 CA/F/25/5 figure4.a_and_b.pdf

SSREPI_argument_output_file $some_script $some_process \
	$figure4_id $arg_figure4 figure4.a_and_b.pdf

some_visualistaiton=$(SSREPI_visualisation \
	visualisation.$(uniq) \
	$sunflower_plot_id \
	"figure2-3s.R -splits final_results.csv Richness \
	A/F/25/5 A/F/25/1 A/F/30/5 O/F/25/5 CA/F/25/5 figure4.a_and_b.pdf" \
	figure4.a_and_b.pdf)

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

(
some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_value $some_process $arg_splits 
SSREPI_argument_value $some_process $arg_main_scenario Richness
SSREPI_argument_value $some_process $arg_small_scenarios \
	"O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5"
SSREPI_argument_input_file $some_script $some_process $final_results_id \
	$arg_final_results final_results.csv

figure2-3s.R -splits final_results.csv Richness \
	O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5 figure4.c_and_d.pdf

SSREPI_argument_output_file $some_script $some_process $figure4_id \
	$arg_figure4 figure4.c_and_d.pdf

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# figure 5
# ========

some_script=$(SSREPI_call_perl_script $(which treehist3.pl) \
		--description="Some documentation here, please.")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input_type $some_script final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

figure5_id=$(SSREPI_input_type $some_script figure5 '^.*.PDF$')
[ -n "$figure5_id" ] || exit -1

# Argument types
# --------------

arg_complexity_variable=$(SSREPI_argument \
        --id_argument=complexity_variable \
        --description="Complexity Parameter" \
        --application=$some_script \
	--name="--cp" \
        --type=option \
        --arity=1 \
	--range="^(1|[0\.[0-9]+)$")
[ -n "$arg_complexity_variable" ] || exit -1

arg_final_results=$(SSREPI_argument \
        --id_argument=final_results \
        --description="Results files with selected scenarios" \
        --application=$some_script \
	--container=$final_results_file \
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_figure5=$(SSREPI_argument \
        --id_argument=figure5 \
        --description="PDF for figure 5" \
        --application=$some_script \
        --type=required \
        --order=2 \
	--container=$figure5_id \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure5" ] || exit -1

arg_response_variable=$(SSREPI_argument \
        --id_argument=response_variable \
        --description="Response variable" \
        --application=$some_script \
        --type=required \
        --order=2 \
        --arity=1 \
        --range=".*")
[ -n "$arg_response_variable" ] || exit -1

arg_explanatory_variables=$(SSREPI_argument \
        --id_argument=explanatory_variables \
        --description="Explanatory variables" \
        --application=$some_script \
        --name=expiriment \
        --type=required \
        --order=3 \
        --arity=+ \
	--argsep="," \
        --range="^.*$")
[ -n "$arg_explanatory_variables" ] || exit -1

# Metadata
# --------

SSREPI_implements $some_script \
	--statistical_method="$recursive_partitioning_id"
SSREPI_value --value="0.0075" \
	--statistical_parameter="$par_partitioning_complexity_id"

exit
(

some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_input_file $some_script $some_process $final_results_id \
	$arg_final_results final_results.csv
SSREPI_argument_value $some_process $arg_complexity_variable 0.0075
SSREPI_argument_value $some_process $arg_response_variable Richness
SSREPI_argument_value $some_process $arg_explanatory_variables \
	Government,Market,BET,ASP,Expenditure 

treehist3.pl \
	-cp 0.0075 \
	final_results.csv  \
	LOBEC.rpart3Xfr.pdf  \
	Richness Government,Market,BET,ASP,Expenditure 

SSREPI_argument_output_file $some_script $some_process $figure5_id \
	$arg_figure5 LOBEC.rpart3Xfr.pdf 

SSREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
)
[ $? -eq 0 ] || exit -1

# Appendix 
# ========

some_script=$(SSREPI_call_R_script $(which figure2-3small.R) \
		--description="Some words of wisdom about this script.")
[ -n "$some_script" ] || exit - 1

next=$(SSREPI_add_application_to_pipeline $next $some_script)
[ -n "$next" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input_type $some_script final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

appendix_id=$(SSREPI_input_type $some_script appendix '^appendix.pdf$')
[ -n "$appendix_id" ] || exit -1


# Argument types
# --------------

arg_splits=$(SSREPI_argument \
        --id_argument=splits \
        --description="I think this might be split the data" \
        --application=$some_script \
	--name="--splits" \
        --type=flag \
        --arity=0)
[ -n "$arg_splits" ] || exit -1

arg_final_results=$(SSREPI_argument \
        --id_argument=final_results \
        --description="Results files with selected scenarios" \
        --application=$some_script \
	--container=$final_results_file
        --type=required \
        --order=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_y_axis=$(SSREPI_argument \
        --id_argument=y_axis \
        --description="y-axis label" \
        --application=$some_script \
        --type=required \
        --order=2 \
        --arity=1 \
        --range='.*')
[ -n "$arg_y_axis" ] || exit -1

arg_appendix=$(SSREPI_argument \
        --id_argument=appendix \
        --description="The diagram for inclusion in the appendix" \
        --application=$some_script \
        --type=required \
	--container=$appendix_id \
        --order=3 \
        --arity=1 \
        --range='^.*pdf$')
[ -n "$appendix" ] || exit -1

arg_scenarios=$(SSREPI_argument \
        --id_argument=scenarios \
        --description="The Scenarios to include in the diagram" \
        --application=$some_script \
        --type=required \
        --order=4 \
        --arity=+ \
	--argsep=' ' \
        --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$')
[ -n "$arg_scenario" ] || exit -1

(

some_process=$(SSREPI_process --executable=$some_script)
[ -n "$some_process" ] || exit -1

SSREPI_argument_input_file $some_script $some_process  $final_results_id $arg_final_results final_results.csv
SSREPI_argument_value $some_process $arg_y_axis Richness
SSREPI_argument_value $some_process $arg_splits 
SSREPI_argument_value $some_process $arg_scenarios " 
	A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 
	CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 
	CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1
	CO/V/30/5"

figure2-3small.R -splits final_results.csv \
	Richness \
	appendix.pdf \
	A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
	CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 \
	CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
	CO/V/30/5

SSREPI_argument_output_file $some_script $some_process $appendix_id \
	$arg_appendix appendix.pdf

SREPI_process \
        --process_id=$some_process \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null

)
[ $? -eq 0 ] || exit -1

SSREPI_process \
        --process_id=$THIS_PROCESS \
        --end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null
