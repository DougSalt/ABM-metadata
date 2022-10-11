#!/bin/bash

# This is the workflow script used tie all the results together in the post
# processing for this experiment.

# Author: Doug Salt

# Date: Jan 2017

# So if any script or part of the script returns non-zero then the script will
# fail
set -e
. lib/ssrepi.sh

ME=$(SSREPI_me)

SSREPI_contributor $ME doug_salt Author
SSREPI_contributor $ME doug_salt Developer

# Requirements for this script
# ============================

# Software

if SSREPI_require_minimum $ME perl  "5.0" $(perl -e 'print $];')
then
        (>&2 echo "$0: Minimum requirement for Perl failed")
        (>&2 echo "$0: Required at least Perl 5.0, got " \
		$(perl -e 'print $];'))
        exit -1
fi


if SSREPI_require_minimum $ME python "3.0" $(python --version 2>&1 | cut -f2 -d' ')
then
        (>&2 echo "$0: Minimum requirement for Python failed")
        (>&2 echo "$0: Required 3.0 got " \
		$(python --version 2>&1 | cut -f2 -d' '))
        exit -1
fi

if SSREPI_require_minimum $ME "R" "3.3.1" $(R --version | head -1 | awk '{print $3}')
then
        (>&2 echo "$0: Minimum requirement for R failed")
        (>&2 echo "$0: Required 3.3.1 got " \
		$(R --version | head -1 | awk '{print $3}'))
        exit -1
fi



if SSREPI_require_minimum $ME bash 3.0 $(bash --version | sed -n 1p | awk '{print $4}' | cut -f1 -d.)
then
        (>&2 echo "$0: Minimum requirement for bash failed")
        (>&2 echo "$0: Required 3.0 got " \
		$(bash --version | sed -n 1p | awk '{print $4}' | cut -f1 -d.))
        exit -1
fi

# Hardware

if SSREPI_require_exact $ME os Linux $(uname -s) && SSREPI_require_exact $ME os Darwin $(uname -s) 
then
        (>&2 echo "$0: Exact requirement for the OS failed")
	(>&2 echo "$0: Required Linux or  Darwin got "$(uname -s))
        exit -1
fi


# Hardware

if SSREPI_require_minimum $ME disk_space 20G $(disk_space)
then
        (>&2 echo "$0: Minimum requirement for disk space failed")
	(>&2 echo "$0: Required 20G of disk space got $(disk_space)G")
        exit -1
fi

if SSREPI_require_minimum $ME memory 4 $(memory)
then
        (>&2 echo "$0: Minimum requirement for memory failed")
	(>&2 echo "$0: Required 4G of memory got $(memory)G")
        exit -1
fi

if SSREPI_require_minimum $ME cpus $SSREPI_NOF_CPUS $(cpus)
then
        (>&2 echo "$0: Minimum requirement for number of cpus failed")
	(>&2 echo "$0: Required $SSREPI_NOF_CPUS cpus of memory got $(cpus)")
        exit -1
fi


# Methods
# =======

