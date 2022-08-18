#!/bin/bash

# A script which is trying to regenerate the data and consequently
# rerun the model for Gary's paper, automate the process and record
# lots and lots of metadata into a relational database, as a kind of
# diary for the model run.

# Author: Doug Salt

# Date: April 2017

date

. lib/ssrepi.sh

export NOF_CPUS=2
export POST_DEPENDENCIES=/tmp/postprocessing.sh.dependencies
touch "$POST_DEPENDENCIES"
> "$POST_DEPENDENCIES"

# Global Identity
# ===============

project_id=$(SSREPI_project \
	--id_project=MIRACLE \
	--title="MIning Relationships Among variables in large datasets 
		from CompLEx systems

		Probably could do with a bit more explanation in here." \
	)
[ -n "$project_id" ] || exit -1

study_id=$(SSREPI_study \
	--id_study=$(next_study.py) \
	--project=$project_id \
	--start_time=$(date "+%Y-%m-%d") \
	--description="This is a run to reconstruct the diagrams 
			and results in Polhill et al. 2013.

			Originally we were going to use Python scripts to
			do the job control for us, but I have decided to remain
			with shell scripts, to try and preserve the original
			flavour. But these might be too slow." \
	--label="SSS-cluster2 reconstruction" \
)
[ -n "$study_id" ] || exit -1
SSREPI_set_study $study_id

# People
# ======

gary_polhill_id=$(SSREPI_hutton_person gp40285)
doug_salt_id=$(SSREPI_hutton_person ds42723)
lorenzo_milazzo_id=$(SSREPI_person \
	--id_person=lorenzo_milazzo \
	--name="Lorenzo Milazzo" \
	--email=lorenzo.milazzo@gmail.com \
	)


SSREPI_involvement $study_id $lorenzo_milazzo_id \
	"Original author of the metadata gathering program"

SSREPI_involvement $study_id $gary_polhill_id \
	"Original author"

SSREPI_involvement $study_id $doug_salt_id \
	"Implementor of the metadata gathering

	and creator of enormously long comments."

# Local Identity (particulars of this script)
# ==============

VERSION=1.0
LICENCE=GPLv3
ME=$(SSREPI_application \
	--language=bash \
	--version=$VERSION \
	--license=$LICENCE \
	--purpose="Overall workflow shell script" \
        --model=fearlus-spomm)
[ -n "$ME" ] || exit -1

SSREPI_contributor $ME $doug_salt_id Developer
SSREPI_contributor $ME $doug_salt_id Author

pipe=$(SSREPI_create_pipeline $ME)

# Some metadata
# =============

paper_id=$(SSREPI_paper \
	'doc/Reconstructing the diagrams and results in Polhill et al.docx' \
	--held_by=$doug_salt_id \
	--sourced_from=$gary_polhill_id \
	--describes=$study_id \
	--date=20170414)

SSREPI_contributor $paper_id $gary_polhill_id Author

# Folksonomy
# ==========

source_tag=$(SSREPI_make_tag source "This is a paper that is the source of the reproducibility.")
mad_tag=$(SSREPI_make_tag mad "Complete AWOL. About as useful as a chocolate teapot")
too_old_tag=$(SSREPI_make_tag ancient "Past it.")
frivilous_tag=$(SSREPI_make_tag frivilous "Rather silly.")
urgent_tag=$(SSREPI_make_tag urgent "Needs to be done yesterday.")
bad_syntax_tag=$(SSREPI_make_tag bad_syntax "The syntax in use in the script
	is still too awkward, and you have to be really in the zone to remember it, in 
	all its complexity. It is approaching some kind of language, but I am not sure 
	which kind.")
too_slow_tag=$(SSREPI_make_tag too_slow "This refers to the execution speed of a script or program.")

# Differing ways of accessing the key for an entity shown below. You can use a
# hardcoded key, or a variable containing the key. Much of a muchness.
# Throughout these scripts, I have tended to use variables.

SSREPI_tag $source_tag --documentation="$paper_id"
SSREPI_tag $mad_tag --person=ds42723
SSREPI_tag ancient --person=ds42723
SSREPI_tag urgent --study=$study_id
SSREPI_tag bad_syntax --application=$ME

# This is not a frivilous tag. It is actually too slow. If I haven't talked
# about this, once I have handed over then somebody should remind me.

SSREPI_tag too_slow --container_type=bash

# Tagging tags (or groups).

SSREPI_tag frivilous --tag=mad
SSREPI_tag frivilous --tag=$too_old


# Assumptions
# ===========

dougs_assumption=$(SSREPI_person_makes_assumption \
        $doug_salt_id dangerous 'Gary knows what he is doing. This is an example
of an assumption, which you might want to fill in....
...and could conceivably go over several lines.') 

garys_1st_assumption=$(SSREPI_person_makes_assumption $gary_polhill_id \
        insane "There are no bugs in this software.")
garys_2nd_assumption=$(SSREPI_person_makes_assumption $gary_polhill_id \
        likely "There are bugs in this software." )

# Requirements for this script
# ============================

# Software

required_perl=$(SSREPI_require_minimum perl  "5.0")
required_python=$(SSREPI_require_minimum python  "2.6.6")
required_fearlus=$(SSREPI_require_exact fearlus "fearlus-1.1.5.2_spom-2.3")
required_R=$(SSREPI_require_minimum "R" "3.3.1")
required_os=$(SSREPI_require_exact os Linux)
required_shell=$(SSREPI_require_exact shell '/bin/bash')

# Hardware

required_disk_space=$(SSREPI_require_minimum disk_space "20G")
required_nof_cpus=$(SSREPI_require_minimum nof_cpus $NOF_CPUS)
required_memory=$(SSREPI_require_minimum memory "4G")

if SSREPI_fails_minimum_requirement $required_perl $(perl -e 'print $];')
then
        (>&2 echo "$0: Minimum requirement for Perl failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_python \
	$(python --version 2>&1 | cut -f2 -d' ')
then
        (>&2 echo "$0: Minimum requirement for Python failed")
        (>&2 echo "$0: Required $python, got " \
		$(python --version 2>&1 | cut -f2 -d' '))
        exit -1
fi

# Don't need to check the shell as the hashbang insists we are running
# under bash, so we just need to set the meets criterion.
SSREPI_meets $required_shell

if SSREPI_fails_exact_requirement $required_os $(uname)
then
        (>&2 echo "$0: Minimum requirement for the OS failed")
        exit -1
fi

if SSREPI_fails_exact_requirement $required_fearlus \
	$($(which fearlus-1.1.5.2_spom-2.3) --version | tail -1 | awk '{print $1}')
then
        (>&2 echo "$0: Minimum requirement for fearlus-spom binary failed")
        exit -1
fi

if SSREPI_fails_minimum_requirement $required_R  \
	$(R --version | head -1 | awk '{print $3}')
then
        (>&2 echo "$0: Minimum requirement for R failed")
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

fuckyou=<< FUCKYOU
SHELL_SCRIPT_1=$(SSREPI_call_bash_script \
	$(which SSS-StopC2-Cluster-create.sh) \
	--purpose="

		Sets up the run for the lower value rewards
		and this is to test out multi-line,
		to see if it works. Which it does but removes the
		carriage returns and tabs. So you can nicely format it.")

[ -n "$SHELL_SCRIPT_1" ] || exit -1

pipe=$(SSREPI_add_pipeline_to_pipeline $pipe $SHELL_SCRIPT_1)
[ -n "$pipe" ] || exit -1

SHELL_SCRIPT_2=$(SSREPI_call_bash_script \
	$(which SSS-StopC2-Cluster-create2.sh) \
	--purpose="Sets up the run for the higher value rewards

		Add some documentary stuff here.")


[ -n "$SHELL_SCRIPT_2" ] || exit -1

pipe=$(SSREPI_add_pipeline_to_pipeline $pipe $SHELL_SCRIPT_2)
[ -n "$pipe" ] || exit -1
FUCKYOU

SHELL_SCRIPT_3=$(SSREPI_call_bash_script \
	$(which SSS-StopC2-Cluster-run.sh) \
	--purpose="Does the runs for the lower value rewards")

[ -n "$SHELL_SCRIPT_3" ] || exit -1

pipe=$(SSREPI_add_pipeline_to_pipeline $pipe $SHELL_SCRIPT_3)
[ -n "$pipe" ] || exit -1

SHELL_SCRIPT_4=$(SSREPI_call_bash_script \
	$(which SSS-StopC2-Cluster-run2.sh) \
	--purpose="Does the runs for the higher value rewards")

[ -n "$SHELL_SCRIPT_4" ] || exit -1

pipe=$(SSREPI_add_pipeline_to_pipeline $pipe $SHELL_SCRIPT_4)
[ -n "$pipe" ] || exit -1

SHELL_SCRIPT_5=$(SSREPI_call_bash_script_with_dependency \
	$(which postprocessing.sh) \
	"$POST_DEPENDENCIES" \
	--purpose="Post processing to almagamate results and produce pretty diagrams")

[ -n "$SHELL_SCRIPT_5" ] || exit -1

pipe=$(SSREPI_add_pipeline_to_pipeline $pipe $SHELL_SCRIPT_5)
[ -n "$pipe" ] || exit -1

SSREPI_study \
	--id_study=$study_id \
	--project=$project_id \
	--end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null


