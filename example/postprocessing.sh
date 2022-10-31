#!/usr/bin/env bash

# This is the workflow script used tie all the results together in the post
# processing for this experiment.

# Author: Doug Salt

# Date: Jan 2017

# So if any script or part of the script returns non-zero then the script will
# fail
# set -e

. lib/ssrepi_cli.sh

# c_ for container
# a_ for argument
# o_ for an output
# i_ for an input
# A_ for an application

# I have not done this in the other scripts, but I recommend in the case of
# complicated script some kind of convention is adopted purely for your own
# sanity.

# I find the metadata very, very confusing, so to mitigate this I have adopted
# the following conventions for prefices:

# sm_ is a statistical method
# vm_ is a visualisation method
# sos_ is a set of statistics
# var_ is a variable
# con_ is content (????)
# vis_ is a visualisation
# sv_ is a statistical_variable
# par_ is a parameter

# Seemingly the difference between a parameter is that it is fixed.
# and a parameter may change

# sv_ is used by a sm_

# vis_ has a vm_ and points to the visualisation container, a_
# con_ can have a  vm_, sm_, 
# An a_ can implement a vm_ or sm_

# Remembering the setting values does not return anything and can set an

# sv_
# sp_
# vp_


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

if SSREPI_require_minimum $ME cpus $REQUIRED_NOF_CPUS $(cpus)
then
    (>&2 echo "$0: Minimum requirement for number of cpus failed")
    (>&2 echo "$0: Required $REQUIRED_NOF_CPUS cpus of memory got $(cpus)")
    exit -1
fi


# Methods
# =======