aic_id=$(SSREPI_statistical_method aic "The Akaike information criterion (AIC) 
	is a measure of the relative quality of statistical models for a 
	given set of data. Given a collection of models for the data, AIC 
	estimates the quality of each model, relative to each of the other 
	models. Hence, AIC provides a means for model selection.")

bic_id=$(SSREPI_statistical_method bi "Bayesian Information Criterion (BIC) 
	or Schwarz criterion (also SBC, SBIC) is a criterion for model 
	selection among a finite set of models; the model with the lowest 
	BIC is preferred.")

edf_id=$(SSREPI_statistical_method edf "Empirical Distribution Function is the
	distribution function associated with the empirical measure of a
	sample. This cumulative distribution function is a step function that
	jumps up by 1/n at each of the n data points. Its value at any 
	specified value of the measured variable is the fraction of 
	observations of the measured variable that are less than or equal to 
	the specified value.")

anova_gam_id=$(SSREPI_statistical_method anova.gam "Performs
	hypothesis tests relating to one or more fitted gam objects.")

recursive_partitioning_id=$(SSREPI_statistical_method recursive_partioning \
	"Recursive partitioning for classification,
	regression and survival trees.  An implementation of most of the
	functionality of the 1984 book by Breiman, Friedman, 
	Olshen and Stone."
)

sunflower_plot_id=$(SSREPI_visualisation_method sunflower_plot \
	"Looks like a sunflower drawn in a 2D space. The sunflower plots 
	are used as variants of scatter plots to display bivariate 
	distribution. When the density of data increases in a particular 
	region of a plot, it becomes hard to read.")

general_additive_model_id=$(SSREPI_visualisation_method general_additive_method \
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
	--statistical_method="$recursive_partitioning_id" \
)

# So a variable is in a container of some description and can act as an 
# input to VisualisationMethod, as opposed to a parameter, which is provided
# as an argument. Fair enough. 

# Variables
# =========

var_scenario_id=$(SSREPI_variable  \
	scenario  \
	"The combination of government, market, 
		break-even threshold and aspiration" \
	String \
)

# Statistical Variables
# =====================

# These are produced by a statiscal method only.


# Now run the all important scripts...

# analysege_gpLU2.pl
# ==================

ANALYSEGE_GPLU2=$(SSREPI_application analysege_gpLU2.pl \
	--purpose="
Analysis script to analyse results from SSS runs. The output is a CSV format
summary of the results from each run, listing the parameters first, then
the results: the number of bankruptcies, the amount of land use change,
the year of extinction of each species, and the abundance of each species.

Number of species at a given time step
Level of occupancy at each time step
Shannon index and evenness measure." \
)

# Arguments
# ---------

experiment=$(SSREPI_argument \
        $ANALYSEGE_GPLU2 \
        experiment \
        --description="The experimental run for this model. In the range 1-9." \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range="^[0-9]$")
[ -n "$experiment" ] || exit -1

# Input types
# -----------

SSS_report_id=$(SSREPI_input $ANALYSEGE_GPLU2 \
        SSS_report \
        "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].txt")
[ -n "$SSS_report_id" ] || exit -1

SSS_report_grd_id=$(SSREPI_input $ANALYSEGE_GPLU2 \
        SSS_report_grd \
        "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].grd")
[ -n "$SSS_report_grd_id" ] || exit -1

SSS_spomresult_extinct_id=$(SSREPI_input $ANALYSEGE_GPLU2 \
        SSS_spomresult_extinct \
        "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_extinct_id" ] || exit -1

SSS_spomresult_lspp_id=$(SSREPI_output $ME \
        SSS_spomresult_lspp \
        "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-lspp.csv")
[ -n "$SSS_spomresult_lspp_id" ] || exit -1

# Output types
# ------------

result_id=$(SSREPI_output $ANALYSEGE_GPLU2 result "^(batch1|batch2).csv$")
[ -n "$result_id" ] || exit -1


# Metadata
# --------

# Admittedly the next is not a statistical method, but I have used it as such
# to illustrate how these primitives might be employed.

analysege_gpLU2_id=$(SSREPI_statistical_method \
	"Post-run analysis script" \
	"The output is a CSV format
 summary of the results from each run, listing the parameters first, then
 the results: the number of bankruptcies, the amount of land use change,
 the year of extinction of each species, and the abundance of each species.

 Number of species at a given time step
 Level of occupancy at each time step
 Shannon index and evenness measure.")

svar_bankruptcies_id=$(SSREPI_statistical_variable \
	bankruptcies \
	"A column containing the number of bankruptcies." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_land_use_change_id=$(SSREPI_statistical_variable \
	land_use_change \
	"A column containing land use change." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu1_id=$(SSREPI_statistical_variable \
	occupancy_lu1 \
	"A column containing occupancy for landuse 1." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu2_id=$(SSREPI_statistical_variable \
	occupancy_lu2 \
	"A column containing occupancy for landuse 3." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu3_id=$(SSREPI_statistical_variable \
	occupancy_lu3 \
	"A column containing occupancy for landuse 3." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu4_id=$(SSREPI_statistical_variable \
	occupancy_lu4 \
	"A column containing occupancy for landuse 4." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu5_id=$(SSREPI_statistical_variable \
	occupancy_lu5 \
	"A column containing occupancy for landuse 5." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_lu6_id=$(SSREPI_statistical_variable \
	occupancy_lu6 \
	"A column containing occupancy for landuse 6." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_1_id=$(SSREPI_statistical_variable \
	extinction_spp_1 \
	"A column containing the number of extinctions for species 1 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)


svar_extinction_spp_2_id=$(SSREPI_statistical_variable \
	extinction_spp_2 \
	"A column containing the number of extinctions for species 2 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_3_id=$(SSREPI_statistical_variable \
	extinction_spp_3 \
	"A column containing the number of extinctions for species 3 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_4_id=$(SSREPI_statistical_variable \
	extinction_spp_4 \
	"A column containing the number of extinctions for species 4 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_5_id=$(SSREPI_statistical_variable \
	extinction_spp_5 \
	"A column containing the number of extinctions for species 5 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_6_id=$(SSREPI_statistical_variable \
	extinction_spp_6 \
	"A column containing the number of extinctions for species 6 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_7_id=$(SSREPI_statistical_variable \
	extinction_spp_7 \
	"A column containing the number of extinctions for species 7 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_8_id=$(SSREPI_statistical_variable \
	extinction_spp_8 \
	"A column containing the number of extinctions for species 8 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_9_id=$(SSREPI_statistical_variable \
	extinction_spp_9 \
	"A column containing the number of extinctions for species 9 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_extinction_spp_10_id=$(SSREPI_statistical_variable \
	extinction_spp_10 \
	"A column containing the number of extinctions for species 10 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)


svar_occupancy_spp_1_id=$(SSREPI_statistical_variable \
	occupancy_spp_1 \
	"A column containing the occupancy for species 1 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_2_id=$(SSREPI_statistical_variable \
	occupancy_spp_2 \
	"A column containing the occupancy for species 2 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_3_id=$(SSREPI_statistical_variable \
	occupancy_spp_3 \
	"A column containing the occupancy for species 3 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_4_id=$(SSREPI_statistical_variable \
	occupancy_spp_4 \
	"A column containing the occupancy for species 4 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_5_id=$(SSREPI_statistical_variable \
	occupancy_spp_5 \
	"A column containing the occupancy for species 5 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_6_id=$(SSREPI_statistical_variable \
	occupancy_spp_6 \
	"A column containing the occupancy for species 6 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_7_id=$(SSREPI_statistical_variable \
	occupancy_spp_7 \
	"A column containing the occupancy for species 7 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_8_id=$(SSREPI_statistical_variable \
	occupancy_spp_8 \
	"A column containing the occupancy for species 8 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_9_id=$(SSREPI_statistical_variable \
	occupancy_spp_9 \
	"A column containing the occupancy for species 9 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_occupancy_spp_10_id=$(SSREPI_statistical_variable \
	occupancy_spp_10 \
	"A column containing the occupancy for species 10 per patch." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_Shannon_id=$(SSREPI_statistical_variable \
	Shannon \
	"A column containing the Shannon number." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_Equitability_id=$(SSREPI_statistical_variable \
	Equitability \
	"A column containing the equitabilty." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

svar_richness_id=$(SSREPI_statistical_variable \
	richness \
	"A column containing the number of bankruptcies." \
	"\mathbb{R}" \
	"$analysege_gpLU2_id" \
)

##for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
#for run in 001
#do
##  for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
#  for govt in ClusterActivity 
#  do
#    for sink in nosink
#    do
##      for market in flat var2
#      for market in flat
#      do
##        for bet in 25.0 30.0
#        for bet in 25.0 
#        do
##          for asp in 1.0 5.0
#          for asp in 1.0
#          do
##            for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
#            for rwd in 1.0
#            do
##              for rat in 1.0 2.0 10.0
#              for rat in 1.0
#              do
#
#		DIR="Cluster2/SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
#		IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.txt"
#		IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.grd"
#		IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-extinct.csv"
#		IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-lspp.csv"
#
#		ARGS="""
#		--SSREPI-argument-$experiment=8
#		"""
#
#		ARGS="""$ARGS
#		--SSREPI-input-${SSS_report_id}=$DIR/$IN_1
#		--SSREPI-input-${SSS_report_grd_id}=$DIR/$IN_2
#		--SSREPI-input-${SSS_spomresult_extinct_id}=$DIR/$IN_3
#		--SSREPI-input-${SSS_spomresult_lspp_id}=$DIR/$IN_4
#		"""
#
#		ARGS="""$ARGS
#		--SSREPI-extend-stdout-${result_id}=batch1.csv
#		"""
#		SSREPI_call $ANALYSEGE_GPLU2 $ARGS
#              done
#            done
#          done
#        done
#      done
#    done
#  done
#done
#
#statiscs_set_1=$(SSREPI_statistics statistics.$(uniq)\
#	"$analysege_gpLU2_id" \
#	"analysege_gpLU2.pl 8") 
#
#
##for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
#for run in 001
#do
##  for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
#  for govt in ClusterActivity 
#  do
#    for sink in nosink
#    do
#
##      for market in flat var2
#      for market in flat
#      do
##        for bet in 25.0 30.0
#        for bet in 25.0 
#        do
##          for asp in 1.0 5.0
#          for asp in 1.0
#          do
##            for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
#            for rwd in 1.0
#            do
##              for rat in 1.0 2.0 10.0
#              for rat in 1.0
#              do
#
#		DIR="SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
#		IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.txt"
#		IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.grd"
#		IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-extinct.csv"
#		IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-lspp.csv"
#
#		ARGS="""
#		--SSREPI-argument-$experiment=9
#		"""
#
#		ARGS="""$ARGS
#		--SSREPI-input-${SSS_report_id}=$IN_1
#		--SSREPI-input-${SSS_report_grd_id}=$IN_2
#		--SSREPI-input-${SSS_spomresult_extinct_id}=$IN_3
#		--SSREPI-input-${SSS_spomresult_lspp_id}=$IN_4
#		"""
#
#		ARGS="""$ARGS
#		--SSREPI-extend-stdout-${result_id}=batch2.csv
#		"""
#		SSREPI_call $ANALYSEGE_GPLU2 --cwd=$DIR $ARGS
#              done
#            done
#          done
#        done
#      done
#    done
#  done
#done
#
#statiscs_set_1=$(SSREPI_statistics statistics.$(uniq)\
#	"$analysege_gpLU2_id" \
#	"analysege_gpLU2.pl 9") 


# Merge
# =====

tail -n +2 batch1.csv > all_results.csv
tail -n +3 batch2.csv >> all_results.csv

# postprocessing.R
# ================

POSTPROCESSING=$(SSREPI_application postprocessing.R \
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

	4. Removes high expenditure." \
)
[ -n "$POSTPROCESSING" ] || exit - 1


# Input types
# -----------

# Input and output types have to be created first as the arguments to
# a function can access an output/input type. In this case the results
# files have already been defined above.

all_results_id=$(SSREPI_input  $POSTPROCESSING all_results '^all_results.csv$')
[ -n "$all_results_id" ] || exit -1

scenarios_id=$(SSREPI_input $POSTPROCESSING scenarios '^cfg/scenarios.cfg$')
[ -n "$scenarios_id" ] || exit -1

# Output types
# ------------

final_results_id=$(SSREPI_output $POSTPROCESSING final_results ^final_results.csv$)
[ -n "$final_results_id" ] || exit -1

# Arguments
# ---------

arg_all_results=$(SSREPI_argument \
        $POSTPROCESSING \
        arg_result \
        --description="All the results from all the runs" \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_all_results" ] || exit -1


arg_scenarios=$(SSREPI_argument \
        $POSTPROCESSING \
        scenarios \
        --description="The scenarios that are required for processing" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_scenarios" ] || exit -1

arg_final_results=$(SSREPI_argument \
        $POSTPROCESSING \
        experiment \
        --description="The actual results from which diagrams will be created." \
        --type=required \
        --order_value=3 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

ARGS="""
--SSREPI-input-${all_results_id}=all_results.csv
--SSREPI-input-${scenarios_id}=cfg/scenarios.cfg
"""

ARGS="""$ARGS
--SSREPI-argument-${arg_all_results}=all_results.csv
--SSREPI-argument-${arg_scenarios}=cfg/scenarios.cfg
--SSREPI-argument-${arg_final_results}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-output-${final_results_id}=final_results.csv
"""

SSREPI_call $POSTPROCESSING $ARGS

# ============
# # Diagrams #
# ============

# Figure 3
# ========

PROG=$(SSREPI_application figure2-3part.R \
		--description="""
		This needs filling in.
		Figure 2 - part 3 for the paper.
""")
[ -n "$PROG" ] || exit -1

# Input types
# -----------

final_results_id=$(SSREPI_input $PROG final_results \
	'^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

figure3_cfg_id=$(SSREPI_input $PROG figure3_cfg \
	'^cfg\/figure3\.cfg$')
[ -n "$figure3_cfg_id" ] || exit -1

# Output types
# ------------

figure3_id=$(SSREPI_input $PROG figure3 '^figure3.pdf$')
[ -n "$figure3_id" ] || exit -1

# Argument types
# --------------

arg_final_results=$(SSREPI_argument \
        $PROG \
        final_results \
        --description="Results files with selected scenarios" \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_figure3_cfg=$(SSREPI_argument \
        $PROG \
        figure3_cfg \
        --description="Configuration to pick correct scenarios for figure 3" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure3_cfg" ] || exit -1

arg_figure3=$(SSREPI_argument \
        $PROG \
        figure3 \
        --description="Figure 3 pdf" \
        --type=required \
        --order_value=3 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure3" ] || exit -1

# Metadata
# --------

visualisation_method_figure3_id=$(SSREPI_visualisation_method \
	"figure 3" \
	"A sunflower plot with curve fitting, plotting incentive (x-axis)
	against landscape scale species richness (y-axis)")

SSREPI_implements $PROG \
	--visualisation_method="$visualisation_method_figure3_id"

SSREPI_implements $PROG \
	--visualisation_method="$sunflower_plot_id"
SSREPI_implements $PROG \
	--statistical_method="$recursive_partitioning_id"
SSREPI_implements $PROG \
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

ARGS="""
--SSREPI-argument-${arg_final_results}=final_results.csv
--SSREPI-argument-${arg_figure3_cfg}=cfg/figure3.cfg
--SSREPI-argument-${arg_figure3}=figure3.pdf
"""

ARGS="""$ARGS
--SSREPI-input-${final_results_id}=final_results.csv
--SSREPI-input-${figure3_cfg_id}=cfg/figure3.cfg
"""

ARGS="""$ARGS
--SSREPI-output-${figure3_id}=figure3.pdf
"""

(>&2 echo SSREPI_call $PROG $ARGS)
SSREPI_call $PROG $ARGS

some_visualisation=$(SSREPI_visualisation \
	visualisation.$(uniq) \
	$sunflower_plot_id \
	"figure2-3part.R final_results.csv cfg/figure3.cfg figure3.pdf" \
	figure3.pdf)

# Need to add more specifics to these. That is there are more fields for the
# value record

SSREPI_value \
	"A/F/30/1" \
	$var_scenario_id \
	figure3.pdf
SSREPI_value \
	2 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	10 \
	$var_max_incentive_id \
	figure3.pdf 
SSREPI_value \
	"A/V/30/1" \
	$var_scenario_id \
	figure3.pdf 
SSREPI_value \
	2 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	15 \
	$var_max_incentive_id \
	figure3.pdf 
SSREPI_value "CA/F/25/5" \
	$var_scenario_id \
	figure3.pdf 
SSREPI_value \
	1 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	10 $var_max_incentive_id figure3.pdf 
SSREPI_value \
	"O/F/30/5" \
	$var_scenario_id \
	figure3.pdf 
SSREPI_value \
	1 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	8 \
	$var_max_incentive_id \
	figure3.pdf 
SSREPI_value \
	"O/V/25/1" \
	$var_scenario_id \
	figure3.pdf 
SSREPI_value \
	1 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	5 \
	$var_max_incentive_id \
	figure3.pdf 
SSREPI_value \
	"CO/V/25/5" \
	$var_scenario_id \
	figure3.pdf 
SSREPI_value \
	0.1 \
	$var_min_incentive_id \
	figure3.pdf 
SSREPI_value \
	0.8 \
	$var_max_incentive_id \
	figure3.pdf 
	
# table 4 for presentation
# ========================

NONLINEARR=$(SSREPI_application nonlinearK4bsI.R \
		--description="This needs supplying")
[ -n "$NONLINEARR" ] || exit - 1

# Input types
# -----------

final_results_id=$(SSREPI_input $NONLINEARR final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

table4_id=$(SSREPI_output $NONLINEARR table4 '^table4.csv$')
[ -n "$table4_id" ] || exit -1

# Argument types
# --------------

arg_final_results=$(SSREPI_argument \
        $NONLINEARR \
        final_results \
        --description="Results files with selected scenarios" \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_table4=$(SSREPI_argument \
        $NONLINEARR \
        table4 \
        --description="Results for table 4 in the paper" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

# Metadata
# --------

SSREPI_implements $NONLINEARR \
	--statistical_method="$aic_id"
SSREPI_implements $NONLINEARR \
	--statistical_method="$bic_id"
SSREPI_implements $NONLINEARR \
	--statistical_method="$edf_id"
SSREPI_implements $NONLINEARR \
	--statistical_method="$anova_gam_id"

ARGS="""
--SSREPI-input-${final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-argument-${arg_final_results}=final_results.csv
--SSREPI-argument-${arg_table4}=table4.csv
"""

ARGS="""$ARGS
--SSREPI-output-${table4_id}=table4.csv
"""

SSREPI_call $NONLINEARR $ARGS

SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $aic_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $bic_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $edf_id 
SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $anova_gam_id 

# table 4 paper CSV
# =================

TABLE4=$(SSREPI_application table4.R \
		--description="""
		A small script to prodce a text version of the table found in
		Polhil et al (2013) - Nonlinearities in biodiversity incentive
		schemes: A study using an integrated agent-based and
		metacommunity model The original diagram was done with a
		mixture of R and Excel. I have automated this part.
""")

[ -n "$TABLE4" ] || exit - 1

# Input types
# -----------

table4_id=$(SSREPI_input $TABLE4 table4 '^table4.csv$')

# Output types
# ------------

table4_paper_id=$(SSREPI_input $TABLE4 table4_paper '^table4.paper.csv$')

# Argument types
# --------------

arg_table4=$(SSREPI_argument \
        $TABLE4 \
        table4 \
        --description="Unprocessed table 4" \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

arg_table4_paper=$(SSREPI_argument \
        $TABLE4 \
        table4_paper \
        --description="Results for table 4 in the paper" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_table4" ] || exit -1

ARGS="""
--SSREPI-argument-${arg_table4}=table4.csv
--SSREPI-argument-${arg_table4_paper}=table4.paper.csv
"""

ARGS="""$ARGS
--SSREPI-input-${table4_id}=table4.csv
"""

ARGS="""$ARGS
--SSREPI-output-${table4_paper_id}=table4.paper.csv
"""

SSREPI_call $TABLE4 $ARGS

# figure 4
# ========

FIGURE2_3S=$(SSREPI_application figure2-3s.R \
		--description="""
		Need some stuff here.
		Produces a sunflow plot for the paper
""")

[ -n "$FIGURE2_3S" ] || exit - 1

# Input types
# -----------

final_results_id=$(SSREPI_input $FIGURE2_3S final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

figure4_id=$(SSREPI_output $FIGURE2_3S figure4 '^figure4.*\.pdf$')
[ -n "$figure4_id" ] || exit -1

# Argument types
# --------------

arg_splits=$(SSREPI_argument \
        $FIGURE2_3S \
        splits \
        --description="I think this might be split the data" \
	--name="splits" \
        --type=flag \
)
[ -n "$arg_splits" ] || exit -1

arg_final_results=$(SSREPI_argument \
        $FIGURE2_3S \
        final_results \
        --description="Result files with selected scenarios" \
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref \
)
[ -n "$arg_final_results" ] || exit -1

arg_main_scenario=$(SSREPI_argument \
        $FIGURE2_3S \
        main_scenario \
        --description="Main scenario" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range='^.*$')
[ -n "$arg_main_scenario" ] || exit -1

arg_small_scenarios=$(SSREPI_argument \
        $FIGURE2_3S \
        small_scenarios \
        --description="Small scenarios" \
        --type=required \
        --order_value=3 \
        --arity=5 \
	--argsep='space' \
        --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$')
[ -n "$arg_small_scenarios" ] || exit -1

arg_figure4=$(SSREPI_argument \
        $FIGURE2_3S \
        figure5 \
        --description="PDF for figure 4" \
        --type=required \
        --order_value=4 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_figure4" ] || exit -1

# Metadata
# --------

SSREPI_implements $FIGURE2_3S --visualisation_method=$sunflower_plot_id

con_figure4_sunflower_plot_id=$(SSREPI_content \
	--visualisation_method=$sunflower_plot_id \
	--container_type=$figure4_id \
)

con_varscenario_id=$(SSREPI_content \
	--variable=$var_scenario_id \
	--container_type=$figure4_id \
	--locator='grep -v ^scenario | cut -f1 -3,' \
)

ARGS="""
--SSREPI-argument-${arg_splits} 
--SSREPI-argument-${arg_final_results}=final_results.csv
--SSREPI-argument-${arg_main_scenario}=Richness
--SSREPI-argument-${arg_small_scenarios}=O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5
--SSREPI-argument-${arg_figure4}=figure4.a_and_b.pdf
"""

ARGS="""$ARGS
--SSREPI-input=${final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-output=${figure4_id}=figure4.a_and_b.pdf
"""
SSREPI_call $FIGURE2_3S $ARGS

#figure2-3s.R 
# 	--splits \
#       final_results.csv \
#       Richness \
#       O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5
#	figure4.a_and_b.pdf

some_visualisation=$(SSREPI_visualisation \
	visualisation.$(uniq) \
	$sunflower_plot_id \
	"figure2-3s.R -splits final_results.csv Richness \
	A/F/25/5 A/F/25/1 A/F/30/5 O/F/25/5 CA/F/25/5 figure4.a_and_b.pdf" \
	figure4.a_and_b.pdf \
)

# figure 5
# ========

xit -2
# Appendix 
# ========

FIGURE2_3SMALL=$(SSREPI_application figure2-3small.R \
	--description="""
		This produces the diagram for the appendix of the paper.
		Some words of wisdom about this script."
)
[ -n "$FIGURE2_3SMALL" ] || exit - 1

# Input types
# -----------

final_results_id=$(SSREPI_input $FIGURE2_3SMALL final_results '^final_results.csv$')
[ -n "$final_results_id" ] || exit -1

# Output types
# ------------

appendix_id=$(SSREPI_input $FIGURE2_3SMALL appendix '^appendix.pdf$')
[ -n "$appendix_id" ] || exit -1

# Argument types
# --------------

arg_splits=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        splits \
        --description="I think this might be split the data" \
	--name="splits" \
        --type=flag \
        --arity=0)
[ -n "$arg_splits" ] || exit -1

arg_final_results=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        final_results \
        --description="Results file with selected scenarios" \
	--container=$final_results_file
        --type=required \
        --order_value=1 \
        --arity=1 \
        --range=relative_ref)
[ -n "$arg_final_results" ] || exit -1

arg_response_variable=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        response_variable \
        --description="Response variable" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range=".*")
[ -n "$arg_response_variable" ] || exit -1

arg_y_axis=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        y_axis \
        --description="y-axis label" \
        --type=required \
        --order_value=2 \
        --arity=1 \
        --range='.*')
[ -n "$arg_y_axis" ] || exit -1

arg_appendix=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        appendix \
        --description="The diagram for inclusion in the appendix" \
        --type=required \
	--container=$appendix_id \
        --order_value=3 \
        --arity=1 \
        --range='^.*pdf$')
[ -n "$appendix" ] || exit -1

arg_scenarios=$(SSREPI_argument \
        $FIGURE2_3SMALL \
        scenarios \
        --description="The Scenarios to include in the diagram" \
        --type=required \
        --order_value=4 \
        --arity=+ \
	--argsep=' ' \
        --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$'
)
[ -n "$arg_scenario" ] || exit -1

ARGS="""
--SSREPI-input-${final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-argument=${arg_splits}
--SSREPI-argument=${arg_final_results}=final_results.csv
--SSREPI-argument=${arg_response_variable}=Richness
--SSREPI-argument=${arg_appendix}=appendix.pdf
--SSREPI-argument=${arg_scenarios}=\
	A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
	CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 \ 
	CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
	CO/V/30/5
"""

ARGS="""$ARGS
--SSREPI-output=${appendix_id}=appendix.pdf
"""

SSREPI_call $FIGURE2_3SMALL $ARGS

#figure2-3small.R -splits final_results.csv \
#	Richness \
#	appendix.pdf \
#	A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
#	CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 \
#	CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
#	CO/V/30/5


