#!/usr/bin/env bash

# Shell script to run the SSS experiments

# Author: Doug Salt

# Date: January 2017

echo "$0: Started."

. lib/ssrepi_cli.sh

# The Model
# =========

FEARLUS_EXE=fearlus-1.1.5.2_spom-2.3
FEARLUS=$(which $FEARLUS_EXE)

if [ -z "$FEARLUS" ]
then
	(>&2 echo $0: No exectuable found for $FEARLUS_EXE)
	exit -1
fi

# Identity
# ========

ME=$(SSREPI_me)

SSREPI_contributor $ME gary_polhill Author
SSREPI_contributor $ME doug_salt Author 

PROG=$(SSREPI_application \
	$FEARLUS \
	--licence=GPLv3 \
	--version=1.1.5.2_spom-2.3 \
	--description="Framework for Evaluation and Assessment of Regional Land Use Scenarios (FEARLUS) = Stochastic Patch Occupancy Model (SPOM)" \
)
[ -n $PROG ] || exit -1

SSREPI_contributor $PROG gary_polhill Author

# Requirements for this script
# ============================

# Software

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

# Inputs Types
# ------------

SSS_economystate_id=$(SSREPI_input $PROG \
	SSS_economystate \
	"______[^_]+_____.state")
[ -n "$SSS_economystate_id" ] || exit -1 

SSS_top_level_subpop_id=$(SSREPI_input $PROG \
	SSS_top-level-subpop \
	"________[^_]+_[^_]+_[^_]+_.ssp")
[ -n "$SSS_top_level_subpop_id" ] || exit -1 

SSS_grid_id=$(SSREPI_input $PROG \
	SSS_grid \
	"___________[^_]+.grd")
[ -n "$SSS_grid_id" ] || exit -1 