sm_aic_id=$(SSREPI_statistical_method aic "The Akaike information criterion (AIC) 
    is a measure of the relative quality of statistical models for a 
    given set of data. Given a collection of models for the data, AIC 
    estimates the quality of each model, relative to each of the other 
    models. Hence, AIC provides a means for model selection.")

sm_bic_id=$(SSREPI_statistical_method bi "Bayesian Information Criterion (BIC) 
    or Schwarz criterion (also SBC, SBIC) is a criterion for model 
    selection among a finite set of models; the model with the lowest 
    BIC is preferred.")

sm_edf_id=$(SSREPI_statistical_method edf "Empirical Distribution Function is the
    distribution function associated with the empirical measure of a
    sample. This cumulative distribution function is a step function that
    jumps up by 1/n at each of the n data points. Its value at any 
    specified value of the measured variable is the fraction of 
    observations of the measured variable that are less than or equal to 
    the specified value.")

sm_anova_gam_id=$(SSREPI_statistical_method anova.gam "Performs
    hypothesis tests relating to one or more fitted gam objects.")

sm_recursive_partitioning_id=$(SSREPI_statistical_method recursive_partioning \
    "Recursive partitioning for classification,
    regression and survival trees.  An implementation of most of the
    functionality of the 1984 book by Breiman, Friedman, 
    Olshen and Stone."
)

vm_sunflower_plot_id=$(SSREPI_visualisation_method sunflower_plot \
    "Looks like a sunflower drawn in a 2D space. The sunflower plots 
    are used as variants of scatter plots to display bivariate 
    distribution. When the density of data increases in a particular 
    region of a plot, it becomes hard to read.")

vm_general_additive_model_id=$(SSREPI_visualisation_method general_additive_method \
    "A generalized additive model (GAM) is a generalized linear model 
    in which the linear predictor depends linearly on unknown smooth 
    functions of some predictor variables, and interest focuses on 
    inference about these smooth functions.
    
    Note Bene: this is not a visualisation method, but I just wanted
    some more examples of visualisation methods.")

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
    --statistical_method="$sm_recursive_partitioning_id" \
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

A_ANALYSEGE_GPLU2=$(SSREPI_application analysege_gpLU2.pl \
    --purpose="
Analysis script to # results from SSS runs. The output is a CSV format
summary of the results from each run, listing the parameters first, then
the results: the number of bankruptcies, the amount of land use change,
the year of extinction of each species, and the abundance of each species.

Number of species at a given time step
Level of occupancy at each time step
Shannon index and evenness measure." \
)

# Arguments
# ---------

a_experiment=$(SSREPI_argument \
    $A_ANALYSEGE_GPLU2 \
    experiment \
    --description="The experimental run for this model. In the range 1-9." \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range="^[0-9]$")
[ -n "$a_experiment" ] || exit -1

# Input types
# -----------

i_SSS_report_id=$(SSREPI_input $A_ANALYSEGE_GPLU2 \
    SSS_report \
    "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].txt")
[ -n "$i_SSS_report_id" ] || exit -1

i_SSS_report_grd_id=$(SSREPI_input $A_ANALYSEGE_GPLU2 \
    SSS_report_grd \
    "SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].grd")
[ -n "$i_SSS_report_grd_id" ] || exit -1

i_SSS_spomresult_extinct_id=$(SSREPI_input $A_ANALYSEGE_GPLU2 \
    SSS_spomresult_extinct \
    "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$i_SSS_spomresult_extinct_id" ] || exit -1

i_SSS_spomresult_lspp_id=$(SSREPI_input $A_ANALYSEGE_GPLU2 \
    SSS_spomresult_lspp \
    "SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-lspp.csv")
[ -n "$i_SSS_spomresult_lspp_id" ] || exit -1

# Output types
# ------------

o_result_id=$(SSREPI_output $A_ANALYSEGE_GPLU2 result "^(batch1|batch2).csv$")
[ -n "$o_result_id" ] || exit -1


for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
do
    for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
    do
        for sink in nosink
        do
            for market in flat var2
            do
                for bet in 25.0 30.0
                do
                    for asp in 1.0 5.0
                    do
                        for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
                        do
                            for rat in 1.0 2.0 10.0
                            do

                                DIR="Cluster2/SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
                                IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.txt"
                                IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.grd"
                                IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-extinct.csv"
                                IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-lspp.csv"

                                ARGS="""
                                --SSREPI-argument-$a_experiment=8
                                """

                                ARGS="""$ARGS
                                --SSREPI-input-${i_SSS_report_id}=$DIR/$IN_1
                                --SSREPI-input-${i_SSS_report_grd_id}=$DIR/$IN_2
                                --SSREPI-input-${i_SSS_spomresult_extinct_id}=$DIR/$IN_3
                                --SSREPI-input-${i_SSS_spomresult_lspp_id}=$DIR/$IN_4
                                """

                                ARGS="""$ARGS
                                --SSREPI-extend-stdout-${o_result_id}=batch1.csv
                                """
                                set -xv
                                SSREPI_run $A_ANALYSEGE_GPLU2 $ARGS

                                if [ -z "$test" ]
                                then
                                    break
                                fi

                            done
                        done
                    done
                done
            done
        done
    done
done

#    for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
#    do
#        for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
#        do
#            for sink in nosink
#            do
#                for market in flat var2
#                do
#                    for bet in 25.0 30.0
#                    do
#                        for asp in 1.0 5.0
#                        do
#                            for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
#                            do
#                                for rat in 1.0 2.0 10.0
#                                do
#
#                                    DIR="Cluster2/SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
#                                    IN_1="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.txt"
#                                    IN_2="SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.grd"
#                                    IN_3="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-extinct.csv"
#                                    IN_4="SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-lspp.csv"
#
#                                    ARGS="""
#                                    --SSREPI-argument-$a_experiment=9
#                                    """
#
#                                    ARGS="""$ARGS
#                                    --SSREPI-input-${i_SSS_report_id}=$DIR/$IN_1
#                                    --SSREPI-input-${i_SSS_report_grd_id}=$DIR/$IN_2
#                                    --SSREPI-input-${i_SSS_spomresult_extinct_id}=$DIR/$IN_3
#                                    --SSREPI-input-${i_SSS_spomresult_lspp_id}=$DIR/$IN_4
#                                    """
#
#                                    ARGS="""$ARGS
#                                    --SSREPI-extend-stdout-${o_result_id}=batch2.csv
#                                    """
#                                    SSREPI_run $A_ANALYSEGE_GPLU2 $ARGS
#                                    if [ -z "$test" ]
#                                    then
#                                        break
#                                    fi
#                                done
#                            done
#                        done
#                    done
#                done
#            done
#        done
#    done
fi
echo "FUCK"
exit -6
# Metadata
# --------

# Metadata should normally follow the run. Although not strictly necessary, if
# you are referring to files which contain statistical and visualisation
# information then it is generally better to have produced them if they are
# referred to. If you wish to put the metadata before the stuff that produces
# it, then be aware the code assumes things are there if they are referred to
# and _will_ check for their existence.

# Admittedly the next is not a statistical method, but I have used it as such
# to illustrate how these primitives might be employed.

sm_analysege_gpLU2_id=$(SSREPI_statistical_method \
    "Post-run-analysis-script" \
    "The output is a CSV format
 summary of the results from each run, listing the parameters first, then
 the results: the number of bankruptcies, the amount of land use change,
 the year of extinction of each species, and the abundance of each species.

 Number of species at a given time step
 Level of occupancy at each time step
 Shannon index and evenness measure.")

sos_statistics_set_1=$(SSREPI_statistics statistics.$(uniq)\
    $sm_analysege_gpLU2_id \
    "analysege_gpLU2.pl 8") 

sos_statistics_set_2=$(SSREPI_statistics statistics.$(uniq)\
    $sm_analysege_gpLU2_id \
    "analysege_gpLU2.pl 9") 

sv_bankruptcies_id=$(SSREPI_statistical_variable \
    bankruptcies \
    "A column containing the number of bankruptcies." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_land_use_change_id=$(SSREPI_statistical_variable \
    land_use_change \
    "A column containing land use change." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu1_id=$(SSREPI_statistical_variable \
    occupancy_lu1 \
    "A column containing occupancy for landuse 1." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu2_id=$(SSREPI_statistical_variable \
    occupancy_lu2 \
    "A column containing occupancy for landuse 3." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu3_id=$(SSREPI_statistical_variable \
    occupancy_lu3 \
    "A column containing occupancy for landuse 3." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu4_id=$(SSREPI_statistical_variable \
    occupancy_lu4 \
    "A column containing occupancy for landuse 4." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu5_id=$(SSREPI_statistical_variable \
    occupancy_lu5 \
    "A column containing occupancy for landuse 5." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_lu6_id=$(SSREPI_statistical_variable \
    occupancy_lu6 \
    "A column containing occupancy for landuse 6." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_1_id=$(SSREPI_statistical_variable \
    extinction_spp_1 \
    "A column containing the number of extinctions for species 1 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_2_id=$(SSREPI_statistical_variable \
    extinction_spp_2 \
    "A column containing the number of extinctions for species 2 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_3_id=$(SSREPI_statistical_variable \
    extinction_spp_3 \
    "A column containing the number of extinctions for species 3 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_4_id=$(SSREPI_statistical_variable \
    extinction_spp_4 \
    "A column containing the number of extinctions for species 4 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_5_id=$(SSREPI_statistical_variable \
    extinction_spp_5 \
    "A column containing the number of extinctions for species 5 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_6_id=$(SSREPI_statistical_variable \
    extinction_spp_6 \
    "A column containing the number of extinctions for species 6 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_7_id=$(SSREPI_statistical_variable \
    extinction_spp_7 \
    "A column containing the number of extinctions for species 7 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_8_id=$(SSREPI_statistical_variable \
    extinction_spp_8 \
    "A column containing the number of extinctions for species 8 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_9_id=$(SSREPI_statistical_variable \
    extinction_spp_9 \
    "A column containing the number of extinctions for species 9 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_extinction_spp_10_id=$(SSREPI_statistical_variable \
    extinction_spp_10 \
    "A column containing the number of extinctions for species 10 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_1_id=$(SSREPI_statistical_variable \
    occupancy_spp_1 \
    "A column containing the occupancy for species 1 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_2_id=$(SSREPI_statistical_variable \
    occupancy_spp_2 \
    "A column containing the occupancy for species 2 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_3_id=$(SSREPI_statistical_variable \
    occupancy_spp_3 \
    "A column containing the occupancy for species 3 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_4_id=$(SSREPI_statistical_variable \
    occupancy_spp_4 \
    "A column containing the occupancy for species 4 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_5_id=$(SSREPI_statistical_variable \
    occupancy_spp_5 \
    "A column containing the occupancy for species 5 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_6_id=$(SSREPI_statistical_variable \
    occupancy_spp_6 \
    "A column containing the occupancy for species 6 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_7_id=$(SSREPI_statistical_variable \
    occupancy_spp_7 \
    "A column containing the occupancy for species 7 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_8_id=$(SSREPI_statistical_variable \
    occupancy_spp_8 \
    "A column containing the occupancy for species 8 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_9_id=$(SSREPI_statistical_variable \
    occupancy_spp_9 \
    "A column containing the occupancy for species 9 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_occupancy_spp_10_id=$(SSREPI_statistical_variable \
    occupancy_spp_10 \
    "A column containing the occupancy for species 10 per patch." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_Shannon_id=$(SSREPI_statistical_variable \
    Shannon \
    "A column containing the Shannon number." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_Equitability_id=$(SSREPI_statistical_variable \
    Equitability \
    "A column containing the equitabilty." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

sv_richness_id=$(SSREPI_statistical_variable \
    richness \
    "A column containing the number of bankruptcies." \
    "\mathbb{R}" \
    "$sm_analysege_gpLU2_id" \
)

# Merge
# =====

tail -n +2 batch1.csv > all_results.csv
tail -n +3 batch2.csv >> all_results.csv

# postprocessing.R
# ================

A_POSTPROCESSING=$(SSREPI_application postprocessing.R \
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
[ -n "$A_POSTPROCESSING" ] || exit - 1


# Input types
# -----------

# Input and output types have to be created first as the arguments to
# a function can access an output/input type. In this case the results
# files have already been defined above.

i_all_results_id=$(SSREPI_input  $A_POSTPROCESSING all_results '^all_results.csv$')
[ -n "$i_all_results_id" ] || exit -1

i_scenarios_id=$(SSREPI_input $A_POSTPROCESSING scenarios '^cfg/scenarios.cfg$')
[ -n "$i_scenarios_id" ] || exit -1

# Output types
# ------------

o_final_results_id=$(SSREPI_output $A_POSTPROCESSING final_results ^final_results.csv$)
[ -n "$o_final_results_id" ] || exit -1

# Arguments
# ---------

a_all_results=$(SSREPI_argument \
    $A_POSTPROCESSING \
    a_result \
    --description="All the results from all the runs" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_all_results" ] || exit -1


a_scenarios=$(SSREPI_argument \
    $A_POSTPROCESSING \
    scenarios \
    --description="The scenarios that are required for processing" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_scenarios" ] || exit -1

a_final_results=$(SSREPI_argument \
    $A_POSTPROCESSING \
    experiment \
    --description="The actual results from which diagrams will be created." \
    --type=required \
    --order_value=3 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_final_results" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-input-${i_all_results_id}=all_results.csv
--SSREPI-input-${i_scenarios_id}=cfg/scenarios.cfg
"""

ARGS="""$ARGS
--SSREPI-argument-${a_all_results}=all_results.csv
--SSREPI-argument-${a_scenarios}=cfg/scenarios.cfg
--SSREPI-argument-${a_final_results}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-output-${o_final_results_id}=final_results.csv
"""

SSREPI_run $A_POSTPROCESSING $ARGS

# ============
# # Diagrams #
# ============

# Figure 3
# ========

A_FIGURE2_3PART=$(SSREPI_application figure2-3part.R \
    --description="""
    Produces 6 graphs for figure 3 for the paper.  The
    configurations to select this graphs are kept in a
    configuration file, unlike other code this does not take these
    scenarios from the commmand line
""")
[ -n "$A_FIGURE2_3PART" ] || exit -1

# Input types
# -----------

i_final_results_id=$(SSREPI_input $A_FIGURE2_3PART final_results \
    '^final_results.csv$')
[ -n "$i_final_results_id" ] || exit -1

i_figure3_cfg_id=$(SSREPI_input $A_FIGURE2_3PART figure3_cfg \
    '^cfg\/figure3\.cfg$')
[ -n "$i_figure3_cfg_id" ] || exit -1

# Output types
# ------------

o_figure3_id=$(SSREPI_input $A_FIGURE2_3PART figure3 '^figure3.pdf$')
[ -n "$o_figure3_id" ] || exit -1

# Argument types
# --------------

a_final_results=$(SSREPI_argument \
    $A_FIGURE2_3PART \
    final_results \
    --description="Results files with all scenarios" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_final_results" ] || exit -1

a_figure3_cfg=$(SSREPI_argument \
    $A_FIGURE2_3PART \
    figure3_cfg \
    --description="Configuration to pick correct scenarios for figure 3" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_figure3_cfg" ] || exit -1

a_figure3=$(SSREPI_argument \
    $A_FIGURE2_3PART \
    figure3 \
    --description="The output Figure 3 pdf for the paper containing six graphs" \
    --type=required \
    --order_value=3 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_figure3" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-argument-${a_final_results}=final_results.csv
--SSREPI-argument-${a_figure3_cfg}=cfg/figure3.cfg
--SSREPI-argument-${a_figure3}=figure3.pdf
"""

ARGS="""$ARGS
--SSREPI-input-${i_final_results_id}=final_results.csv
--SSREPI-input-${i_figure3_cfg_id}=cfg/figure3.cfg
"""

ARGS="""$ARGS
--SSREPI-output-${o_figure3_id}=figure3.pdf
"""

SSREPI_run $A_FIGURE2_3PART $ARGS

# figure2-3part.R \
#    final_results.csv \
#    cfg/figure3.cfg \
#    figure3.pdf

# Metadata
# --------

vm_figure3_id=$(SSREPI_visualisation_method \
    "figure_3" \
    "A sunflower plot with curve fitting, plotting incentive (x-axis)
    against landscape scale species richness (y-axis)")

SSREPI_implements $A_FIGURE2_3PART \
    --visualisation_method=$vm_figure3_id

SSREPI_implements $A_FIGURE2_3PART \
    --visualisation_method=$vm_sunflower_plot_id
SSREPI_implements $A_FIGURE2_3PART \
    --statistical_method=$sm_recursive_partitioning_id
SSREPI_implements $A_FIGURE2_3PART \
    --visualisation_method=$vm_general_additive_model_id

sv_min_incentive_id=$(SSREPI_visualisation_variable \
    figure3_min_incentive \
    "Minimum value for horizontal axis in figure 3" \
    "\Z_{\ne 0}" \
    $vm_sunflower_plot_id)

sv_max_incentive_id=$(SSREPI_visualisation_variable \
    figure3_max_incentive \
    "Max value for horizontal axis in figure 3" \
    "\Z_{\ne 0}" \
    "$vm_sunflower_plot_id")

con_figure3_sunflower_plot_id=$(SSREPI_content \
    --visualisation_method="$vm_sunflower_plot_id" \
    --container_type=$o_figure3_id )

con_scenario_id=$(SSREPI_content \
    --variable=$var_scenario_id \
    --container_type=$o_figure3_id \
    --locator='grep -v ^scenario | cut -f1 -d,')

con_min_incentive_id=$(SSREPI_content \
    --statistical_variable=$sv_min_incentive_id \
    --container_type=$o_figure3_id \
    --locator='grep -v ^scenario | cut -f2 -d,')

con_max_incentive_id=$(SSREPI_content \
    --statistical_variable=$sv_max_incentive_id \
    --container_type=$o_figure3_id \
    --locator='grep -v ^scenario | cut -f3 -d,')

vis_sunflower_plot_fig3=$(SSREPI_visualisation \
    visualisation.$(uniq) \
    $vm_sunflower_plot_id \
    "figure2-3part.R final_results.csv cfg/figure3.cfg figure3.pdf" \
    figure3.pdf)

# Need to add more specifics to these. That is there are more fields for the
# value record

SSREPI_value \
    "A/F/30/1" \
    $var_scenario_id \
    figure3.pdf
SSREPI_statistical_variable_value \
    2 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    10 \
    $sv_max_incentive_id \
    figure3.pdf 

SSREPI_value \
    "A/V/30/1" \
    $var_scenario_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    2 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    15 \
    $sv_max_incentive_id \
    figure3.pdf 

SSREPI_value "CA/F/25/5" \
    $var_scenario_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    1 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    10 $sv_max_incentive_id figure3.pdf 

SSREPI_value \
    "O/F/30/5" \
    $var_scenario_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    1 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    8 \
    $sv_max_incentive_id \
    figure3.pdf 

SSREPI_value \
    "O/V/25/1" \
    $var_scenario_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    1 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    5 \
    $sv_max_incentive_id \
    figure3.pdf 

SSREPI_value \
    "CO/V/25/5" \
    $var_scenario_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    0.1 \
    $sv_min_incentive_id \
    figure3.pdf 
SSREPI_statistical_variable_value \
    0.8 \
    $sv_max_incentive_id \
    figure3.pdf 
    
# table 4 for presentation
# ========================

A_NONLINEARK4BSI=$(SSREPI_application nonlinearK4bsI.R \
    --description="This needs supplying")
[ -n "$A_NONLINEARK4BSI" ] || exit - 1

# Input types
# -----------

i_final_results_id=$(SSREPI_input $A_NONLINEARK4BSI final_results '^final_results.csv$')
[ -n "$i_final_results_id" ] || exit -1

# Output types
# ------------

o_table4_id=$(SSREPI_output $A_NONLINEARK4BSI table4 '^table4.csv$')
[ -n "$o_table4_id" ] || exit -1

# Argument types
# --------------

a_final_results=$(SSREPI_argument \
    $A_NONLINEARK4BSI \
    final_results \
    --description="Results files with selected scenarios" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_final_results" ] || exit -1

a_table4=$(SSREPI_argument \
    $A_NONLINEARK4BSI \
    table4 \
    --description="Results for table 4 in the paper" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_table4" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-input-${i_final_results_id}=final_results.csv
"""
ARGS="""$ARGS
--SSREPI-argument-${a_final_results}=final_results.csv
--SSREPI-argument-${a_table4}=table4.csv
"""

ARGS="""$ARGS
--SSREPI-output-${o_table4_id}=table4.csv
"""

SSREPI_run $A_NONLINEARK4BSI $ARGS

# Metadata
# --------

SSREPI_implements $A_NONLINEARK4BSI \
    --statistical_method="$sm_aic_id"
SSREPI_implements $A_NONLINEARK4BSI \
    --statistical_method="$sm_bic_id"
SSREPI_implements $A_NONLINEARK4BSI \
    --statistical_method="$sm_edf_id"
SSREPI_implements $A_NONLINEARK4BSI \
    --statistical_method="$sm_anova_gam_id"

sos_nonlinearK4bsI_aic_id=(SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $sm_aic_id)
sos_nonlinearK4bsI_bic_id=$(SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $sm_bic_id )
sos_nonlinearK4bsI_edf_id=$(SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $sm_edf_id )
sos_nonlinearK4bsI_anova_id=$(SSREPI_statistics "nonlinearK4bsI.R final_results.csv table4.csv" $sm_anova_gam_id )

# table 4 paper CSV
# =================

A_TABLE4=$(SSREPI_application table4.R \
    --description="""
    A small script to prodce a text version of the table found in
    Polhil et al (2013) - Nonlinearities in biodiversity incentive
    schemes: A study using an integrated agent-based and
    metacommunity model The original diagram was done with a
    mixture of R and Excel. I have automated this part.
""")

[ -n "$A_TABLE4" ] || exit - 1

# Input types
# -----------

i_table4_id=$(SSREPI_input $A_TABLE4 table4 '^table4.csv$')

# Output types
# ------------

o_table4_paper_id=$(SSREPI_input $A_TABLE4 table4_paper '^table4.paper.csv$')

# Argument types
# --------------

a_table4=$(SSREPI_argument \
    $A_TABLE4 \
    table4 \
    --description="Unprocessed table 4" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_table4" ] || exit -1

a_table4_paper=$(SSREPI_argument \
    $A_TABLE4 \
    table4_paper \
    --description="Results for table 4 in the paper" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_table4" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-argument-${a_table4}=table4.csv
--SSREPI-argument-${a_table4_paper}=table4.paper.csv
"""

ARGS="""$ARGS
--SSREPI-input-${i_table4_id}=table4.csv
"""

ARGS="""$ARGS
--SSREPI-output-${o_table4_paper_id}=table4.paper.csv
"""

SSREPI_run $A_TABLE4 $ARGS

# figure 4
# ========

A_FIGURE2_3S=$(SSREPI_application figure2-3s.R \
    --description="""
    Need some stuff here.
    Produces a sunflow plot for the paper
""")

[ -n "$A_FIGURE2_3S" ] || exit - 1

# Input types
# -----------

i_final_results_id=$(SSREPI_input $A_FIGURE2_3S final_results '^final_results.csv$')
[ -n "$i_final_results_id" ] || exit -1

# Output types
# ------------

o_figure4_id=$(SSREPI_output $A_FIGURE2_3S figure4 '^figure4.*\.pdf$')
[ -n "$o_figure4_id" ] || exit -1

# Argument types
# --------------

a_splits=$(SSREPI_argument \
    $A_FIGURE2_3S \
    splits \
    --description="I think this might be split the data" \
    --name="splits" \
    --type=flag \
)
[ -n "$a_splits" ] || exit -1

a_final_results=$(SSREPI_argument \
    $A_FIGURE2_3S \
    final_results \
    --description="Result files with selected scenarios" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref \
)
[ -n "$a_final_results" ] || exit -1

a_main_scenario=$(SSREPI_argument \
    $A_FIGURE2_3S \
    main_scenario \
    --description="Main scenario" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range='^.*$')
[ -n "$a_main_scenario" ] || exit -1

a_small_scenarios=$(SSREPI_argument \
    $A_FIGURE2_3S \
    small_scenarios \
    --description="Small scenarios" \
    --type=required \
    --order_value=3 \
    --arity=5 \
    --argsep='space' \
    --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$')
[ -n "$a_small_scenarios" ] || exit -1

a_figure4=$(SSREPI_argument \
    $A_FIGURE2_3S \
    figure5 \
    --description="PDF for figure 4" \
    --type=required \
    --order_value=4 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_figure4" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-argument-${a_splits} 
--SSREPI-argument-${a_final_results}=final_results.csv
--SSREPI-argument-${a_main_scenario}=Richness
--SSREPI-argument-${a_small_scenarios}=O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5
--SSREPI-argument-${a_figure4}=figure4.a_and_b.pdf
"""

ARGS="""$ARGS
--SSREPI-input-${i_final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-output-${o_figure4_id}=figure4.a_and_b.pdf
"""

SSREPI_run $A_FIGURE2_3S $ARGS

#figure2-3s.R 
#     --splits \
#       final_results.csv \
#       Richness \
#       O/V/25/5 O/V/25/1 O/V/30/5 A/V/25/5 CO/V/25/5
#    figure4.a_and_b.pdf

# Metadata
# --------

SSREPI_implements $A_FIGURE2_3S --visualisation_method=$vm_sunflower_plot_id

con_figure4_sunflower_plot_id=$(SSREPI_content \
    --visualisation_method=$vm_sunflower_plot_id \
    --container_type=$o_figure4_id \
)

con_varscenario_id=$(SSREPI_content \
    --variable=$var_scenario_id \
    --container_type=$o_figure4_id \
    --locator='grep -v ^scenario | cut -f1 -3,' \
)

vis_sunflower_plot_fig4=$(SSREPI_visualisation \
    visualisation_$(uniq) \
    $vm_sunflower_plot_id \
    "\"figure2-3s.R -splits final_results.csv Richness A/F/25/5 A/F/25/1 A/F/30/5 O/F/25/5 CA/F/25/5 figure4.a_and_b.pdf\"" \
    figure4.a_and_b.pdf \
)

# figure 5
# ========

A_TREEHIST3=$(SSREPI_application treehist3.pl \
    --description="Some documentation here, please.")
[ -n "$A_TREEHIST3" ] || exit - 1

# Input types
# -----------

i_final_results_id=$(SSREPI_input $A_TREEHIST3 final_results '^final_results.csv$')
[ -n "$i_final_results_id" ] || exit -1

# Output types
# ------------

o_figure5_id=$(SSREPI_output $A_TREEHIST3 figure5 '^.*.PDF$')
[ -n "$o_figure5_id" ] || exit -1

# Argument types
# --------------

a_complexity_variable=$(SSREPI_argument \
    $A_TREEHIST3 \
    complexity_variable \
    --description="Complexity Parameter" \
    --name="cp" \
    --separator='-' \
    --assignment_operator="space" \
    --type=option \
    --arity=1 \
    --range="^(1|[0\.[0-9]+)$")
[ -n "$a_complexity_variable" ] || exit -1

a_final_results=$(SSREPI_argument \
    $A_TREEHIST3 \
    final_results \
    --description="Results files with selected scenarios" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_final_results" ] || exit -1

a_figure5=$(SSREPI_argument \
    $A_TREEHIST3 \
    figure5 \
    --description="PDF for figure 5" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_figure5" ] || exit -1

a_response_variable=$(SSREPI_argument \
    $A_TREEHIST3 \
    response_variable \
    --description="Response variable" \
    --type=required \
    --order_value=3 \
    --arity=1 \
    --range=".*")
[ -n "$a_response_variable" ] || exit -1

a_explanatory_variables=$(SSREPI_argument \
    $A_TREEHIST3 \
    explanatory_variables \
    --description="Explanatory variables
    Comma (no space) separated values" \
    --name=expiriment \
    --type=required \
    --order_value=4 \
    --range="^(..*)(\,..*)*$")
[ -n "$a_explanatory_variables" ] || exit -1

# Execution
# =========

ARGS="""
--SSREPI-input-${i_final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-argument-${a_complexity_variable}=0.0075
--SSREPI-argument-${a_response_variable}=Richness
--SSREPI-argument-${a_final_results}=final_results.csv
--SSREPI-argument-${a_figure5}=LOBEC.rpart3Xfr.pdf 
--SSREPI-argument-${a_explanatory_variables}=Government,Market,BET,ASP,Expenditure 
"""

ARGS="""$ARGS
--SSREPI-output-${o_figure5_id}=LOBEC.rpart3Xfr.pdf 
"""

SSREPI_run $A_TREEHIST3 $ARGS

#treehist3.pl \
#    -cp 0.0075 \
#    final_results.csv  \
#    LOBEC.rpart3Xfr.pdf  \
#    Richness Government,Market,BET,ASP,Expenditure 

# Metadata
# --------

sos_from_recursive_partioning_id=$(SSREPI_statistics \
    sos_from_recursive_partitioning \
    $sm_recursive_partitioning_id \
    'treehist3.pl -cp 0.0075 final_results.csv LOBEC.rpart3Xfr.pdf Richness Government,Market,BET,ASP,Expenditure' \
)


SSREPI_implements $A_TREEHIST3 \
    --statistical_method="$sm_recursive_partitioning_id"

var_partitioning_complexity_id=$(SSREPI_variable  \
    var_partitioining_complexity \
    "A measure of complexity " \
    Integer \
)

SSREPI_value "0.0075" \
    $var_partitioning_complexity_id \
    LOBEC.rpart3Xfr.pdf \
    --statistical_parameter=$sos_from_recursive_partioning_id


sv_partitioning_complexity_id=$(SSREPI_statistical_variable \
    partitioning_complexity_id \
    "A measure of complexity used as a threshold in a classification to prune nodes." \
    "\mathbb{R}" \
    "$sm_recursive_partitioning_id" \
)

# Appendix 
# ========

A_FIGURE2_3SMALL=$(SSREPI_application figure2-3small.R \
    --description="Some words of wisdom about this script."
)
[ -n "$A_FIGURE2_3SMALL" ] || exit - 1

# Input types
# -----------

i_final_results_id=$(SSREPI_input $A_FIGURE2_3SMALL final_results '^final_results.csv$')
[ -n "$i_final_results_id" ] || exit -1

# Output types
# ------------

o_appendix_id=$(SSREPI_output $A_FIGURE2_3SMALL appendix '^appendix.pdf$')
[ -n "$o_appendix_id" ] || exit -1


# Argument types
# --------------

a_splits=$(SSREPI_argument \
    $A_FIGURE2_3SMALL \
    splits \
    --description="I think this might be split the data" \
    --name="splits" \
    --type=flag \
)
[ -n "$a_splits" ] || exit -1

a_final_results=$(SSREPI_argument \
    $A_FIGURE2_3SMALL \
    final_results \
    --description="Results files with selected scenarios" \
    --type=required \
    --order_value=1 \
    --arity=1 \
    --range=relative_ref)
[ -n "$a_final_results" ] || exit -1

a_y_axis=$(SSREPI_argument \
    $A_FIGURE2_3SMALL \
    y_axis \
    --description="y-axis label" \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range='.*')
[ -n "$a_y_axis" ] || exit -1

a_appendix=$(SSREPI_argument \
    $A_FIGURE2_3SMALL \
    appendix \
    --description="The diagram for inclusion in the appendix" \
    --type=required \
    --order_value=3 \
    --arity=1 \
    --range='^.*pdf$')
[ -n "$a_appendix" ] || exit -1

a_scenarios=$(SSREPI_argument \
    $A_FIGURE2_3SMALL \
    scenarios \
    --description="The Scenarios to include in the diagram" \
    --type=required \
    --order_value=4 \
    --arity=+ \
    --argsep='space' \
    --range='^A-ZA-Z?\/(V|F)\/[0-9][0-9]\/[0-9]$')
[ -n "$a_scenarios" ] || exit -1

ARGS="""
--SSREPI-argument-${a_splits}
--SSREPI-argument-${a_final_results}=final_results.csv
--SSREPI-argument-${a_appendix}=appendix.pdf
--SSREPI-argument-${a_y_axis}=Richness
--SSREPI-argument-${a_scenarios}=A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 CO/V/30/5
"""

ARGS="""$ARGS
--SSREPI-input-${i_final_results_id}=final_results.csv
"""

ARGS="""$ARGS
--SSREPI-output-${o_appendix_id}=appendix.pdf
"""

SSREPI_run $A_FIGURE2_3SMALL $ARGS

#figure2-3small.R -splits final_results.csv \
#    Richness \
#    appendix.pdf \
#    A/F/30/1 A/V/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
#    CO/V/30/5 CA/F/25/1 CA/F/30/1 CA/F/30/5 CA/V/25/1 CA/V/25/5 CA/V/30/1 \
#    CA/V/30/5 CO/F/25/1 CO/F/25/5 CO/F/30/1 CO/F/30/5 CO/V/25/1 CO/V/30/1 \
#    CO/V/30/5

# This is a bit of a PITA. Sometimes you need the following, sometimes you
# don't. But it ensures that zero status is returned from the $SSREPI_run
# program above, and thus the flow of the code is not terminated

exit 0

