#!/usr/bin/env bash
#
# Shell script to create the SSS preliminary experiments. These are designed
# to cover sinks/nosinks and RewardActivity/RewardSpecies, at various BETs and
# ASPs, and for flat and var2 market. There will be 20 runs each

echo "$0: started."

. lib/ssrepi_cli.sh

# Identity (stuff about this script)
# ========

ME=$(SSREPI_me)

SSREPI_contributor $ME gary_polhill Author
SSREPI_contributor $ME doug_salt Author

pipe=$(SSREPI_pipeline $ME)

# Called script
# =============

# This could probably be done within a Perl program itself, for the purposes of
# this instance of generating metadata, I have done everything in the shell
# scripts.

PROG=$(SSREPI_application SSS-StopC2-Cluster-expt.pl \
    --purpose="Perl script to create the SSS preliminary experiments. These are designed to cover sinks/nosinks and RewardActivity/RewardSpecies, at various BETs and ASPs, and for flat and var2 market." \
    --version=1.0 \
    --licence=GPLv3 \
)
[ -n $PROG ] || exit -1 

SSREPI_contributor $PROG gary_polhill Author

# Assumptions
# ===========

dougs_assumption=$(SSREPI_person_makes_assumption \
    doug_salt "Gary knows what he is doing. This is an example
of an assumption, which you might want to fill in....

...and could conceivably go over several lines." \
    --short_name=generous)
garys_1st_assumption=$(SSREPI_person_makes_assumption gary_polhill \
    "There are no bugs in this software.")
garys_2nd_assumption=$(SSREPI_person_makes_assumption gary_polhill \
    "There are bugs in this software." \
    --short_name=reasonable)

# Requirements for this script 
# ============================

# Software

if SSREPI_require_minimum $PROG perl  "5.0" $(perl -e 'print $];')
then
    (>&2 echo "$0: Minimum requirement for Perl failed")
    (>&2 echo "$0: Required at least Perl 5.0, got " \
    $(perl -e 'print $];'))
    exit -1
fi


if SSREPI_require_minimum $PROG python "3.0" $(python --version 2>&1 | cut -f2 -d' ')
then
    (>&2 echo "$0: Minimum requirement for Python failed")
    (>&2 echo "$0: Required 3.0 got " \
    $(python --version 2>&1 | cut -f2 -d' '))
    exit -1
fi

if SSREPI_require_minimum $PROG bash 3 $(bash --version | sed -n 1p | awk '{print $4}' | cut -f1 -d.)
then
    (>&2 echo "$0: Minimum requirement for bash failed")
    (>&2 echo "$0: Required 3 got " \
    $(bash --version | sed -n 1p | awk '{print $4}' | cut -f1 -d.))
    exit -1
fi

if SSREPI_require_exact $PROG os Linux $(uname -s) && SSREPI_require_exact $PROG os Darwin $(uname -s) 
then
    (>&2 echo "$0: Exact requirement for the OS failed")
    (>&2 echo "$0: Required Linux or  Darwin got "$(uname -s))
    exit -1
fi

# Hardware

if SSREPI_require_minimum $PROG disk_space 20G $(disk_space)
then
    (>&2 echo "$0: Minimum requirement for disk space failed")
    (>&2 echo "$0: Required 20G of disk space got "$(disk_space))
    exit -1
fi

if SSREPI_require_minimum $PROG memory 4 $(memory)
then
    (>&2 echo "$0: Minimum requirement for memory failed")
    (>&2 echo "$0: Required 4G of memory got $(memory)G")
    exit -1
fi

if SSREPI_require_minimum $PROG cpus $REQUIRED_NOF_CPUS $(cpus) 
then
    (>&2 echo "$0: Minimum requirement for number of cpus failed")
    (>&2 echo "$0: Required $REQUIRED_NOF_CPUS cpus of memory got $(cpus)")
    exit -1
fi

# Argument types
# --------------

govt_id=$(SSREPI_argument \
    $PROG \
    govt \
    --description="Type of governance" \
    --type=required \
    --name=govt \
    --order_value=1 \
    --arity=1 \
    --range="^(ClusterActivity|ClusterSpecies|RewardActivity|RewardSpecies)$")
[ -n $govt_id ] || exit -1

sink_id=$(SSREPI_argument \
    $PROG \
    sink\
    --description="Type of governance" \
    --name=sink \
    --type=required \
    --order_value=2 \
    --arity=1 \
    --range="^(YES|NO)$")
[ -n $sink_id ] || exit -1

market_id=$(SSREPI_argument \
    $PROG \
    market \
    --description="Market" \
    --name=market \
    --type=required \
    --order_value=3 \
    --arity=1 \
    --range="^(flat|var1|var2)$")
[ -n $market_id ] || exit -1

zone_id=$(SSREPI_argument \
    $PROG \
    zone \
    --description="Policy zone" \
    --name=zone \
    --type=required \
    --order_value=4 \
    --arity=1 \
    --range="^(all|random|rect)$")
[ -n $zone_id ] || exit -1

reward_id=$(SSREPI_argument \
    $PROG \
    reward \
    --description="Reward budget" \
    --name=reward \
    --type=required \
    --order_value=5 \
    --arity=1 \
    --range="^[0-9]+(\.[0-9]+)?$")
[ -n $reward_id ] || exit -1

ratio_id=$(SSREPI_argument \
    $PROG \
    ratio \
    --description="Cluster reward ratio" \
    --name=ratio \
    --type=required \
    --order_value=6 \
    --arity=1 \
    --range="^[0-9]+(\.[0-9]+)?$")
[ -n $ratio_id ] || exit -1

bet_id=$(SSREPI_argument \
    $PROG \
    bet \
    --description="Break-even threshold" \
    --name=bet \
    --type=required \
    --order_value=7 \
    --arity=1 \
    --range="^[0-9]+(\.[0-9]+)?$")
[ -n $bet_id ] || exit -1

approval_id=$(SSREPI_argument \
    $PROG \
    approval \
    --description="Approval" \
    --name=approval \
    --type=required \
    --order_value=8 \
    --arity=1 \
    --range="^(YES|NO)$")
[ -n $approval_id ] || exit -1

iwealth_id=$(SSREPI_argument \
    $PROG \
    iwealth \
    --description="Initial wealth" \
    --name=iwealth \
    --type=required \
    --order_value=9 \
    --arity=1 \
    --range="^[0-9]+(\.[0-9]+)?$")
[ -n $iwealth_id ] || exit -1

aspiration_id=$(SSREPI_argument \
    $PROG \
    aspiration \
    --description="Aspriation threshold" \
    --name=aspiration \
    --type=required \
    --order_value=10 \
    --arity=1 \
    --range="^[0-9]+(\.[0-9]+)?$")
[ -n $aspiration_id ] || exit -1

run_id=$(SSREPI_argument \
    $PROG \
    run \
    --description="Run number" \
    --name=run \
    --type=required \
    --order_value=11 \
    --arity=1 \
    --range="^\d+$")
[ -n $run_id ] || exit -1

# Output types
# ------------

SSS_economystate_id=$(SSREPI_output $PROG \
    SSS_economystate \
    "______[^_]+_____.state")
[ -n "$SSS_economystate_id" ] || exit -1 

SSS_top_level_subpop_id=$(SSREPI_output $PROG \
    SSS_top-level-subpop \
    "________[^_]+_[^_]+_[^_]+_.ssp")
[ -n "$SSS_top_level_subpop_id" ] || exit -1 

SSS_grid_id=$(SSREPI_output $PROG \
    SSS_grid \
    "___________[^_]+.grd")
[ -n "$SSS_grid_id" ] || exit -1 

SSS_top_level_id=$(SSREPI_output $PROG \
    SSS_top-level \
    "_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.model")
[ -n "$SSS_top_level_id" ] || exit -1 

SSS_species_id=$(SSREPI_output $PROG \
    SSS_species \
    "_[^_]+__________.csv")
[ -n "$SSS_species_id" ] || exit -1 

SSS_subpop_id=$(SSREPI_output $PROG \
    SSS_subpop \
    "________[^_]+_[^_]+_[^_]+_.sp")
[ -n "$SSS_subpop_id" ] || exit -1 

SSS_yieldtree_id=$(SSREPI_output $PROG \
    SSS_yieldtree \
    "___________.tree")
[ -n "$SSS_yieldtree_id" ] || exit -1 

SSS_fearlus_id=$(SSREPI_output $PROG \
    SSS_fearlus \
    "__[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.fearlus")
[ -n "$SSS_fearlus_id" ] || exit -1 

SSS_government_id=$(SSREPI_output $PROG \
    SSS_government \
    "__[^_]+_[^_]+_[^_]+_[^_]+______.gov")
[ -n "$SSS_government_id" ] || exit -1 

SSS_sink_id=$(SSREPI_output $PROG \
    SSS_sink \
    "_[^_]+__________.csv")
[ -n "$SSS_sink_id" ] || exit -1 

SSS_incometree_id=$(SSREPI_output $PROG \
    SSS_incometree \
    "______[^_]+_____.tree")
[ -n "$SSS_incometree_id" ] || exit -1 

SSS_luhab_id=$(SSREPI_output $PROG \
    SSS_luhab \
    "___________.csv")
[ -n "$SSS_luhab_id" ] || exit -1 

SSS_climateprob_id=$(SSREPI_output $PROG \
    SSS_climateprob \
    "___________.prob")
[ -n "$SSS_climateprob_id" ] || exit -1 

SSS_patch_id=$(SSREPI_output $PROG \
    SSS_patch \
    "_[^_]+__________[^_]+.csv")
[ -n "$SSS_patch_id" ] || exit -1 

SSS_report_config_id=$(SSREPI_output $PROG \
    SSS_report-config \
    "_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.repcfg")
[ -n "$SSS_report_config_id" ] || exit -1 

SSS_yielddata_id=$(SSREPI_output $PROG \
    SSS_yielddata \
    "___________.data")
[ -n "$SSS_yielddata_id" ] || exit -1 

SSS_spom_id=$(SSREPI_output $PROG \
    SSS_spom \
    "_[^_]+__________[^_]+.spom")
[ -n "$SSS_spom_id" ] || exit -1 

SSS_economyprob_id=$(SSREPI_output $PROG \
    SSS_economyprob \
    "___________.prob")
[ -n "$SSS_economyprob_id" ] || exit -1 

SSS_dummy_id=$(SSREPI_output $PROG \
    SSS_dummy \
    "___________[^_]+.csv")
[ -n "$SSS_dummy_id" ] || exit -1 

SSS_incomedata_id=$(SSREPI_output $PROG \
    SSS_incomedata \
    "______[^_]+_____.data")
[ -n "$SSS_incomedata_id" ] || exit -1 

SSS_event_id=$(SSREPI_output $PROG \
    SSS_event \
    "________[^_]+___.event")
[ -n "$SSS_event_id" ] || exit -1 

SSS_trigger_id=$(SSREPI_output $PROG \
    SSS_trigger \
    "________[^_]+___.trig")
[ -n "$SSS_trigger_id" ] || exit -1 

for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
do
    for govt in ClusterActivity ClusterSpecies RewardActivity RewardSpecies
    do
        for sink in nosink
        do
            for market in flat
            do
                for bet in 25.0 30.0
                do
                    for asp in 1.0 5.0
                    do
                        for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
                        do
                            for rat in 1.0 2.0 10.0
                            do 

                                DIR="SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_"
                                
                                ARGS="""
                                --SSREPI-argument-${govt_id}=$govt
                                --SSREPI-argument-${sink_id}=NO
                                --SSREPI-argument-${market_id}=$market
                                --SSREPI-argument-${zone_id}=all
                                --SSREPI-argument-${reward_id}=$rwd
                                --SSREPI-argument-${ratio_id}=$rat
                                --SSREPI-argument-${bet_id}=$bet
                                --SSREPI-argument-${approval_id}=NO
                                --SSREPI-argument-${iwealth_id}=0
                                --SSREPI-argument-${aspiration_id}=$asp
                                --SSREPI-argument-${run_id}=$run
                                """

                                ARGS="""$ARGS
                                --SSREPI-output-${SSS_sink_id}="$DIR/SSS_sink_${sink}__________.csv"
                                --SSREPI-output-${SSS_incometree_id}="$DIR/SSS_incometree______${market}_____.tree"
                                --SSREPI-output-${SSS_luhab_id}="$DIR/SSS_luhab___________.csv"
                                --SSREPI-output-${SSS_climateprob_id}="$DIR/SSS_climateprob___________.prob"
                                --SSREPI-output-${SSS_patch_id}="$DIR/SSS_patch_${sink}__________${run}.csv"
                                --SSREPI-output-${SSS_report_config_id}="$DIR/SSS_report-config_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.repcfg"
                                --SSREPI-output-${SSS_yielddata_id}="$DIR/SSS_yielddata___________.data"
                                --SSREPI-output-${SSS_spom_id}="$DIR/SSS_spom_${sink}__________${run}.spom"
                                --SSREPI-output-${SSS_economyprob_id}="$DIR/SSS_economyprob___________.prob"
                                --SSREPI-output-${SSS_incomedata_id}="$DIR/SSS_incomedata______${market}_____.data"
                                --SSREPI-output-${SSS_event_id}="$DIR/SSS_event________noapproval___.event"
                                --SSREPI-output-${SSS_trigger_id}="$DIR/SSS_trigger________noapproval___.trig"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-1.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-2.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-3.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-4.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-5.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-6.csv"
                                --SSREPI-output-${SSS_dummy_id}="$DIR/SSS_dummy___________-7.csv"
                                """

                                SSREPI_run $PROG $ARGS --cwd="Cluster2"
                                    
                                if [ -n "$test" ]
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

echo "$0: ended."