SSS_top_level_id=$(SSREPI_input $PROG \
	SSS_top-level \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.model")
[ -n "$SSS_top_level_id" ] || exit -1 

SSS_species_id=$(SSREPI_input $PROG \
	SSS_species \
	"_[^_]+__________.csv")
[ -n "$SSS_species_id" ] || exit -1 

SSS_subpop_id=$(SSREPI_input $PROG \
	SSS_subpop \
	"________[^_]+_[^_]+_[^_]+_.sp")
[ -n "$SSS_subpop_id" ] || exit -1 

SSS_yieldtree_id=$(SSREPI_input $PROG \
	SSS_yieldtree \
	"___________.tree")
[ -n "$SSS_yieldtree_id" ] || exit -1 

SSS_fearlus_id=$(SSREPI_input $PROG \
	SSS_fearlus \
	"__[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.fearlus")
[ -n "$SSS_fearlus_id" ] || exit -1 

SSS_government_id=$(SSREPI_input $PROG \
	SSS_government \
	"__[^_]+_[^_]+_[^_]+_[^_]+______.gov")
[ -n "$SSS_government_id" ] || exit -1 

SSS_sink_id=$(SSREPI_input $PROG \
	SSS_sink \
	"_[^_]+__________.csv")
[ -n "$SSS_sink_id" ] || exit -1 

SSS_incometree_id=$(SSREPI_input $PROG \
	SSS_incometree \
	"______[^_]+_____.tree")
[ -n "$SSS_incometree_id" ] || exit -1 

SSS_luhab_id=$(SSREPI_input $PROG \
	SSS_luhab \
	"___________.csv")
[ -n "$SSS_luhab_id" ] || exit -1 

SSS_climateprob_id=$(SSREPI_input $PROG \
	SSS_climateprob \
	"___________.prob")
[ -n "$SSS_climateprob_id" ] || exit -1 

SSS_patch_id=$(SSREPI_input $PROG \
	SSS_patch \
	"_[^_]+__________[^_]+.csv")
[ -n "$SSS_patch_id" ] || exit -1 

SSS_report_config_id=$(SSREPI_input $PROG \
	SSS_report-config \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.repcfg")
[ -n "$SSS_report_config_id" ] || exit -1 

SSS_yielddata_id=$(SSREPI_input $PROG \
	SSS_yielddata \
	"___________.data")
[ -n "$SSS_yielddata_id" ] || exit -1 

SSS_spom_id=$(SSREPI_input $PROG \
	SSS_spom \
	"_[^_]+__________[^_]+.spom")
[ -n "$SSS_spom_id" ] || exit -1 

SSS_economyprob_id=$(SSREPI_input $PROG \
	SSS_economyprob \
	"___________.prob")
[ -n "$SSS_economyprob_id" ] || exit -1 

SSS_dummy_id=$(SSREPI_input $PROG \
	SSS_dummy \
	"___________[^_]+.csv")
[ -n "$SSS_dummy_id" ] || exit -1 

SSS_incomedata_id=$(SSREPI_input $PROG \
	SSS_incomedata \
	"______[^_]+_____.data")
[ -n "$SSS_incomedata_id" ] || exit -1 

SSS_event_id=$(SSREPI_input $PROG \
	SSS_event \
	"________[^_]+___.event")
[ -n "$SSS_event_id" ] || exit -1 

SSS_trigger_id=$(SSREPI_input $PROG \
	SSS_trigger \
	"________[^_]+___.trig")
[ -n "$SSS_trigger_id" ] || exit -1 

	

# Arguments
# ---------

batch_id=$(SSREPI_argument \
	$PROG \
	batch \
	--description="Run in batch mode" \
	--name="batch" \
	--short_name="b" \
	--type=flag \
	)
[ -n $batch_id ] || exit -1

varyseed_id=$(SSREPI_argument \
	$PROG \
	varyseed \
	--short_name="s" \
	--name="varyseed" \
	--description="Select random number seed from current time" \
	--type=flag \
	)
[ -n $varyseed_id ] || exit -1

show_current_time_id=$(SSREPI_argument \
	$PROG \
	show_current_time \
	--short_name="t" \
	--name="show-current-time" \
	--description="Show current time in control panel" \
	--type=flag \
	)
[ -n $show_current_time_id ] || exit -1

no_init_file_id=$(SSREPI_argument \
	$PROG \
	no_init_file \
	--name="no-init-file" \
	--description="Inhibit loading of ~/.swarmArchiver" \
	--type=flag \
	)
[ -n $no_init_file_id ] || exit -1

verbose_id=$(SSREPI_argument \
	$PROG \
	verbose \
	--short_name="v" \
	--name="verbose" \
	--description="Activate verbose messages" \
	--type=flag \
	)
[ -n $verbose_id ] || exit -1

append_report_id=$(SSREPI_argument \
	$PROG \
	append_report \
	--short_name="a" \
	--name="append-report" \
	--type=flag \
	--arity=0 \
	--description="If report file exists, then append to it" \
	)
[ -n $append_report_id ] || exit -1

ontology_all_years_id=$(SSREPI_argument \
	$PROG \
	ontology_all_years \
	--short_name="A" \
	--name="ontology-all-years" \
	--description="Output a model state ontology each year (warning:" \
	--type=flag \
	)
[ -n $ontology_all_years_id ] || exit -1

conditions_id=$(SSREPI_argument \
	$PROG \
	conditions \
	--short_name="-c" \
	--name="conditions" \
	--description="Show conditions of redistribution" \
	--type=flag \
	)
[ -n $conditions_id ] || exit -1

warranty_id=$(SSREPI_argument \
	$PROG \
	warranty \
	--short_name="w" \
	--name="warranty" \
	--description="Show warranty information" \
	--type=flag \
	)
[ -n $waranty_id ] || exit -1

help_id=$(SSREPI_argument \
	$PROG \
	help \
	--short_name="?" \
	--name="help" \
	--description="Give this help list" \
	--type=flag \
	)
[ -n $help_id ] || exit -1

usage_id=$(SSREPI_argument \
	$PROG \
	usage \
	--name="usage" \
	--description="Give a short usage message" \
	--type=flag \
	)
[ -n $usage_id ] || exit -1

version_id=$(SSREPI_argument \
	$PROG \
	version \
	--short_name="V" \
	--name="version" \
	--description="Print program version" \
	--type=flag \
	)
[ -n $version_id ] || exit -1

seed_id=$(SSREPI_argument \
	$PROG \
	seed \
	--short_name="S" \
	--name="seed" \
	--description="Specify seed for random numbers" \
	--arity=1 \
	--range="[0-9]+" \
	--type=option \
	)
[ -n $seed_id ] || exit -1

mode_id=$(SSREPI_argument \
	$PROG \
	mode \
	--short_name="m" \
	--name="mode" \
	--description="Specify mode of use (for archiving) will potentially require a lot of disk space)" \
	--arity=1 \
	--type=option \
	--range="^\s+" \
	)
[ -n $mode_id ] || exit -1
	

ontology_class_id=$(SSREPI_argument \
	$PROG \
	ontology_class \
	--short_name="C" \
	--name="ontology-class" \
	--description="Record structural ontology from subclasses of CLASS" \
	--arity=1 \
	--type=option \
	--range="^\s+" \
	)
[ -n $class_id ] || exit -1

debug_id=$(SSREPI_argument \
	$PROG \
	debug \
	--short_name="D" \
	--name="debug" \
	--description="Debug level (integer) and/or a list of +/- separated message symbols" \
	--arity=1 \
	--type=option \
	--range="^\s+((\+|\-)\s+)?$" \
	)
[ -n $debug_id ] || exit -1

gridServiceUID_id=$(SSREPI_argument \
	$PROG \
	gridServiceUID \
	--short_name="g" \
	--name="gridServiceUID" \
	--description="User ID for FEARLUS-G Service" \
	--arity=1 \
	--type=option \
	--range="^\s+" \
	)
[ -n $gridServiceUID_id ] || exit -1

gridServiceURL_id=$(SSREPI_argument \
	$PROG \
	gridServiceURL \
	--short_name="G" \
	--name="gridServiceURL" \
	--description="URL for FEARLUS-G Service" \
	--arity=1 \
	--type=option \
	--range="absolute_URI" \
	)
[ -n $gridServiceURI_id ] || exit -1

gridModelDescription_id=$(SSREPI_argument \
	$PROG \
	gridModelDescription \
	--short_name="H" \
	--name="gridModelDescription" \
	--description="Description for this model" \
	--arity=1 \
	--type=option \
	--range="^\s+$" \
	)
[ -n $gridModelDescription_id ] || exit -1

javapath_id=$(SSREPI_argument \
	$PROG \
	javapath \
	--short_name="j" \
	--name="javapath" \
	--description="Path to java Grid Client" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $javapath_id ] || exit -1

rng_id=$(SSREPI_argument \
	$PROG \
	rng \
	--short_name="n" \
	--name="rng" \
	--description="Class of RNG to use" \
	--arity=1 \
	--type=option \
	--range="^\s+$" \
	)
[ -n $rng_id ] || exit -1

observers_id=$(SSREPI_argument \
	$PROG \
	observers \
	--short_name="o" \
	--name="observers" \
	--description="File for the observer settings to be loaded from" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $observers_id ] || exit -1

ontology_id=$(SSREPI_argument \
	$PROG \
	ontology \
	--short_name="O" \
	--name="ontology" \
	--description="Name of file to output ontology to" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $ontology_id ] || exit -1

parameters_id=$(SSREPI_argument \
	$PROG \
	parameters \
	--short_name="p" \
	--name="parameters" \
	--description="File for the model parameters to be loaded from" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $parameters_id ] || exit -1

report_id=$(SSREPI_argument \
	$PROG \
	report \
	--short_name="r" \
	--name="report" \
	--description="File to save the report to (stdout by default)" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $report_id ] || exit -1

repconfig_id=$(SSREPI_argument \
	$PROG \
	repconfig \
	--short_name="R" \
	--name="repconfig" \
	--description="Reporter configuration file" \
	--arity=1 \
	--type=option \
	--range="relative_ref" \
	)
[ -n $repconfig_id ] || exit -1

ontology_uri_id=$(SSREPI_argument \
	$PROG \
	ontology_uri \
	--short_name="U" \
	--name="ontology-uri=URI" \
	--description="URI for ontology" \
	--arity=1 \
	--type=option \
	--range="absolute_URI" \
	)
[ -n $ontology_uri_id ] || exit -1

withseed_id=$(SSREPI_argument \
	$PROG \
	withseed \
	--short_name="X" \
	--name="withseed" \
	--description="Specify the seed. [0-9]+, TIME or DEFAULT" \
	--arity=1 \
	--type=option \
	--range="^([0-9]+|TIME|DEFAULT)$" \
	)
[ -n $withseed_id ] || exit -1

postinitseed_id=$(SSREPI_argument \
	$PROG \
	postinitseed \
	--short_name="-Z" \
	--name="postinitseed" \
	--description="Specify a separate seed to use after initialisation: [0-9]+ or TIME" \
	--arity=1 \
	--type=option \
	--range="^([0-9]+|TIME)" \
	)
[ -n $postinitseed_id ] || exit -1

# Output types
# ------------

SSS_OUT_id=$(SSREPI_output $PROG \
	OUT \
	"[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].out")
[ -n "$SSS_OUT_id" ] || exit -1 

SSS_ERR_id=$(SSREPI_output $PROG \
	ERR \
	"[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].err")
[ -n "$SSS_ERR_id" ] || exit -1 

	
# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.txt
SSS_report_id=$(SSREPI_output $PROG \
	SSS_report \
	"SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].txt")
[ -n "$SSS_report_id" ] || exit -1 

# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.grd
SSS_report_grd_id=$(SSREPI_output $PROG \
	SSS_report_grd \
	"SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].grd")
[ -n "$SSS_report_grd_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-prop.csv
SSS_spomresult_prop_id=$(SSREPI_output $PROG \
	SSS_spomresult \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-prop.csv")
[ -n "$SSS_spomresult_prop_id" ] || exit -1 

#SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-nspp.csv
SSS_spomresult_nspp_id=$(SSREPI_output $PROG \
	SSS_spomresult_nspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_nspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-lspp.csv
SSS_spomresult_lspp_id=$(SSREPI_output $PROG \
	SSS_spomresult_lspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-lspp.csv")
[ -n "$SSS_spomresult_lspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-extinct.csv
SSS_spomresult_extinct_id=$(SSREPI_output $PROG \
	SSS_spomresult_extinct \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_extinct_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-pspp.csv
SSS_spomresult_pspp_id=$(SSREPI_output $PROG \
	SSS_spomresult_pspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-pspp.csv")
[ -n "$SSS_spomresult_pspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-habgrid.csv
SSS_spomresult_habgrid_id=$(SSREPI_output $PROG \
	SSS_spomresult_habgrid \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-habgrid.csv")
[ -n "$SSS_spomresult_habgrid_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-area.csv
SSS_spomresult_area_id=$(SSREPI_output $PROG \
	SSS_spomresult_area \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-area.csv")
[ -n "$SSS_spomresult_area_id" ] || exit -1 
wait
	
for govt in ClusterActivity RewardActivity RewardSpecies ClusterSpecies 
do
	for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
	do
        for market in flat var2
        do
            for sink in nosink
            do
                for rwd in 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
                do
                     for asp in 1.0 5.0
                     do
                          for bet in 25.0 30.0
                          do
                               for rat in 1.0 2.0 10.0
                               do
                                    DIR=Cluster2/SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_
                                    report=${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}
                                    param=SSS_top-level_${report}.model

                                    ARGS="""
                                    --SSREPI-argument-${batch_id}
                                    --SSREPI-argument-${varyseed_id}
                                    --SSREPI-argument-${repconfig_id}=SSS_report-config_${report}.repcfg
                                    --SSREPI-argument-${report_id}=SSS_report_${report}.txt
                                    --SSREPI-argument-${parameters_id}=$param
                                    """

                                    ARGS="""$ARGS
                                    --SSREPI-input-${SSS_economystate_id}=SSS_economystate______${market}_____.state 
                                    --SSREPI-input-${SSS_top_level_subpop_id}=SSS_top-level-subpop________noapproval_0_${asp}_.ssp 
                                    --SSREPI-input-${SSS_grid_id}=SSS_grid___________${run}.grd 
                                    --SSREPI-input-${SSS_top_level_id}=SSS_top-level_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.model 
                                    --SSREPI-input-${SSS_species_id}=SSS_species_${sink}__________.csv 
                                    --SSREPI-input-${SSS_subpop_id}=SSS_subpop________noapproval_0_${asp}_.sp 
                                    --SSREPI-input-${SSS_yieldtree_id}=SSS_yieldtree___________.tree 
                                    --SSREPI-input-${SSS_fearlus_id}=SSS_fearlus__${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.fearlus 
                                    --SSREPI-input-${SSS_government_id}=SSS_government__${govt}_all_${rwd}_${rat}______.gov 
                                    --SSREPI-input-${SSS_sink_id}=SSS_sink_${sink}__________.csv 
                                    --SSREPI-input-${SSS_incometree_id}=SSS_incometree______${market}_____.tree 
                                    --SSREPI-input-${SSS_luhab_id}=SSS_luhab___________.csv 
                                    --SSREPI-input-${SSS_climateprob_id}=SSS_climateprob___________.prob 
                                    --SSREPI-input-${SSS_patch_id}=SSS_patch_${sink}__________${run}.csv 
                                    --SSREPI-input-${SSS_report_config_id}=SSS_report-config_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.repcfg 
                                    --SSREPI-input-${SSS_yielddata_id}=SSS_yielddata___________.data 
                                    --SSREPI-input-${SSS_spom_id}=SSS_spom_${sink}__________${run}.spom 
                                    --SSREPI-input-${SSS_economyprob_id}=SSS_economyprob___________.prob    
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-1.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-2.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-3.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-4.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-5.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-6.csv 
                                    --SSREPI-input-${SSS_dummy_id}=SSS_dummy___________-7.csv 
                                    --SSREPI-input-${SSS_incomedata_id}=SSS_incomedata______${market}_____.data 
                                    --SSREPI-input-${SSS_event_id}=SSS_event________noapproval___.event 
                                    --SSREPI-input-${SSS_trigger_id}=SSS_trigger________noapproval___.trig 
                                    """

                                    ARGS="""$ARGS
                                    --SSREPI-stdout-${SSS_OUT_id}=${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.out
                                    --SSREPI-stderr-${SSS_ERR_id}=${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.err
                                    --SSREPI-output-${SSS_report_id}=SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.txt
                                    --SSREPI-output-${SSS_report_grd_id}=SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}.grd
                                    --SSREPI-output-${SSS_spomresult_prop_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-prop.csv
                                    --SSREPI-output-${SSS_spomresult_nspp_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-nspp.csv
                                    --SSREPI-output-${SSS_spomresult_lspp_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-lspp.csv
                                    --SSREPI-output-${SSS_spomresult_extinct_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-extinct.csv
                                    --SSREPI-output-${SSS_spomresult_pspp_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-pspp.csv
                                    --SSREPI-output-${SSS_spomresult_habgrid_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-habgrid.csv
                                    --SSREPI-output-${SSS_spomresult_area_id}=SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0_${asp}_${run}-area.csv
                                    """

                                    SSREPI_batch $PROG $ARGS --cwd=$DIR
                                    if [ -n "$test" ]
                                    then
                                        break 8
                                    fi
                            done
                        done
                    done
                done
            done
        done
	done
done                    

wait
echo $0: Ended.


