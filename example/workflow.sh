#!/usr/bin/env bash

# A script which is trying to regenerate the data and consequently
# rerun the model for Gary's paper, automate the process and record
# lots and lots of metadata into a relational database, as a kind of
# diary for the model run.

# Author: Doug Salt

# Date: April 2017

date

. lib/ssrepi.sh

export SSREPI_NOF_CPUS=2

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

# People
# ======

gary_polhill_id=""
if [[ $(uname -s) == "Darwin" ]]
then
	gary_polhill_id=$(SSREPI_person \
		--id_person=gary_polhill \
		--name="Gary Polhill" \
		--email=gary.polhill@hutton.ac.uk \
	)
	doug_salt_id=$(SSREPI_person \
		--id_person=doug_salt \
		--name="Doug Salt" \
		--email=doug.salt@hutton.ac.uk \
	)
else
	gary_polhill_id=$(SSREPI_hutton_person gp40285)
	doug_salt_id=$(SSREPI_hutton_person ds42723)
fi

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

ME=$(SSREPI_application \
	--language=bash \
	--version=$VERSION \
	--licence=$LICENCE \
	--purpose="Overall workflow shell script" \
        --model=fearlus-spom)
[ -n "$ME" ] || exit -1

SSREPI_contributor $ME $doug_salt_id Developer
SSREPI_contributor $ME $doug_salt_id Author

# This sets the value of the study_id as a global variable, SSREPI_study and
# sets the GENERATED_BY variable to --generated_by=SSREPI_study which is used
# internally.

SSREPI_set --study=$study_id \
	--model=fearlus-spom \
	--licence=GPLv3 \
	--version=1.0 \

# Some metadata
# =============

paper_id=$(SSREPI_paper \
	'doc/Reconstructing the diagrams and results in Polhill et al.docx' \
	--held_by=$doug_salt_id \
	--sourced_from=$gary_polhill_id \
	--describes=$study_id \
	--date=20170414)

SSREPI_contributor "$paper_id" $gary_polhill_id Author

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
SSREPI_tag $mad_tag --person=$doug_salt_id
SSREPI_tag ancient --person=$doug_salt_id
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

#if SSREPI_require_exact $ME fearlus "fearlus-1.1.5.2_spom-2.3") \
#	$($(which fearlus-1.1.5.2_spom-2.3) --version | tail -1 | awk '{print $1}')
#then
#        (>&2 echo "$0: Minimum requirement for fearlus-spom binary failed")
#        (>&2 echo "$0: Required fearlus-1.1.5.2_spom-2.3 got " \
#		$($(which fearlus-1.1.5.2_spom-2.3) --version | tail -1 | awk '{print $1}'))
#        exit -1
#fi

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

SSREPI_call \
	SSS-StopC2-Cluster-create.sh \
	--purpose="

		Sets up the run for the lower value rewards
		and this is to test out multi-line,
		to see if it works. Which it does but removes the
		carriage returns and tabs. So you can nicely format it." \

SSREPI_call \
	SSS-StopC2-Cluster-create2.sh \
	--purpose="Sets up the run for the higher value rewards

		Add some documentary stuff here." \


SSREPI_invoke \
	SSS-StopC2-Cluster-run.sh \
	--purpose="Does the runs for the lower value rewards" \
	--add-to-dependencies=postprocessing.sh.dependencies \


SSREPI_invoke \
	SSS-StopC2-Cluster-run2.sh \
	--purpose="Does the runs for the higher value rewards" \
	--add-to-dependencies=postprocessing.sh.dependencies \


SSREPI_call \
	postprocessing.sh \
	--purpose="Post processing to almagamate results and produce pretty diagrams" \
	--with-dependencies=postprocessing.sh.dependencies \

SSREPI_study \
	--id_study=$study_id \
	--project=$project_id \
	--end_time=$(date "+%Y%m%dT%H%M%S") > /dev/null


