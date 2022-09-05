#!/usr/bin/env bash

# A series of functions to update ssrep.db with an actual run. 

# I have decided to do this in the bash script

# Remember because this is in-line, exit causes a stop program, return to abort
# to calling program.

export NOF_CPUS=2
export SSREP_DBNAME="$PWD"/ssrep.db

if which create_database.py >/dev/null 2>&1
then
	create_database.py
else
	(>&2 echo "No ssrepi python functions available. 
		Have you set the PATH variable correct?")
	exit -1
fi


SSREPI_require_minimum() {
	# $1 - executable
	# $2 - desired version literal
	# $3 - actual version literal
	# $4 - calling script (optional)
	PARENT_COMMAND=$(basename $(_parent_script))
	if [ -n "$4" ]
	then
		PARENT_COMMAND=$(basename "$4")
	fi
	computer_id=$(update.py \
		--table=Computer \
		--id_computer=$(hostname) \
		--name=$(hostname) \
		--host_id=$(_fqdn) \
		--ip_address=$(_ip_address) \
		--mac_address=$(_mac_address) \
	)
	[ -n "$computer_id" ] || exit -1
	specification_id=$(update.py \
		--table=Specification \
		--id_specification=$1 \
		--specification_of=$computer_id \
		--value="$2" \
	)	
	[ -n "$specification_id" ] || exit -1
	requirement_id=$(update.py \
		--table=Requirement \
		--minimum=$specification_id \
		--application=$PARENT_COMMAND \
	)		
	[ -n "$requirement_id" ] || exit -1
	if echo $2 | egrep -q "^[0-9]+(\.[0-9]+)?$" && \
	   echo $3 | egrep -q "^[0-9]+(\.[0-9]+)?$"
	then 
	     	if (( $(echo $2'>'$3 | bc -lq 2>/dev/null) ))
	     	then
			return 0
		fi
	elif [[ "$2" > "$3" ]]
	then
		return 0
	fi
	meets_id=$(update.py \
		--table=Meets \
		--computer_specification=$computer_id \
		--requirement_specification=$specification_id \
	)
	[ -n "$meets_id" ] || exit -1
	return 1
}

SSREPI_require_exact() {
	# $1 - executable
	# $2 - desired version literal
	# $3 - actual version literal
	# $4 - calling script (optional)
	PARENT_COMMAND=$(basename $(_parent_script))
	if [ -n "$4" ]
	then
		PARENT_COMMAND=$(basename "$4")
	fi
	computer_id=$(update.py \
		--table=Computer \
		--id_computer=$(hostname) \
		--name=$(hostname) \
		--host_id=$(_fqdn) \
		--ip_address=$(_ip_address) \
		--mac_address=$(_mac_address) \
	)
	[ -n "$computer_id" ] || exit -1
	specification_id=$(update.py \
		--table=Specification \
		--id_specification=$1 \
		--specification_of=$computer_id \
		--value="$2" \
	)	
	[ -n "$specification_id" ] || exit -1
	requirement_id=$(update.py \
		--table=Requirement \
		--exact=$specification_id \
		--application=$PARENT_COMMAND \
	)		
	[ -n "$requirement_id" ] || exit -1
	if [[ "$2" != "$3" ]]
	then
		return 0
	fi
	meets_id=$(update.py \
		--table=Meets \
		--computer_specification=$computer_id \
		--requirement_specification=$specification_id \
	)
	[ -n "$meets_id" ] || exit -1
	return 1
}

SSREPI_process() {
	process_id=
	EXEC=
	if [[ "$@" != *--executable* ]]
	then
		EXEC="--executable="$(basename $0)
	else
		EXEC=''
	fi
	if [[ "$@" == *--id_process* ]]
	then
   		process_id=$(update.py \
			--table=Process \
			$@ \
			)
	else
		NAME=$(_getent passwd $USER | cut -f 5 -d:) 
		person_id=$(update.py \
			--table=Person \
			--email=$USER@$(hostname) \
			--id_person=$USER \
			--name="$NAME" \
			)
		[ -n "$person_id" ] || exit -1

		user_id=$(update.py \
			--table=User \
			--home_dir=$HOME \
			--account_of=$person_id \
			--id_user=$USER \
			)
		[ -n "$user_id" ] || exit -1

		process_id=$(update.py \
			--table=Process \
			--id_process=process.$(uniq) \
			--some_user=$USER \
			--start_time=$(date "+%Y%m%dT%H%M%S") \
			--working_dir=$PWD \
			--host=$(hostname) \
			$EXEC $@)
		[ -n "$process_id" ] || exit -1
		

		computer_id=$(update.py \
			--table=Computer \
			--id_computer=$(hostname) \
			--name=$(hostname) \
			--host_id=$(_fqdn) \
			--ip_address=$(_ip_address) \
			--mac_address=$(_mac_address) \
		)
		[ -n "$computer_id" ] || exit -1
	fi
	echo $process_id
}

SSREPI_application() {
	# $1 - executable
	# Free form except for --instance  which gets deleted as a prefix and
	# used to update the container and --model which is also deleted and
	# used to update the model entry.

	APP=$(which "$1" 2>/dev/null)
	if [[ ! -f "$APP" ]]
	then
		APP=$(which $0)
	else
		shift
	fi

	PARAMS=$@

	model_id=
	if [[ "$@" == *--model=* ]]
	then	
		MODEL=$(echo "$PARAMS" | egrep -s "model=" | \
			sed "s/^.*--model=\([^ ][^ ]*\).*$/\1/")
		
		model_id=$(update.py \
			--table=Model\
			--id_model=$MODEL
			)
		[ -n "$model_id" ] || exit -1
	fi

	if [[ "$PARAMS" == *--instance=* ]]
	then
		INSTANCE=$(echo "$PARAMS" | egrep -s "instance=" | \
			sed "s/^.*\(--instance=[^ ][^ ]*\).*$/\1/")
		PARAMS=$(echo "$PARAMS" | egrep -s "instance=" | \
			sed "s/--instance=[^ ][^ ]* *//")
	fi

	container_id=$(update.py \
		--table=Container \
		--id_container=$(basename $(which $APP)) \
		--location_value=$(which $APP) \
		--location_type="relative_ref" \
		--encoding=$(file -b --mime-encoding $(which $APP)) \
		--size=$(stat --printf="%s" $(which $APP)) \
		--modification_time=$(stat --printf="%y" $(which $APP) | \
			sed "s/://g" | \
			sed "s/-//g" | \
			sed "s/ /T/" | \
			cut -b1-15 ) \
		--update_time=$(stat --printf="%z" $(which $APP) | \
			sed "s/://g" | \
			sed "s/-//g" | \
			sed "s/ /T/" | \
			cut -b1-15 ) \
		--hash=$(cksum $(which $APP) | cut -f 1 -d' ') \
		$INSTANCE \
		$GENERATED_BY \
		)
	[ -n "$container_id" ] || exit -1
	
	app_id=$(update.py \
		--table=Application \
		--id_application=$(basename $(which $APP)) \
		--location=$container_id \
		$PARAMS
		)
	[ -n "$app_id" ] || exit -1

	container_id=$(update.py \
		--table=Container \
		--id_container=$container_id \
		--location_type="relative_ref" \
		--location_value=$(readlink -f $APP) \
		--location_application=$app_id \
		)
	[ -n "$container_id" ] || exit -1

	echo $app_id
}

SSREPI_me() {
	id_container=$(get_value.py \
		--table=Container \
		--location_value="$0"\
		--id_container \
	)
	[ -n "$id_container" ] || exit -1
	id_application=$(get_value.py \
		--table=Application \
		--location=$id_container \
		--id_application \
	)
	[ -n "$id_application" ] || exit -1
	echo $id_application
}

SSREPI_get_app() {
	id_application=$1
	shift
	PARAMS=
	for arg in $@
	do
		if [[ "$arg" != *--SSREPI- ]]
		then
			PARAM="$PARAM $arg"
		fi
	done
	APP=
	CON=$(get_value.py \
		--table=Application \
		--id_application=$id_application \
		--location \
	)
	if [ ! -n "id_container" ]
	then
		APP=$id_container
		id_container=$(SSREPI_application $(which SSS-StopC2-Cluster-expt.pl) $PARAMS)
		[ -n "$id_application" ] || exit -1
	elif [ "$CON" != "None" ] || exit -1
	then
		APP=$(get_value.py \
			--table=Container \
			--id_container=$CON \
			--location_value \
		)
		[ "$APP" != "None" ] || exit -1
	fi
	echo $APP
}
SSREPI_call() {
	id_application=$1
	shift
	APP=$(SSREPI_get_app $id_application)
	if [[ "$@" == *--add-to-pipeline=* ]]
	then
		PIPE=$(echo "$@" | egrep -s "add-to-pipeline=" | \
			sed "s/^.*\(--add-to-pipeline=[^ ][^ ]*\).*$/\1/")
		pipe=$(SSREPI_add_pipeline_to_pipeline $PIPE $id_application)
		[ -n "$pipe" ] || exit -1
	fi
		
	if [[ "$@" == *--dependency=* ]]
	then
		# This is for something that must be run before this part can
		# be run. For instance we may have some post processing to be
		# done, or pre-processing. We need some way of determing
		# whether this has been run. I think we we will have to look
		# through the database looking to see if there is a record of
		# the dependency have been executed successfully this time.

		DEPENDENCY=$(echo "$@" | egrep -s "dependency=" | \
			sed "s/^.*\(--dependency=[^ ][^ ]*\).*$/\1/")
		call_id_application=$(SSREPI_application $DEPENDENCY \
			--instance=$(which $DEPENDENCY) \
		)
		[ -n "$call_id_application" ] || exit -1
		dependency_id=$(update.py \
			--table=Dependency \
			--optionality=required \
			--dependant=$id_application \
			--dependency=$call_id_application \
		)
		[ -n "$dependency_id" ] || exit -1
	fi	
	proper_args=
	position_arg=()
	position_arg_id=()
	for arg in $@
	do
		if [[ "$arg" == *--SSREPI-arg-* ]]
		then
			value=$(echo $arg | cut -f2 -d=)
			arg_id=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-arg-//')
			pos=$(get_value.py \
				--table=Argument \
				--application=$id_application \
				--id_argument=$arg_id \
				--order_value \
			)
			[ -n "$pos" ] || exit -1
			if [[ $pos = 'None' ]]
			then
				name=$(get_value.py \
					--table Argument \
					--application=$id_application \
					--id_argument=$arg_id)
					--name
				[ -n "$name" ] || exit -1
				proper_args="$proper_args --$name=$value"
			else
				position_arg[$pos]=$value
				position_arg_id[$pos]=$arg_id
			fi
		fi
	done

	LANGUAGE=
	container_type_id=
	if [[ $(file $(which $APP)) == *Bourne-Again* ]]
	then
		container_type_id=$(update.py \
			--table=ContainerType \
			--id_container_type=bash \
			--description="A Bourne-again bash script" \
			--format='text/x-shellscript' \
			--identifier=magic:'^.*shell script text executable.*$' \
		)
		LANGUAGE="Bash"
	elif [[ $(file $(which $APP)) == *Perl* ]]
	then
		container_type_id=$(update.py \
			--table=ContainerType \
			--id_container_type=perl \
			--description="A Perl script" \
			--format='text/x-perl' \
			--identifier=magic:'^.*perl script text executable$' \
		)
		LANGUAGE="Perl"
	elif  [[ $(file $(which $APP)) == *Rscript* ]]
	then
		container_type_id=$(update.py \
			--table=ContainerType \
			--id_container_type=R \
			--description="An R  script" \
			--format='text/plain' \
			--identifier=magic:'^.*Rscript script text executable.*'
		)
		LANGUAGE="R"
	elif  [[ $(file $(which $APP)) == *"ELF 64"* ]]
	then
		container_type_id=$(update.py \
			--table=ContainerType \
			--id_container_type=elf \
			--description="64bit Linux Executable" \
			--format='application/x-executable' \
			--identifier=magic:'^.*ELF 64-bit LSB executable\, x86-64.*$'
		)
		LANGUAGE="Unknown"
	else
		(>&2 echo "$FUNCNAME: Trying to call a script $APP we recognise "$(file $(which $APP)))
	fi
	[ -n "$container_type_id" ] || exit -1

	id_application=$(SSREPI_application $id_application \
		--instance=$container_type_id \
		--language=$LANGUAGE \
	)
	[ -n "$id_application" ] || exit -1

	dependency_id=$(update.py \
		--table=Dependency \
		--optionality=required \
		--dependant=$(basename $PARENT_COMMAND) \
		--dependency=$id_application \
	)
	[ -n "$dependency_id" ] || exit -1

	# The bracket means that this in-between code is sub-processed, thus
	# retaining the process's separate identity for terms of provenance.
	# That is each run of the perl script is associated with a separate
	(
		THIS_PROCESS=$(SSREPI_process --executable=$id_application)

		if (( ${#position_arg[*]} != 0 ))
		then
			for pos in $(seq ${#position_arg[*]})
			do
				SSREPI_argument_value $THIS_PROCESS ${position_arg_id[$pos]} ${position_arg[$pos]}
			done
		fi
		for arg in $proper_args 
		do
			id=$(echo $arg | cut -f 1 -d= | sed 's^--//')
			value=$(echo $arg | cut -f 2 -d=)
			(>&2 echo "NOT NOT NOT TESTED "$arg)
			SSREPI_argument_value $THIS_PROCESS $id $value
		done

		eval $APP $proper_args ${position_arg[*]}
		if [ $? -ne 0 ]
		then
			exit -1
		fi
		for arg in $@
		do
			if [[ "$arg" == *--SSREPI-output-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				kind=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-output-//')
				SSREPI_argument_output_file $id_application $THIS_PROCESS $kind $kind $value
				(>&2 echo JLFDSJJFLSJFJSDSLSLJF SSREPI_argument_output_file $id_application $THIS_PROCESS $kind $kind $value)
			fi
		done

		THIS_PROCESS=$(SSREPI_process \
			--id_process=$THIS_PROCESS \
			--executable=$id_application \
			--end_time=$(date "+%Y%m%dT%H%M%S"))


	)
	if [ $? -ne 0 ]
	then
		(>&2 echo "$FUNCNAME: Problem setting up a run for $APP")
		exit -1
	fi
	echo $call_id_application
}

SSREPI_call_bash_script_with_dependency() {
	# $1 - Script being called
	# $2 - Dependency
	PARENT_COMMAND=$(_parent_script)
	RUN=$1
	DEPEND=$2
	shift 2
	bash_container_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=bash \
		--description="A bash shell script" \
		--format='text/x-shellscript' \
		--identifier=magic:'^.*Bourne-Again shell script.*$' \
	)
	[ -n "$bash_container_type_id" ] || exit -1
	
	call_application_id=$(SSREPI_application $RUN \
		--instance=$bash_container_type_id $@)
	[ -n "$call_application_id" ] || exit -1

        application_id=$(update.py \
                --table=Application \
		--language=bash \
                --id_application=$(basename $PARENT_COMMAND) \
		--calls_application=$call_application_id \
		)	
	[ -n "$application_id" ] || exit -1

	dependency_id=$(update.py \
		--table=Dependency \
		--optionality=required \
		--dependant=$(basename $PARENT_COMMAND) \
		--dependency=$call_application_id \
		)
	[ -n "$dependency_id" ] || exit -1
	if [ -z "$NOQSUB" ]
	then
		#qsub -hold_jid $(tr "\n" "," < $DEPEND) -cwd "$RUN"
		# https://www.depts.ttu.edu/hpcc/userguides/general_guides/Conversion_Table_1.pdf
		srun ---dependency=afterany$(tr "\n" "," < $DEPEND) --chdir ./ "$RUN"
	else
		exec "$RUN"
	fi
	echo $call_application_id
}

SSREPI_argument() {
	argument_id=$(update.py \
		--table=Argument \
		$@ \
	)	
	echo $argument_id
}

SSREPI_argument_value() {
	argument_value_id=$(update.py \
		--table=ArgumentValue \
		--for_process=$1 \
		--for_argument=$2 \
		--has_value=$3 \
	)	
}
SSREPI_argument_input_file() {
	app=$1
	process=$2
	kind=$3
	var=$4
	filename=$5
	SSREPI_input $app $process $kind $filename
	argument_value_id=$(update.py \
		--table=ArgumentValue \
		--for_process=$process \
		--for_argument=$var \
		--container=$filename \
	)	
}
SSREPI_argument_output_file() {
	app=$1
	process=$2
	var=$3
	kind=$4
	filename=$5
	if [ -x "$5" ]
	then
		(>&2 echo $_parent_name":$FUNCNAME: Something failed. No output from $app for $var")
		exit -1 
	fi
	SSREPI_output $app $process $kind $filename
#	argument_value_id=$(update.py \
#		--table=ArgumentValue \
#		--for_process=$process \
#		--for_argument=$var \
#		--container=$filename \
#	)	
}
SSREPI_container_type() {
	container_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=$1 \
		--format='text/plain' \
		--identifier=$2 \
	)	
	echo $container_type_id
}

SSREPI_product() {
	product_id=$(update.py \
		--table=Product \
		--optionality=always \
		--container_type=$1 \
		--application=$2 \
		--in_file=$3 \
		--locator=$4 \
	)	
}

SSREPI_output_type() {
	output_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=$2 \
		--format='text/plain' \
		--identifier="name:$3" \
	)	
	[ -n "$output_type_id" ] || exit -1

	product_id=$(update.py \
		--table=Product \
		--optionality=always \
		--application=$1 \
		--container_type=$2 \
		--in_file=$output_type_id \
		--locator="CWD PATH REGEX:$3" \
	)	
	[ -n "$product_id" ] || (unset $output_product_id && exit -1)

	echo $output_type_id
}

SSREPI_working_directory() {
	output_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=CWD \
		--format='application/x-directory' \
		--identifier="name:$2" \
	)	
	[ -n "$output_type_id" ] || exit -1

	product_id=$(update.py \
		--table=Product \
		--optionality=always \
		--application=$1 \
		--container_type=CWD \
		--in_file=$output_type_id \
		--locator="CWD" \
	)	
	[ -n "$product_id" ] || (unset $output_type_id && exit -1)

	echo $output_type_id
}

SSREPI_output() {
 
	# 1 - application path
	# 2 - output_of
	# 3 - container type
	# 4 - path to object

	if [ ! -e $4 ]
	then
		(>&2 echo "$FUNCNAME: Something seriously wrong in $0 at $BASH_LINENO: $4 does not exist")
		exit -1 
	fi

	container_id=
	if [ -d $4 ]
	then
		container_id=$(update.py \
			--table=Container \
			--id_container=$(basename $4) \
			--location_value=$(readlink -f $4) \
			--location_type="relative_ref" \
			--location_application=$1 \
			--encoding=$(file -b --mime-encoding $4) \
			--size=4096 \
			--modification_time=$(stat --printf="%y" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--output_of=$2 \
			--instance=$3 \
			$GENERATED_BY \
			)
	else	
		container_id=$(update.py \
			--table=Container \
			--id_container=$(basename $4) \
			--location_value=$(readlink -f $4) \
			--location_type="relative_ref" \
			--location_application=$1 \
			--encoding=$(file -b --mime-encoding $4) \
			--size=$(stat --printf="%s" $4) \
			--modification_time=$(stat --printf="%y" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--hash=$(cksum $4 | cut -f 1 -d' ') \
			--output_of=$2 \
			--instance=$3 \
			$GENERATED_BY \
			)
			
	fi
	[ -n "$container_id" ] || exit -1

}
	
SSREPI_input_type() {
	input_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=$2 \
		--format='text/plain' \
		--identifier="name:$3" \
	)	
	[ -n "$input_type_id" ] || exit -1

	uses_id=$(update.py \
		--table=Uses \
		--optionality=required \
		--application=$1 \
		--container_type=$2 \
		--in_file=$input_type_id \
		--locator="CWD PATH REGEX:$3" \
	)	
	[ -n "$uses_id" ] || (unset $input_type_id && exit -1)

	echo $input_type_id
}

SSREPI_input() {
	if [ ! -e $4 ]
	then
		(>&2 echo "$FUNCNAME: Something seriously wrong in $0 at $BASH_LINENO: $4 does not exist")
		exit -1 
	fi

	container_id=
	if [ -d $4 ]
	then
		container_id=$(update.py \
			--table=Container \
			--id_container=$(basename $4) \
			--location_value=$(readlink -f $4) \
			--location_type="relative_ref" \
			--location_application=$1 \
			--encoding=$(file -b --mime-encoding $4) \
			--size=4096 \
			--modification_time=$(stat --printf="%y" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--instance=$3 \
			$GENERATED_BY \
			)
	else	
		container_id=$(update.py \
			--table=Container \
			--id_container=$(basename $4) \
			--location_value=$(readlink -f $4) \
			--location_type="relative_ref" \
			--location_application=$1 \
			--encoding=$(file -b --mime-encoding $4) \
			--size=$(stat --printf="%s" $4) \
			--modification_time=$(stat --printf="%y" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" $4 | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--hash=$(cksum $4 | cut -f 1 -d' ') \
			--instance=$3 \
			$GENERATED_BY \
			)
			
	fi
	[ -n "$container_id" ] || exit -1
	

	input_id=$(update.py \
		--table=Input \
		--usage=data \
		--process=$2 \
		--container=$4 \
	)
	[ -n "$input_id" ] || exit -1
}
SSREPI_hutton_person() {
	if ! _getent passwd $1 >/dev/null 2>/dev/null 
	then
		(>&2 echo "$FUNCNAME: $0 at $BASH_LINENO: Invalid user supplied: $1")
		echo ""
		exit 1
	fi
        NAME=$(_getent passwd $1 | cut -f 5 -d:)
        EMAIL=$(echo $NAME | sed "s/ /./g")"@hutton.ac.uk"
	USER_HOME=$(_getent passwd $1 | cut -f 6 -d:)

        person_id=$(update.py \
                --table=Person \
                --id_person=$1 \
                --name="$NAME" \
                --email=$EMAIL \
                )
        [ -n "$person_id" ] || exit -1

        user_id=$(update.py \
                --table=User \
                --home_dir=$USER_HOME \
                --account_of=$person_id \
                --id_user=$1 \
                )
        [ -n "$user_id" ] || exit -1

	echo $person_id
}
SSREPI_person() {
	person_id=$(update.py \
		--table=Person \
		$@ \
	)	
	echo $person_id
}
SSREPI_project() {
	if [[ "$@" != *--id_project* ]]
	then
		(>&2 echo "$FUNCNAME: $0 at $BASH_LINENO: No project id has been provided")
		echo ""
		exit -1
	fi
	project_id=$(update.py \
		--table=Project \
		$@
	)	
	echo $project_id
}
SSREPI_study() {
	study_id=$(update.py \
		--table=Study \
		$@ \
	)
	echo $study_id
}
SSREPI_set_study() {
	# You would think that this should be done in the function above.
	# However the script above is called by command substitution, which is
	# a subprocess. A subprocess for which all environment variables are
	# wiped out, as soon as it terminates. So we have to do this directly.
	export SSREPI_STUDY=$1
	export GENERATED_BY=--generated_by=$SSREP_STUDY
}
SSREPI_involvement() {
	involvement_id=$(update.py \
		--table=Involvement \
		--study=$1 \
		--person=$2 \
		--role=$3 \
	)
}
SSREPI_paper() {
	DOC="$1"
	if [[ ! -f "$DOC" ]]
	then
		APP=$0
	else
		shift
	fi
	PARAMS=$@
	for param in $PARAMS
	do
		parameter=$(echo $param | cut -f1 -d=)
		case "$parameter" in
			"sourced_by") sourced_by=$(echo $param | cut -f2 -d=);;
			"held_by") held_by=$(echo $param | cut -f2 -d=);;
			"describes") describes=$(echo $param | cut -f2 -d=);;
			"date") date=$(echo $param | cut -f2 -d=);;
		esac
	done

	paper_container_type_id=$(update.py \
		--table=ContainerType \
		--id_container_type=paper \
		--description="Published or draft paper" \
		--format='application/pdf;application/msword' \
		--identifier=magic:'^.*Microsoft Word*$;magic:^.*PDF Document.*$' \
	)
	[ -n "$paper_container_type_id" ] || exit -1

	container_id=$(update.py \
		--table=Container \
		--id_container=$(basename "$DOC") \
		--location_value=$(readlink -f "$DOC") \
		--held_by=$held_bv \
	        --sourced_from=$sourced_from \
		--location_type="relative_ref" \
		--encoding=$(file -b --mime-encoding "$DOC") \
		--size=$(stat --printf="%s" "$DOC") \
		--modification_time=$(stat --printf="%y" "$DOC" | \
			sed "s/://g" | \
			sed "s/-//g" | \
			sed "s/ /T/" | \
			cut -b1-15 ) \
		--update_time=$(stat --printf="%z" "$DOC" | \
			sed "s/://g" | \
			sed "s/-//g" | \
			sed "s/ /T/" | \
			cut -b1-15 ) \
		--hash=$(cksum "$DOC" | cut -f 1 -d' ') \
		--instance=$paper_container_type_id \
		$GENERATED_BY \
		)
	[ -n "$container_id" ] || exit -1
	

	paper_id=$(update.py \
		--table=Documentation \
		--id_documentation="$DOC" \
		--title=$(basename "$DOC") \
		--describes=$describes \
		)
		#--date=$date \
		#--location=$container_id \
	[ -n "$paper_id" ] || exit -1

	container_id=$(update.py \
		--table=Container \
		--id_container=$container_id \
		--location_type="relative_ref" \
		--location_value=$(readlink -f "$DOC") \
		--location_documentation=$paper_id \
		)
	[ -n "$container_id" ] || exit -1

	echo $container_id

}
SSREPI_make_tag() {
	tag_id=$(update.py \
		--table=Tag \
		--id_tag=$1 \
		--description=$2 \
	)
	echo $tag_id
}
SSREPI_tag() {
	tag_map_id=$(update.py \
		--table=TagMap \
		--target_tag=$1 \
		$2
	)
}
SSREPI_contributor() {
	instance=$(get_value.py \
		--table=Container \
	        --id_container="$1" \
		--instance)
	if [[ "$instance" == "paper" ]]
	then
		contributor_id=$(update.py \
			--table=Contributor \
			--documentation="$1" \
			--contributor="$2" \
			--contribution="$3" \
		)
	else
		contributor_id=$(update.py \
			--table=Contributor \
			--application="$1" \
			--contributor="$2" \
			--contribution="$3" \
		)
	fi
}
SSREPI_create_pipeline() {
        pipeline_id=$(update.py \
		--table=Pipeline \
		--id_pipeline=application.$1 \
		--calls_application=$1 \
		)
	echo $pipeline_id
}
SSREPI_add_application_to_pipeline() {
	# $1 - pipeline
	# $2 - called application
        pipeline_id=$(update.py \
		--table=Pipeline \
		--id_pipeline=application.$2 \
		--calls_application=$2 \
		)
	[ -n "$pipeline_id" ] || exit -1
	old_pipeline_id=$(update.py \
		--table=Pipeline \
		--id_pipeline=$1 \
		--next=$pipeline_id \
		)
	if [ -z "$old_pipeline_id" ] 
	then
		unset pipeline_id
		exit -1
	fi
	echo $pipeline_id
}
SSREPI_add_pipeline_to_pipeline() {

        pipeline_id=$(update.py \
		--table=Pipeline \
		--id_pipeline=pipeline.$2 \
		--calls_pipeline=$2 \
		)
	[ -n "$pipeline_id" ] || exit -1
	old_pipeline_id=$(update.py \
		--table=Pipeline \
		--id_pipeline=$1 \
		--next=$pipeline_id \
		)
	if [ -z "$old_pipeline_id" ] 
	then
		unset pipeline_id
		exit -1
	fi
	echo $pipeline_id
}
SSREPI_statistical_method() {
	statistical_method_id=$(update.py \
		--table=StatisticalMethod \
		--id_statistical_method=$1 \
		--description=$2 \
		)
	echo "$statistical_method_id"
}
SSREPI_visualisation_method() {
	visualisation_method_id=$(update.py \
		--table=VisualisationMethod \
		--id_visualisation_method=$1 \
		--description=$2 \
		)
	echo "$visualisation_method_id"
}

SSREPI_statistics() {
	statistics_id=$(update.py \
		--table="Statistics" \
		--id_statistics=$1 \
		--date=$(date "+%Y%m%dT%H%M%S") \
		--used=$2 \
		--query=$3 \
	)
	echo $statistics_id
}
SSREPI_visualisation() {
	visualisation_id=$(update.py \
		--table="Visualisation" \
		--id_visualisation=$1 \
		--date=$(date "+%Y%m%dT%H%M%S") \
		--visualisation_method=$2 \
		--query=$3 \
		--contained_in=$4 \
	)
	echo $visualisation_id
}
SSREPI_employs() {
	employs_id=$(update.py \
		--table=Employs \
		--statistical_variable=$1 \
		$2 \
		)
}

SSREPI_implements() {
	implements_id=$(update.py \
		--table=Implements \
		--application=$1 \
		$2 \
		)
}

SSREPI_parameter() {
	parameter_id=$(update.py \
		--table=Parameter \
		--id_parameter=$1 \
		--description=$2 \
		--data_type=$3 \
		$4 \
		)
	echo $parameter_id
}
SSREPI_statistical_variable() {
	statistical_variable_id=$(update.py \
		--table=Variable \
		--id_variable=$1 \
		--description=$2 \
		--data_type=$3 \
		--generated_by=$4 \
		)
	echo $statistical_variable_id
}
SSREPI_variable() {
	variable_id=$(update.py \
		--table=Variable \
		--id_variable=$1 \
		--description=$2 \
		--data_type=$3 \
		--visualisation_method=$4 \
		)
	echo $variable_id
}
SSREPI_value() {
	val=$1
	shift 1
	value_id=$(update.py \
		--table=Value \
		--id_value=$val \
		$@)
}
SSREPI_content() {
	content_id=$(update.py \
		--table=Content \
		$@)
	echo $content_id
}

SSREPI_person_makes_assumption() {
	assumption_id=$(update.py \
		--table=Assumption \
		--id_assumption=$2 \
		--description=$3 \
		)
	if [ -z "$assumption_id" ] 
	then
		unset assumption_id
		exit -1
	fi
	assumes_id=$(update.py \
		--table=Assumes \
		--person=$1 \
		--assumption=$assumption_id)
	if [ -z "$assumes_id" ] 
	then
		unset assumption_id
		exit -1
	fi
	echo "$assumption_id"
}

SSREPI_run() {
	run=0
	MAX_RUNS=5
	runcmd=$1

	if [ -z "$NOQSUB" ]
	then
		while (($run < $count))
		do
			(>&2 echo "==========================")
			(>&2 echo "Run number: "$(($run + 1))" of $count")
			(>&2 echo "==========================")
			(>&2 echo "Running ${runcmd[$run]}...")
			chmod +x "${runcmd[$run]}"
			#qsub -N $(basename ${runcmd[$run]}) -cwd "${runcmd[$run]}"
			# https://www.depts.ttu.edu/hpcc/userguides/general_guides/Conversion_Table_1.pdf
			srun -J $(basename ${runcmd[$run]}) --chdir ./ "${runcmd[$run]}"
			
			echo $(basename ${runcmd[$run]}) >> $POST_DEPENDENCIES

			run=$(($run + 1))
		done

		# The code below is the old way of doing it. 

		exit 0

		# I am doing this use shell scripting but qsub looks really quite
		# promising.  I need to discuss this with Gary. This means a change of
		# database to start with, and a change in how the preparation is done.
	else
		run=0
		while (($run < $count)) && (($run < $MAX_RUNS ))
		do
		    instances=$(ps -Ao cmd | grep $FEARLUS | grep -v grep | wc -l)
		    if [ $instances -lt $NOF_CPUS ]
		    then

			chmod +x "${runcmd[$run]}"
			(>&2 echo "==========================")
			(>&2 echo "Run number: $run of $count")
			(>&2 echo "==========================")
			(>&2 echo "Running ${runcmd[$run]}...")
			eval "sh ${runcmd[$run]} 2> ${runcmd[$run]}.out"

			run=$(($run + 1))
		    else
		    	(>&2 echo $_parent_name":$FUNCNAME: Waiting...")
		    fi
		    sleep 20
		done
	fi
}
_ip_address() {
	IP=$(/sbin/ifconfig | sed -n "2p" | awk '{print $2}' |cut -f2 -d:)
	if [[ $(uname -s) == "Darwin" ]]
	then
		IP=$(/sbin/ifconfig en0 | sed -n "5p" | awk '{print $2}' |cut -f2 -d:)
	fi
	echo "$IP"
}

_mac_address() {
	MAC=$(/sbin/ifconfig | sed -n "1p" | awk '{print $5}')
	if [[ $(uname -s) == "Darwin" ]]
	then
		MAC=$(/sbin/ifconfig en0 | sed -n "3p" | awk '{print $2}')
	fi
        if [ -z "$MAC" ]
        then 
		MAC=$(/sbin/ifconfig | sed -n "4p" | awk '{print $2}')
	fi
	echo "$MAC"
}

_fqdn() {

# I have had to write this because of the way /etc/hosts have been set
# up wth the canonical name for the machine is first and in our /etc/hosts
# this is the shortname rather than the long name, so I am going to 
# use nslookup to get around this.

	if hostname -f | grep -qs "\."
	then 
		hostname -f 
	else
		nslookup -host $(hostname) | grep ^Name | awk '{print $2}'
	fi
}

_parent_script() {
	# Should be able to do this in one line, but bash doesn't like it for
	# some reason
	ME=$BASHPID
	BASH_PROB=$(ps -o args= $ME)
	if [[ "$BASH_PROB" == *-xv* ]]
	then
		RESULT=$(echo $BASH_PROB | awk '{print $3}') 
	else
		RESULT=$(echo $BASH_PROB | awk '{print $2}') 
	fi
	echo $RESULT
}

uniq() {
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
}

_getent() {
	if [[ "$1" != "passwd" ]]
	then
		echo "This only works for 'passwd'"
		exit -1
	fi
	if [[ $(uname -s) != "Darwin" ]]
	then
		getent $user
	else
		if [ -z $2 ];
		then
			USERS=`dscl . list /Users | grep -v “^_”`
		else
			USERS="$2"
		fi
		for user in $USERS
		do
			result=`dscl . -read /Users/$user RecordName | \
				sed 's/RecordName: //g'`:*:`dscl . -read /Users/$user UniqueID | \
				sed 's/UniqueID: //g'`:`dscl . -read /Users/$user PrimaryGroupID | \
				sed 's/PrimaryGroupID: //g'`:`dscl . -read /Users/$user RealName | \
				sed -e 's/RealName://g' -e 's/^ //g' | \
				awk '{printf("%s", $0 (NR==1 ? "" : ""))}'`:/Users/$user:`dscl . -read /Users/$user UserShell | \
				sed 's/UserShell: //g'`
			echo $result
		done
	fi
}

