#!/bin/bash

# A temporary file to run the actual model

export PATH="bin:lib:/mnt/sge/bin:/mnt/sge/bin/lx-amd64:/usr/lib64/qt-3.3/bin:/usr/lib64/mpich/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/dell/srvadmin/bin:/home/ab/ds42723/.local/bin"

cd /mnt/storage/doug/SSS.2

. lib/ssrepi_lib.sh

# Set up process


THIS_PROCESS=$(SSREPI_process --executable=fearlus-1.1.5.2_spom-2.3) 

if SSREPI_fails_exact_requirement fearlus \
	$(/mnt/storage/doug/SSS.2/bin/fearlus-1.1.5.2_spom-2.3 --version | tail -1 | awk '{print $1}')
then
        (>&2 echo "$0: Exact requirement for Fearlus failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
	python 	$(python --version 2>&1 | cut -f2 -d' ')
then
        (>&2 echo "$0: Minimum requirement for Python failed")
        exit -1
fi

# Do not need to check the shell as the hashbang insists we are running
# under bash, so we just need to set the meets criterion.
SSREPI_meets shell

if SSREPI_fails_exact_requirement os $(uname)
then
        (>&2 echo "/mnt/storage/doug/SSS.2/bin/SSS-StopC2-Cluster-run.sh: Minimum requirement for the OS failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement disk_space \
	$(df -k . | tail -1 | awk '{print $1}')
then
        (>&2 echo "$0: Minimum requirement for disk space failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
	memory $(cat /proc/meminfo | grep MemTotal | awk '{print $2}')000
then
        (>&2 echo "$0: Minimum requirement for memory failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement \
	nof_cpus  $(($(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1) + 1))
then
        (>&2 echo "$0: Minimum requirement for number of cpus failed")
        exit -1
fi

# Argument Values (Provenance)
# ===============

SSREPI_argument_value $THIS_PROCESS batch
SSREPI_argument_value $THIS_PROCESS varyseed
SSREPI_argument_value $THIS_PROCESS $repconfig_idSSS_report-config_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.repcfg repconfig
SSREPI_argument_value $THIS_PROCESS SSS_report_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.txt report
SSREPI_argument_value $THIS_PROCESS SSS_top-level_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.model parameters

# Actual Inputs (Provenance)
# =============

SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS CWD SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_economystate SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_economystate______flat_____.state
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_top-level-subpop SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_top-level-subpop________noapproval_0.0_1.0_.ssp
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_grid SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_grid___________001.grd
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_top-level SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_top-level_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.model
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_species SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_species_nosink__________.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_subpop SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_subpop________noapproval_0.0_1.0_.sp
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_yieldtree SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_yieldtree___________.tree
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_fearlus SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_fearlus__ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.fearlus
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_government SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_government__ClusterActivity_all_1.0_1.0______.gov
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_sink SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_sink_nosink__________.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_incometree SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_incometree______flat_____.tree
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_luhab SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_luhab___________.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_climateprob SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_climateprob___________.prob
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_patch SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_patch_nosink__________001.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_report-config SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_report-config_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.repcfg
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_yielddata SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_yielddata___________.data
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spom SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spom_nosink__________001.spom
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_economyprob SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_economyprob___________.prob
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_incomedata SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_incomedata______flat_____.data
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_event SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_event________noapproval___.event
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_trigger SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_trigger________noapproval___.trig
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-1.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-2.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-3.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-4.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-5.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-6.csv
SSREPI_input SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_dummy SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_dummy___________-7.csv

# Running Fearlus

cd SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_ 

/mnt/storage/doug/SSS.2/bin/fearlus-1.1.5.2_spom-2.3 	-b 	-s 	-R SSS_report-config_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.repcfg 	-r SSS_report_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.txt 	-p SSS_top-level_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.model 		> nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.out 		2> nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.err

cd -

# Specific Outputs (Provenance)
# ================

SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS OUT SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.out
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS ERR SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.err
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_report SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_report_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.txt
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_report_grd SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_report_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001.grd
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-prop.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_nspp SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-nspp.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_lspp SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-lspp.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_extinct SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-extinct.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_pspp SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-pspp.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_habgrid SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-habgrid.csv
SSREPI_output SSS-StopC2-Cluster-run.sh $THIS_PROCESS SSS_spomresult_area SSS_dir_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_/SSS_spomresult_nosink_ClusterActivity_all_1.0_1.0_flat_25.0_noapproval_0.0_1.0_001-area.csv

# Tidy up process

THIS_PROCESS=$(SSREPI_process --executable=fearlus-1.1.5.2_spom-2.3 \
	--process_id=$THIS_PROCESS \
	--end_time=$(date +%Y%m%dT%H%M%S))

# Delete this command file and be all neat and tidy.

rm process.LreWT3lVIONBRCk64rDAevZVRbvmn8zH.sh
