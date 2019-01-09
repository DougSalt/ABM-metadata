#!/bin/bash

# Shell script to run the SSS experiments

# Author: Doug Salt

# Date: January 2017

. lib/ssrepi_lib.sh

if [[ -z $POST_DEPENDENCIES ]]
then
        # Do not put this, or anything else in the /tmp directory (as I was
        # doing before), because (dur), the /tmp directory is not shared across
        # machines, so should be left in the current working directory.

	export POST_DEPENDENCIES=postprocessing.sh.dependencies
fi

count=0
declare -a runcmd

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

ME=$(basename $(_calling_script))

SSREPI_contributor $ME gp40285 Author
SSREPI_contributor $ME ds42723 Author

next=$(SSREPI_create_pipeline $ME)
[ -n "$next" ] || exit -1

PROG=$(SSREPI_call_elf $FEARLUS)
[ -n $PROG ] || exit -1

SSREPI_contributor $PROG gp40285 Author

next=$(SSREPI_add_application_to_pipeline $next $PROG)
[ -n "$next" ] || exit -1

SSREPI_contributor $PROG gp40285 Author

# Requirements for this script
# ============================

# Software

required_python=$(SSREPI_require_minimum python  "2.6.6" "$PROG")
required_os=$(SSREPI_require_exact os Linux "$PROG")
required_shell=$(SSREPI_require_exact shell '/bin/bash' "$PROG")
required_fearlus=$(SSREPI_require_exact fearlus "fearlus-1.1.5.2_spom-2.3" "$PROG")

# Hardware

required_disk_space=$(SSREPI_require_minimum disk_space "20G" "$PROG")
required_nof_cpus=$(SSREPI_require_minimum nof_cpus $NOF_CPUS "$PROG")
required_memory=$(SSREPI_require_minimum memory "4G" "$PROG")

# Inputs Types
# ------------

SSS_economystate_id=$(SSREPI_input_type $ME \
	SSS_economystate \
	"______[^_]+_____.state")
[ -n "$SSS_economystate_id" ] || exit -1 

SSS_top_level_subpop_id=$(SSREPI_input_type $ME \
	SSS_top-level-subpop \
	"________[^_]+_[^_]+_[^_]+_.ssp")
[ -n "$SSS_top_level_subpop_id" ] || exit -1 

SSS_grid_id=$(SSREPI_input_type $ME \
	SSS_grid \
	"___________[^_]+.grd")
[ -n "$SSS_grid_id" ] || exit -1 

