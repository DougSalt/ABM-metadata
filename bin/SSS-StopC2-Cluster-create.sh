#!/bin/bash
#
# Shell script to create the SSS preliminary experiments. These are designed
# to cover sinks/nosinks and RewardActivity/RewardSpecies, at various BETs and
# ASPs, and for flat and var2 market. There will be 20 runs each

. lib/ssrepi_lib.sh

# Identity (stuff about this script)
# ========

ME=$(basename $(_calling_script))

SSREPI_contributor $ME gp40285 Author
SSREPI_contributor $ME ds42723 Author

next=$(SSREPI_create_pipeline $ME)
[ -n "$next" ] || exit -1

# Called script
# =============

# This could probably be done within a Perl program itself, for the purposes of
# this instance of generating metadata, I have done everything in the shell
# scripts.

PROG=$(SSREPI_call_perl_script $(which SSS-StopC2-Cluster-expt.pl))
[ -n $PROG ] || exit -1 

SSREPI_contributor $PROG gp40285 Author

next=$(SSREPI_add_application_to_pipeline $next $PROG)
[ -n "$next" ] || exit -1

# Assumptions
# ===========

dougs_assumption=$(SSREPI_person_makes_assumption \
	ds42723 "Gary knows what he is doing. This is an example
of an assumption, which you might want to fill in....

...and could conceivably go over several lines." \
		--short_name=generous)
garys_1st_assumption=$(SSREPI_person_makes_assumption gp40285 \
	"There are no bugs in this software.")
garys_2nd_assumption=$(SSREPI_person_makes_assumption gp40285 \
	"There are bugs in this software." \
	--short_name=reasonable)

# Requirements for this script 
# ============================

# Software

required_perl=$(SSREPI_require_minimum perl  "5.0" "$PROG")
required_python=$(SSREPI_require_minimum python  "2.6.6" "$PROG")
required_os=$(SSREPI_require_exact os Linux "$PROG")
required_shell=$(SSREPI_require_exact shell '/bin/bash' "$PROG")

# Hardware

required_disk_space=$(SSREPI_require_minimum disk_space "20G" "$PROG")
required_nof_cpus=$(SSREPI_require_minimum nof_cpus $NOF_CPUS "$PROG")
required_memory=$(SSREPI_require_minimum memory "4G" "$PROG")

# Argument types
# --------------

govt_id=$(SSREPI_argument \
	--id_argument=govt \
	--description="Type of governance" \
	--application=$PROG \
	--type=required \
	--order=1 \
	--arity=1 \
	--range="^(ClusterActivity|ClusterSpecies|RewardActivity|RewardSpecies)$")
[ -n $govt_id ] || exit -1

sink_id=$(SSREPI_argument \
	--id_argument=sink\
	--description="Type of governance" \
	--application=$PROG \
	--type=required \
	--order=2 \
	--arity=1 \
	--range="^(YES|NO)$")
[ -n $sink_id ] || exit -1

market_id=$(SSREPI_argument \
	--id_argument=market \
	--description="Market" \
	--application=$PROG \
	--type=required \
	--order=3 \
	--arity=1 \
	--range="^(flat|var1|var2)$")
[ -n $market_id ] || exit -1

zone_id=$(SSREPI_argument \
	--id_argument=zone \
	--description="Policy zone" \
	--application=$PROG \
	--name=zone \
	--type=required \
	--order=4 \
	--arity=1 \
	--range="^(all|random|rect)$")
[ -n $zone_id ] || exit -1

reward_id=$(SSREPI_argument \
	--id_argument=reward \
	--description="Reward budget" \
	--application=$PROG \
	--name=reward \
	--type=required \
	--order=5 \
	--arity=1 \
	--range="^[0-9]+(\.[0-9]+)?$")
[ -n $reward_id ] || exit -1

ratio_id=$(SSREPI_argument \
	--id_argument=ratio \
	--description="Cluster reward ratio" \
	--application=$PROG \
	--name=ratio \
	--type=required \
	--order=6 \
	--arity=1 \
	--range="^[0-9]+(\.[0-9]+)?$")
[ -n $ratio_id ] || exit -1

bet_id=$(SSREPI_argument \
	--id_argument=bet \
	--description="Break-even threshold" \
	--application=$PROG \
	--name=bet \
	--type=required \
	--order=7 \
	--arity=1 \
	--range="^[0-9]+(\.[0-9]+)?$")
[ -n $bet_id ] || exit -1

approval_id=$(SSREPI_argument \
	--id_argument=approval \
	--description="Approval" \
	--application=$PROG \
	--name=approval \
	--type=required \
	--order=8 \
	--arity=1 \
	--range="^(YES|NO)$")
[ -n $approval_id ] || exit -1

iwealth_id=$(SSREPI_argument \
	--id_argument=iwealth \
	--description="Initial wealth" \
	--application=$PROG \
	--name=iwealth \
	--type=required \
	--order=9 \
	--arity=1 \
	--range="^[0-9]+(\.[0-9]+)?$")
[ -n $iwealth_id ] || exit -1

aspiration_id=$(SSREPI_argument \
	--id_argument=aspiration \
	--description="Aspriation threshold" \
	--application=$PROG \
	--name=aspiration \
	--type=required \
	--order=10 \
	--arity=1 \
	--range="^[0-9]+(\.[0-9]+)?$")
[ -n $aspiration_id ] || exit -1

run_id=$(SSREPI_argument \
	--id_argument=run \
	--description="Run number" \
	--application=$PROG \
	--name=run \
	--type=required \
	--order=11 \
	--arity=1 \
	--range="^\d+$")
[ -n $run_id ] || exit -1

# Output types
# ------------

SSS_economystate_id=$(SSREPI_output_type $PROG \
	SSS_economystate \
	"______[^_]+_____.state")
[ -n "$SSS_economystate_id" ] || exit -1 

SSS_top_level_subpop_id=$(SSREPI_output_type $PROG \
	SSS_top-level-subpop \
	"________[^_]+_[^_]+_[^_]+_.ssp")
[ -n "$SSS_top_level_subpop_id" ] || exit -1 

SSS_grid_id=$(SSREPI_output_type $PROG \
	SSS_grid \
	"___________[^_]+.grd")
[ -n "$SSS_grid_id" ] || exit -1 

SSS_top_level_id=$(SSREPI_output_type $PROG \
	SSS_top-level \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.model")
[ -n "$SSS_top_level_id" ] || exit -1 

SSS_species_id=$(SSREPI_output_type $PROG \
	SSS_species \
	"_[^_]+__________.csv")
[ -n "$SSS_species_id" ] || exit -1 

SSS_subpop_id=$(SSREPI_output_type $PROG \
	SSS_subpop \
	"________[^_]+_[^_]+_[^_]+_.sp")
[ -n "$SSS_subpop_id" ] || exit -1 

SSS_yieldtree_id=$(SSREPI_output_type $PROG \
	SSS_yieldtree \
	"___________.tree")
[ -n "$SSS_yieldtree_id" ] || exit -1 

SSS_fearlus_id=$(SSREPI_output_type $PROG \
	SSS_fearlus \
	"__[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.fearlus")
[ -n "$SSS_fearlus_id" ] || exit -1 

SSS_government_id=$(SSREPI_output_type $PROG \
	SSS_government \
	"__[^_]+_[^_]+_[^_]+_[^_]+______.gov")
[ -n "$SSS_government_id" ] || exit -1 

SSS_sink_id=$(SSREPI_output_type $PROG \
	SSS_sink \
	"_[^_]+__________.csv")
[ -n "$SSS_sink_id" ] || exit -1 

SSS_incometree_id=$(SSREPI_output_type $PROG \
	SSS_incometree \
	"______[^_]+_____.tree")
[ -n "$SSS_incometree_id" ] || exit -1 

SSS_luhab_id=$(SSREPI_output_type $PROG \
	SSS_luhab \
	"___________.csv")
[ -n "$SSS_luhab_id" ] || exit -1 

SSS_climateprob_id=$(SSREPI_output_type $PROG \
	SSS_climateprob \
	"___________.prob")
[ -n "$SSS_climateprob_id" ] || exit -1 

SSS_patch_id=$(SSREPI_output_type $PROG \
	SSS_patch \
	"_[^_]+__________[^_]+.csv")
[ -n "$SSS_patch_id" ] || exit -1 

SSS_report_config_id=$(SSREPI_output_type $PROG \
	SSS_report-config \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.repcfg")
[ -n "$SSS_report_config_id" ] || exit -1 

SSS_yielddata_id=$(SSREPI_output_type $PROG \
	SSS_yielddata \
	"___________.data")
[ -n "$SSS_yielddata_id" ] || exit -1 

SSS_spom_id=$(SSREPI_output_type $PROG \
	SSS_spom \
	"_[^_]+__________[^_]+.spom")
[ -n "$SSS_spom_id" ] || exit -1 

SSS_economyprob_id=$(SSREPI_output_type $PROG \
	SSS_economyprob \
	"___________.prob")
[ -n "$SSS_economyprob_id" ] || exit -1 

SSS_dummy_id=$(SSREPI_output_type $PROG \
	SSS_dummy \
	"___________[^_]+.csv")
[ -n "$SSS_dummy_id" ] || exit -1 

SSS_incomedata_id=$(SSREPI_output_type $PROG \
	SSS_incomedata \
	"______[^_]+_____.data")
[ -n "$SSS_incomedata_id" ] || exit -1 

SSS_event_id=$(SSREPI_output_type $PROG \
	SSS_event \
	"________[^_]+___.event")
[ -n "$SSS_event_id" ] || exit -1 

SSS_trigger_id=$(SSREPI_output_type $PROG \
	SSS_trigger \
	"________[^_]+___.trig")
[ -n "$SSS_trigger_id" ] || exit -1 

SSS_CWD_id=$(SSREPI_working_directory $PROG \
	"SSS__dir_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_")
[ -n "$SSS_CWD_id" ] || exit -1 

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

# The bracket means that this in-between code is sub-processed, thus retaining
# the process's separate identity for terms of provenance. That is each run of
# the perl script is associated with a separate process with its own particular
# inputs and outputs.

(

THIS_PROCESS=$(SSREPI_process --executable=$PROG)

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

# Do not need to check the shell as the hashbang insists we are running
# under bash, so we just need to set the meets criterion.

SSREPI_meets $required_shell

if SSREPI_fails_exact_requirement $required_os $(uname)
then
	(>&2 echo "$0: Exact requirement for the OS failed")
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

SSREPI_argument_value $THIS_PROCESS $govt_id $govt
SSREPI_argument_value $THIS_PROCESS $sink_id $sink
SSREPI_argument_value $THIS_PROCESS $market_id $market
SSREPI_argument_value $THIS_PROCESS $zone_id "all"
SSREPI_argument_value $THIS_PROCESS $reward_id $rew
SSREPI_argument_value $THIS_PROCESS $ratio_id $rat
SSREPI_argument_value $THIS_PROCESS $bet_id $bet
SSREPI_argument_value $THIS_PROCESS $approval_id "NO"
SSREPI_argument_value $THIS_PROCESS $iwealth_id "0.0"
SSREPI_argument_value $THIS_PROCESS $aspiration_id $asp
SSREPI_argument_value $THIS_PROCESS $run_id $run

bin/SSS-StopC2-Cluster-expt.pl \
	$govt \
	NO \
	$market \
	all \
	$rwd \
	$rat \
	$bet \
	NO \
	0.0 \
	$asp \
	$run 2>&1 > /dev/null

DIR="SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_"

SSREPI_output $PROG $THIS_PROCESS $SSS_CWD_id $DIR 

SSREPI_output $PROG $THIS_PROCESS $SSS_economystate_id \
	"$DIR/SSS_economystate______${market}_____.state"
SSREPI_output $PROG $THIS_PROCESS $SSS_top_level_subpop_id \
	"$DIR/SSS_top-level-subpop________noapproval_0.0_${asp}_.ssp"
SSREPI_output $PROG $THIS_PROCESS $SSS_grid_id \
	"$DIR/SSS_grid___________${run}.grd"
SSREPI_output $PROG $THIS_PROCESS $SSS_top_level_id \
	"$DIR/SSS_top-level_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.model"
SSREPI_output $PROG $THIS_PROCESS $SSS_species_id \
	"$DIR/SSS_species_${sink}__________.csv"
SSREPI_output $PROG $THIS_PROCESS $SSS_subpop_id \
	"$DIR/SSS_subpop________noapproval_0.0_${asp}_.sp"
SSREPI_output $PROG $THIS_PROCESS $SSS_yieldtree_id \
	"$DIR/SSS_yieldtree___________.tree"
SSREPI_output $PROG $THIS_PROCESS $SSS_fearlus_id \
	"$DIR/SSS_fearlus__${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.fearlus"
SSREPI_output $PROG $THIS_PROCESS $SSS_government_id \
	"$DIR/SSS_government__${govt}_all_${rwd}_${rat}______.gov"
SSREPI_output $PROG $THIS_PROCESS $SSS_sink_id \
	"$DIR/SSS_sink_${sink}__________.csv"
SSREPI_output $PROG $THIS_PROCESS $SSS_incometree_id \
	"$DIR/SSS_incometree______${market}_____.tree"
SSREPI_output $PROG $THIS_PROCESS $SSS_luhab_id \
	"$DIR/SSS_luhab___________.csv"
SSREPI_output $PROG $THIS_PROCESS $SSS_climateprob_id \
	"$DIR/SSS_climateprob___________.prob"
SSREPI_output $PROG $THIS_PROCESS $SSS_patch_id \
	"$DIR/SSS_patch_${sink}__________${run}.csv"
SSREPI_output $PROG $THIS_PROCESS $SSS_report_config_id \
	"$DIR/SSS_report-config_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.repcfg"
SSREPI_output $PROG $THIS_PROCESS $SSS_yielddata_id \
	"$DIR/SSS_yielddata___________.data"
SSREPI_output $PROG $THIS_PROCESS $SSS_spom_id \
	"$DIR/SSS_spom_${sink}__________${run}.spom"
SSREPI_output $PROG $THIS_PROCESS $SSS_economyprob_id \
	"$DIR/SSS_economyprob___________.prob"
SSREPI_output $PROG $THIS_PROCESS $SSS_incomedata_id \
	"$DIR/SSS_incomedata______${market}_____.data"
SSREPI_output $PROG $THIS_PROCESS $SSS_event_id \
	"$DIR/SSS_event________noapproval___.event"
SSREPI_output $PROG $THIS_PROCESS $SSS_trigger_id \
	"$DIR/SSS_trigger________noapproval___.trig"
for i in -1 -2 -3 -4 -5 -6 -7
do
	SSREPI_output $PROG $THIS_PROCESS $SSS_dummy_id \
		"$DIR/SSS_dummy___________${i}.csv"
done

THIS_PROCESS=$(SSREPI_process \
        --id_process=$THIS_PROCESS \
	--executable=$PROG \
        --end_time=$(date "+%Y%m%dT%H%M%S"))


)
		if [ $? -ne 0 ]
		then
			(>&2 echo "$0: Problem setting up a run")
			exit -1
		fi
	      done
	    done
	  done
	done
      done
    done
  done
done