SSS_top_level_id=$(SSREPI_input_type $ME \
	SSS_top-level \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.model")
[ -n "$SSS_top_level_id" ] || exit -1 

SSS_species_id=$(SSREPI_input_type $ME \
	SSS_species \
	"_[^_]+__________.csv")
[ -n "$SSS_species_id" ] || exit -1 

SSS_subpop_id=$(SSREPI_input_type $ME \
	SSS_subpop \
	"________[^_]+_[^_]+_[^_]+_.sp")
[ -n "$SSS_subpop_id" ] || exit -1 

SSS_yieldtree_id=$(SSREPI_input_type $ME \
	SSS_yieldtree \
	"___________.tree")
[ -n "$SSS_yieldtree_id" ] || exit -1 

SSS_fearlus_id=$(SSREPI_input_type $ME \
	SSS_fearlus \
	"__[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.fearlus")
[ -n "$SSS_fearlus_id" ] || exit -1 

SSS_government_id=$(SSREPI_input_type $ME \
	SSS_government \
	"__[^_]+_[^_]+_[^_]+_[^_]+______.gov")
[ -n "$SSS_government_id" ] || exit -1 

SSS_sink_id=$(SSREPI_input_type $ME \
	SSS_sink \
	"_[^_]+__________.csv")
[ -n "$SSS_sink_id" ] || exit -1 

SSS_incometree_id=$(SSREPI_input_type $ME \
	SSS_incometree \
	"______[^_]+_____.tree")
[ -n "$SSS_incometree_id" ] || exit -1 

SSS_luhab_id=$(SSREPI_input_type $ME \
	SSS_luhab \
	"___________.csv")
[ -n "$SSS_luhab_id" ] || exit -1 

SSS_climateprob_id=$(SSREPI_input_type $ME \
	SSS_climateprob \
	"___________.prob")
[ -n "$SSS_climateprob_id" ] || exit -1 

SSS_patch_id=$(SSREPI_input_type $ME \
	SSS_patch \
	"_[^_]+__________[^_]+.csv")
[ -n "$SSS_patch_id" ] || exit -1 

SSS_report_config_id=$(SSREPI_input_type $ME \
	SSS_report-config \
	"_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+.repcfg")
[ -n "$SSS_report_config_id" ] || exit -1 

SSS_yielddata_id=$(SSREPI_input_type $ME \
	SSS_yielddata \
	"___________.data")
[ -n "$SSS_yielddata_id" ] || exit -1 

SSS_spom_id=$(SSREPI_input_type $ME \
	SSS_spom \
	"_[^_]+__________[^_]+.spom")
[ -n "$SSS_spom_id" ] || exit -1 

SSS_economyprob_id=$(SSREPI_input_type $ME \
	SSS_economyprob \
	"___________.prob")
[ -n "$SSS_economyprob_id" ] || exit -1 

SSS_dummy_id=$(SSREPI_input_type $ME \
	SSS_dummy \
	"___________[^_]+.csv")
[ -n "$SSS_dummy_id" ] || exit -1 

SSS_incomedata_id=$(SSREPI_input_type $ME \
	SSS_incomedata \
	"______[^_]+_____.data")
[ -n "$SSS_incomedata_id" ] || exit -1 

SSS_event_id=$(SSREPI_input_type $ME \
	SSS_event \
	"________[^_]+___.event")
[ -n "$SSS_event_id" ] || exit -1 

SSS_trigger_id=$(SSREPI_input_type $ME \
	SSS_trigger \
	"________[^_]+___.trig")
[ -n "$SSS_trigger_id" ] || exit -1 

SSS_CWD_id=$(SSREPI_working_directory $ME \
	"SSS__dir_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_")
[ -n "$SSS_CWD_id" ] || exit -1 
 

# Arguments
# ---------

batch_id=$(SSREPI_argument \
        --id_argument=batch \
        --description="Run in batch mode" \
        --application=$(basename $FEARLUS) \
        --name="--batch" \
	--short_name="-b" \
        --type=flag \
        --arity=0 \
	)
[ -n $batch_id ] || exit -1

varyseed_id=$(SSREPI_argument \
        --id_argument=varyseed \
        --application=$(basename $FEARLUS) \
  	--short_name="-s" \
	--name="--varyseed" \
        --description="Select random number seed from current time" \
        --type=flag \
        --arity=0 \
	)
[ -n $varyseed_id ] || exit -1

show_current_time_id=$(SSREPI_argument \
        --id_argument=show_current_time \
        --application=$(basename $FEARLUS) \
  	--short_name="-t" \
	--name="--show-current-time" \
	--description="Show current time in control panel" \
        --type=flag \
        --arity=0 \
	)
[ -n $show_current_time_id ] || exit -1

no_init_file_id=$(SSREPI_argument \
        --id_argument=no_init_file \
        --application=$(basename $FEARLUS) \
      	--name="--no-init-file" \
  	--description="Inhibit loading of ~/.swarmArchiver" \
        --type=flag \
        --arity=0 \
	)
[ -n $no_init_file_id ] || exit -1

verbose_id=$(SSREPI_argument \
        --id_argument=verbose \
        --application=$(basename $FEARLUS) \
  	--short_name="-v" \
	--name="--verbose" \
        --description="Activate verbose messages" \
        --type=flag \
        --arity=0 \
	)
[ -n $verbose_id ] || exit -1

append_report_id=$(SSREPI_argument \
        --id_argument=append_report \
        --application=$(basename $FEARLUS) \
  	--short_name="-a" \
	--name="--append-report" \
        --type=flag \
        --arity=0 \
	--description="If report file exists, then append to it" \
	)
[ -n $append_report_id ] || exit -1

ontology_all_years_id=$(SSREPI_argument \
        --id_argument=ontology_all_years \
        --application=$(basename $FEARLUS) \
  	--short_name="-A" \
	--name="--ontology-all-years" \
  	--description="Output a model state ontology each year (warning:" \
        --type=flag \
        --arity=0 \
	)
[ -n $ontology_all_years_id ] || exit -1

conditions_id=$(SSREPI_argument \
        --id_argument=conditions \
        --application=$(basename $FEARLUS) \
  	--short_name="-c" \
	--name="--conditions" \
	--description="Show conditions of redistribution" \
        --type=flag \
        --arity=0 \
	)
[ -n $conditions_id ] || exit -1

warranty_id=$(SSREPI_argument \
        --id_argument=warranty \
        --application=$(basename $FEARLUS) \
  	--short_name="-w" \
	--name="--warranty" \
	--description="Show warranty information" \
        --type=flag \
        --arity=0 \
	)
[ -n $waranty_id ] || exit -1

help_id=$(SSREPI_argument \
        --id_argument=help \
        --application=$(basename $FEARLUS) \
  	--short_name="-?" \
	--name="--help" \
        --description="Give this help list" \
        --type=flag \
        --arity=0 \
	)
[ -n $help_id ] || exit -1

usage_id=$(SSREPI_argument \
        --id_argument=usage \
        --application=$(basename $FEARLUS) \
      	--name="--usage" \
	--description="Give a short usage message" \
        --type=flag \
        --arity=0 \
	)
[ -n $usage_id ] || exit -1

version_id=$(SSREPI_argument \
        --id_argument=version \
        --application=$(basename $FEARLUS) \
  	--short_name="-V" \
	--name="--version" \
        --description="Print program version" \
        --type=flag \
        --arity=0 \
	)
[ -n $version_id ] || exit -1

seed_id=$(SSREPI_argument \
        --id_argument=seed \
        --application=$(basename $FEARLUS) \
  	--short_name="-S" \
  	--short_name_separator=" " \
	--name="--seed" \
	--separator="=" \
        --description="Specify seed for random numbers" \
        --arity=1 \
	--range="[0-9]+" \
        --type=option \
	)
[ -n $seed_id ] || exit -1

mode_id=$(SSREPI_argument \
        --id_argument=mode \
        --application=$(basename $FEARLUS) \
  	--short_name="-m" \
  	--short_name_separator=" " \
	--name="--mode" \
	--separator="=" \
        --description="Specify mode of use (for archiving) will potentially require a lot of disk space)" \
        --arity=1 \
        --type=option \
	--range="^\s+" \
	)
[ -n $mode_id ] || exit -1
	

ontology_class_id=$(SSREPI_argument \
        --id_argument=ontology_class \
        --application=$(basename $FEARLUS) \
  	--short_name="-C" \
  	--short_name_separator=" " \
	--name="--ontology-class" \
	--separator="=" \
	--description="Record structural ontology from subclasses of CLASS" \
        --arity=1 \
        --type=option \
	--range="^\s+" \
	)
[ -n $class_id ] || exit -1

debug_id=$(SSREPI_argument \
        --id_argument=debug \
        --application=$(basename $FEARLUS) \
  	--short_name="-D" \
  	--short_name_separator=" " \
	--name="--debug=" \
	--separator="=" \
        --description="Debug level (integer) and/or a list of +/- separated message symbols" \
        --arity=1 \
        --type=option \
	--range="^\s+((\+|\-)\s+)?$" \
	)
[ -n $debug_id ] || exit -1

gridServiceUID_id=$(SSREPI_argument \
        --id_argument=gridServiceUID \
        --application=$(basename $FEARLUS) \
  	--short_name="-g" \
  	--short_name_separator=" " \
	--name="--gridServiceUID=GRIDUSERID" \
	--separator="=" \
	--description="User ID for FEARLUS-G Service" \
        --arity=1 \
        --type=option \
	--range="^\s+" \
	)
[ -n $gridServiceUID_id ] || exit -1

gridServiceURL_id=$(SSREPI_argument \
        --id_argument=gridServiceURL \
        --application=$(basename $FEARLUS) \
  	--short_name="-G" \
  	--short_name_separator=" " \
	--name="--gridServiceURL=GRIDURL" \
	--separator="=" \
        --description="URL for FEARLUS-G Service" \
        --arity=1 \
        --type=option \
	--range="absolute_URI" \
	)
[ -n $gridServiceURI_id ] || exit -1

gridModelDescription_id=$(SSREPI_argument \
        --id_argument=gridModelDescription \
        --application=$(basename $FEARLUS) \
  	--short_name="-H" \
  	--short_name_separator=" " \
	--name="--gridModelDescription" \
	--separator="=" \
	--description="Description for this model" \
        --arity=1 \
        --type=option \
	--range="^\s+$" \
	)
[ -n $gridModelDescription_id ] || exit -1

javapath_id=$(SSREPI_argument \
        --id_argument=javapath \
        --application=$(basename $FEARLUS) \
  	--short_name="-j" \
  	--short_name_separator=" " \
	--name="--javapath=" \
	--separator="=" \
	--description="Path to java Grid Client" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $javapath_id ] || exit -1

rng_id=$(SSREPI_argument \
        --id_argument=rng \
        --application=$(basename $FEARLUS) \
  	--short_name="-n" \
  	--short_name_separator=" " \
	--name="--rng=" \
	--separator="=" \
	--description="Class of RNG to use" \
        --arity=1 \
        --type=option \
	--range="^\s+$" \
	)
[ -n $rng_id ] || exit -1

observers_id=$(SSREPI_argument \
        --id_argument=observers \
        --application=$(basename $FEARLUS) \
  	--short_name="-o" \
  	--short_name_separator=" " \
	--name="--observers" \
	--separator="=" \
	--description="File for the observer settings to be loaded from" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $observers_id ] || exit -1

ontology_id=$(SSREPI_argument \
        --id_argument=ontology \
        --application=$(basename $FEARLUS) \
  	--short_name="-O" \
  	--short_name_separator=" " \
	--name="--ontology" \
	--separator="=" \
        --description="Name of file to output ontology to" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $ontology_id ] || exit -1

parameters_id=$(SSREPI_argument \
        --id_argument=parameters \
        --application=$(basename $FEARLUS) \
  	--short_name="-p" \
  	--short_name_separator=" " \
	--name="--parameters=PARAMETERFILE" \
	--separator="=" \
	--description="File for the model parameters to be loaded from" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $parameters_id ] || exit -1

report_id=$(SSREPI_argument \
        --id_argument=report \
        --application=$(basename $FEARLUS) \
  	--short_name="-r" \
  	--short_name_separator=" " \
	--name="--report=" \
	--separator="=" \
        --description="File to save the report to (stdout by default)" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $report_id ] || exit -1

repconfig_id=$(SSREPI_argument \
        --id_argument=repconfig \
        --application=$(basename $FEARLUS) \
  	--short_name="-R" \
  	--short_name_separator=" " \
	--name="--repconfig" \
	--separator="=" \
	--description="Reporter configuration file" \
        --arity=1 \
        --type=option \
	--range="relative_ref" \
	)
[ -n $repconfig_id ] || exit -1

ontology_uri_id=$(SSREPI_argument \
        --id_argument=ontology_uri \
        --application=$(basename $FEARLUS) \
  	--short_name="-U" \
  	--short_name_separator=" " \
	--name="--ontology-uri=URI" \
	--separator="=" \
        --description="URI for ontology" \
        --arity=1 \
        --type=option \
	--range="absolute_URI" \
	)
[ -n $ontology_uri_id ] || exit -1

withseed_id=$(SSREPI_argument \
        --id_argument=withseed \
        --application=$(basename $FEARLUS) \
  	--short_name="-X" \
  	--short_name_separator=" " \
	--name="--withseed=SEED" \
	--separator="=" \
        --description="Specify the seed. [0-9]+, TIME or DEFAULT" \
        --arity=1 \
        --type=option \
	--range="^([0-9]+|TIME|DEFAULT)$" \
	)
[ -n $withseed_id ] || exit -1

postinitseed_id=$(SSREPI_argument \
        --id_argument=postinitseed \
        --application=$(basename $FEARLUS) \
  	--short_name="-Z" \
  	--short_name_separator=" " \
        --name="--postinitseed=POSTINITSEED" \
	--separator="=" \
	--description="Specify a separate seed to use after initialisation: [0-9]+ or TIME" \
        --arity=1 \
        --type=option \
	--range="^([0-9]+|TIME)" \
	)
[ -n $postinitseed_id ] || exit -1

# Output types
# ------------

SSS_OUT_id=$(SSREPI_output_type $ME \
	OUT \
	"[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].out")
[ -n "$SSS_OUT_id" ] || exit -1 

SSS_ERR_id=$(SSREPI_output_type $ME \
	ERR \
	"[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].err")
[ -n "$SSS_ERR_id" ] || exit -1 

 
# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.txt
SSS_report_id=$(SSREPI_output_type $ME \
	SSS_report \
	"SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].txt")
[ -n "$SSS_report_id" ] || exit -1 

# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.grd
SSS_report_grd_id=$(SSREPI_output_type $ME \
	SSS_report_grd \
	"SSS_report_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_].grd")
[ -n "$SSS_report_grd_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-prop.csv
SSS_spomresult_prop_id=$(SSREPI_output_type $ME \
	SSS_spomresult \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-prop.csv")
[ -n "$SSS_spomresult_prop_id" ] || exit -1 

#SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-nspp.csv
SSS_spomresult_nspp_id=$(SSREPI_output_type $ME \
	SSS_spomresult_nspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_nspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-lspp.csv
SSS_spomresult_lspp_id=$(SSREPI_output_type $ME \
	SSS_spomresult_lspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-lspp.csv")
[ -n "$SSS_spomresult_lspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-extinct.csv
SSS_spomresult_extinct_id=$(SSREPI_output_type $ME \
	SSS_spomresult_extinct \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-nspp.csv")
[ -n "$SSS_spomresult_extinct_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-pspp.csv
SSS_spomresult_pspp_id=$(SSREPI_output_type $ME \
	SSS_spomresult_pspp \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-pspp.csv")
[ -n "$SSS_spomresult_pspp_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-habgrid.csv
SSS_spomresult_habgrid_id=$(SSREPI_output_type $ME \
	SSS_spomresult_habgrid \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-habgrid.csv")
[ -n "$SSS_spomresult_habgrid_id" ] || exit -1 

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-area.csv
SSS_spomresult_area_id=$(SSREPI_output_type $ME \
	SSS_spomresult_area \
	"SSS_spomresult_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]+_[^_]-area.csv")
[ -n "$SSS_spomresult_area_id" ] || exit -1 


for govt in RewardActivity RewardSpecies 
do
  for run in 001 
#  for run in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020
  do
    for market in flat var2
    do
      for sink in nosink
      do
	for rwd in 15.0 20.0 25.0 30.0 40.0 50.0 100.0
	do
	  for asp in 1.0 5.0
	  do
            for bet in 25.0 30.0
	    do
	      for rat in 1.0
	      do

			DIR=SSS_dir_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_
			report=${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}
			param=SSS_top-level_${report}.model
			tmp=process.$(uniq).sh
	        	runcmd[$count]=$tmp

			cat > $tmp << CMD
#!/bin/bash

# A temporary file to run the actual model

export PATH="$PATH"

cd $PWD

CMD

			cat >> $tmp << 'START'
. lib/ssrepi_lib.sh

# Set up process


START
			echo 'THIS_PROCESS=$(SSREPI_process --executable='$PROG') ' \
				>> $tmp
echo "
if SSREPI_fails_exact_requirement $required_fearlus \\" \
				>> $tmp
echo '	$('$FEARLUS' --version | tail -1 | awk '"'{print "'$1'"}')" \
				>> $tmp
			cat >> $tmp << 'REQ1'
then
        (>&2 echo "$0: Exact requirement for Fearlus failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
REQ1
			echo -n "	$required_python " >> $tmp

			cat >> $tmp << 'REQ2' 
	$(python --version 2>&1 | cut -f2 -d' ')
then
        (>&2 echo "$0: Minimum requirement for Python failed")
        exit -1
fi
REQ2

echo "" \
                        >> $tmp
echo "# Do not need to check the shell as the hashbang insists we are running" \
                        >> $tmp
echo "# under bash, so we just need to set the meets criterion." \
                        >> $tmp
echo "SSREPI_meets $required_shell" \
                        >> $tmp
echo "" \
                        >> $tmp

echo "if SSREPI_fails_exact_requirement $required_os "'$(uname)' \
			>> $tmp
			cat >> $tmp << REQ4
then
        (>&2 echo "$0: Exact requirement for the OS failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_disk_space \\
REQ4

			cat >> $tmp << 'REQ5' 
	$(df -k . | tail -1 | awk '{print $1}')
then
        (>&2 echo "$0: Minimum requirement for disk space failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
REQ5
			echo -n "	$required_memory" >> $tmp
			cat >> $tmp << 'REQ6' 
 $(cat /proc/meminfo | grep MemTotal | awk '{print $2}')000
then
        (>&2 echo "$0: Minimum requirement for memory failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
REQ6
			echo -n "	$required_nof_cpus " >> $tmp
			cat >> $tmp << 'REQ7' 
 $(($(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1) + 1))
then
        (>&2 echo "$0: Minimum requirement for number of cpus failed")
        exit -1
fi

# Argument Values (Provenance)
# ===============

REQ7

echo 'SSREPI_argument_value $THIS_PROCESS '$batch_id >> $tmp
echo 'SSREPI_argument_value $THIS_PROCESS '$varyseed_id  >> $tmp
echo 'SSREPI_argument_value $THIS_PROCESS $repconfig_id'SSS_report-config_${report}.repcfg $repconfig_id  >> $tmp
echo 'SSREPI_argument_value $THIS_PROCESS 'SSS_report_${report}.txt $report_id  >> $tmp
echo 'SSREPI_argument_value $THIS_PROCESS '$param $parameters_id  >> $tmp

echo '' >> $tmp
echo '# Actual Inputs (Provenance)' >> $tmp
echo '# =============' >> $tmp
echo '' >> $tmp

echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_CWD_id $DIR >> $tmp 

echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_economystate_id \
	$DIR/SSS_economystate______${market}_____.state >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_top_level_subpop_id \
	$DIR/SSS_top-level-subpop________noapproval_0.0_${asp}_.ssp >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_grid_id \
	$DIR/SSS_grid___________${run}.grd >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_top_level_id \
	$DIR/SSS_top-level_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.model >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_species_id \
	$DIR/SSS_species_${sink}__________.csv >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_subpop_id \
	$DIR/SSS_subpop________noapproval_0.0_${asp}_.sp >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_yieldtree_id \
	$DIR/SSS_yieldtree___________.tree >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_fearlus_id \
	$DIR/SSS_fearlus__${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.fearlus >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_government_id \
	$DIR/SSS_government__${govt}_all_${rwd}_${rat}______.gov >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_sink_id \
	$DIR/SSS_sink_${sink}__________.csv >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_incometree_id \
	$DIR/SSS_incometree______${market}_____.tree >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_luhab_id \
	$DIR/SSS_luhab___________.csv >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_climateprob_id \
	$DIR/SSS_climateprob___________.prob >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_patch_id \
	$DIR/SSS_patch_${sink}__________${run}.csv >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_report_config_id \
	$DIR/SSS_report-config_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.repcfg >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_yielddata_id \
	$DIR/SSS_yielddata___________.data >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_spom_id \
	$DIR/SSS_spom_${sink}__________${run}.spom >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_economyprob_id \
	$DIR/SSS_economyprob___________.prob >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_incomedata_id \
	$DIR/SSS_incomedata______${market}_____.data >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_event_id \
	$DIR/SSS_event________noapproval___.event >> $tmp
echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_trigger_id \
	$DIR/SSS_trigger________noapproval___.trig >> $tmp
for i in -1 -2 -3 -4 -5 -6 -7
do
	echo 'SSREPI_input '$ME' $THIS_PROCESS '$SSS_dummy_id \
		$DIR/SSS_dummy___________${i}.csv >> $tmp
done

			cat >> $tmp << PART2 

PART2

			cat ->> $tmp << REQ0 
# Running Fearlus

cd ${DIR} 

$FEARLUS \
	-b \
	-s \
	-R SSS_report-config_${report}.repcfg \
	-r SSS_report_${report}.txt \
	-p $param \
		> ${report}.out \
		2> ${report}.err

cd -

# Specific Outputs (Provenance)
# ================

REQ0

echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_OUT_id \
	$DIR/${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.out >> $tmp \
	>> $tmp

echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_ERR_id \
	$DIR/${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.err >> $tmp \
	>> $tmp

# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.txt
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_report_id \
	"$DIR/SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.txt" \
	>> $tmp

# SSS_report_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001.grd
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_report_grd_id \
	"$DIR/SSS_report_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}.grd" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-prop.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_prop_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-prop.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-nspp.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_nspp_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-nspp.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-lspp.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_lspp_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-lspp.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-extinct.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_extinct_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-extinct.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-pspp.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_pspp_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-pspp.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-habgrid.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_habgrid_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-habgrid.csv" \
	>> $tmp

# SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_var2_25.0_noapproval_0.0_1.0_001-area.csv
echo 'SSREPI_output '$ME' $THIS_PROCESS '$SSS_spomresult_area_id \
	"$DIR/SSS_spomresult_${sink}_${govt}_all_${rwd}_${rat}_${market}_${bet}_noapproval_0.0_${asp}_${run}-area.csv" \
	>> $tmp


			cat >> $tmp << 'END' 

# Tidy up process

END
echo 'THIS_PROCESS=$(SSREPI_process --executable='$PROG' \' \
				>> $tmp
echo '	--process_id=$THIS_PROCESS \' \
				>> $tmp
echo '	--end_time=$(date '+%Y%m%dT%H%M%S'))' \
				>> $tmp

			cat >> $tmp << DELETE 

# Delete this command file and be all neat and tidy.

rm $tmp
DELETE

	        count=$(($count + 1))
	      done
	    done
	  done
	done
      done
    done
  done
done

date
SSREPI_run $runcmd

