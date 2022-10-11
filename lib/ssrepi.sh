#!/usr/bin/env bash

# A series of functions to update ssrep.db with an actual run. 

# I have decided to do this in the bash script

# Remember because this is in-line, exit causes a stop program, return to abort
# to calling program.

# The convention here is that any function that starts with an underscore, "_"
# is an internal function.

export SSREPI_NOF_CPUS=2
export SSREP_DBNAME="$PWD"/ssrep.db
export DEBUG=1
export PRCESSSES_STARTED=()
export PROCESSES_DONE=()


if which create_database.py >/dev/null 2>&1
then
	create_database.py
else
	(>&2 echo "No ssrepi python functions available. 
		Have you set the PATH variable correct?")
	exit -1
fi

# Some sanity checking

if [ -z "$SSREPI_SLURM" ]
then
	if [ -z "$SSREPI_MAX_PROCESSES" ]
	then
		(>&2 echo $0: No max processes and not using a scheduler will assume 1.)
		SSREPI_MAX_PROCESSES=1
	fi
fi
SSREPI_require_minimum() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	# $1 - app id
	# $2 - spec name
	# $3 - desired version literal
	# $4 - actual version literal
	id_computer=$(update.py \
		--table=Computer \
		--id_computer=$(hostname) \
		--name=$(hostname) \
		--host_id=$(_fqdn) \
		--ip_address=$(_ip_address) \
		--mac_address=$(_mac_address) \
	)
	[ -n "$id_computer" ] || exit -1
	id_specification=$(update.py \
		--table=Specification \
		--id_specification=$2 \
		--specification_of=$id_computer \
		--value="$3" \
	)	
	[ -n "$id_specification" ] || exit -1
	id_requirement=$(update.py \
		--table=Requirement \
		--minimum=$id_specification \
		--application=$1 \
	)		
	[ -n "$id_requirement" ] || exit -1
	if echo $3 | egrep -q "^[0-9]+(\.[0-9]+)?$" && \
	   echo $4 | egrep -q "^[0-9]+(\.[0-9]+)?$"
	then 
	     	if (( $(echo $3'>'$4 | bc -lq 2>/dev/null) ))
	     	then
			[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
			return 0
		fi
	elif [[ "$3" > "$4" ]]
	then
		[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
		return 0
	fi
	id_meets=$(update.py \
		--table=Meets \
		--computer_specification=$id_computer \
		--requirement_specification=$id_specification \
	)
	[ -n "$id_meets" ] || exit -1
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	return 1
}

SSREPI_require_exact() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	# $1 - app id
	# $2 - spec name
	# $3 - desired version literal
	# $4 - actual version literal
	id_computer=$(update.py \
		--table=Computer \
		--id_computer=$(hostname) \
		--name=$(hostname) \
		--host_id=$(_fqdn) \
		--ip_address=$(_ip_address) \
		--mac_address=$(_mac_address) \
	)
	[ -n "$id_computer" ] || exit -1
	id_specification=$(update.py \
		--table=Specification \
		--id_specification=$2 \
		--specification_of=$id_computer \
		--value="$3" \
	)	
	[ -n "$id_specification" ] || exit -1
	id_requirement=$(update.py \
		--table=Requirement \
		--exact=$id_specification \
		--application=$1 \
	)		
	[ -n "$id_requirement" ] || exit -1
	if [[ "$3" != "$4" ]]
	then
		[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
		return 0
	fi
	id_meets=$(update.py \
		--table=Meets \
		--computer_specification=$id_computer \
		--requirement_specification=$id_specification \
	)
	[ -n "$id_meets" ] || exit -1
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	return 1
}

SSREPI_process() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_process=
	EXEC=
	if [[ "$@" != *--executable* ]]
	then
		EXEC="--executable="$(basename $0)
	else
		EXEC=''
	fi
	if [[ "$@" == *--id_process* ]]
	then
   		id_process=$(update.py \
			--table=Process \
			$@ \
		)
	else
		NAME=$(_getent passwd $USER | cut -f 5 -d:) 
		id_person=$(update.py \
			--table=Person \
			--email=$USER@$(hostname) \
			--id_person=$USER \
			--name="$NAME" \
		)
		[ -n "$id_person" ] || exit -1

		id_user=$(update.py \
			--table=User \
			--home_dir=$HOME \
			--account_of=$id_person \
			--id_user=$USER \
		)
		[ -n "$id_user" ] || exit -1

		id_process=$(update.py \
			--table=Process \
			--id_process=process.$(uniq) \
			--some_user=$USER \
			--start_time=$(date "+%Y%m%dT%H%M%S") \
			--working_dir=$PWD \
			--host=$(hostname) \
		$EXEC $@)
		[ -n "$id_process" ] || exit -1
		

		id_computer=$(update.py \
			--table=Computer \
			--id_computer=$(hostname) \
			--name=$(hostname) \
			--host_id=$(_fqdn) \
			--ip_address=$(_ip_address) \
			--mac_address=$(_mac_address) \
		)
		[ -n "$id_computer" ] || exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_process
}

SSREPI_application() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
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

	id_model=
	if [[ "$@" == *--model=* ]]
	then	
		MODEL=$(echo "$PARAMS" | egrep -s "model=" | \
			sed "s/^.*--model=\([^ ][^ ]*\).*$/\1/")
		
		id_model=$(update.py \
			--table=Model\
			--id_model=$MODEL
			)
		[ -n "$id_model" ] || exit -1
	fi

	if [[ "$PARAMS" == *--instance=* ]]
	then
		INSTANCE=$(echo "$PARAMS" | egrep -s "instance=" | \
			sed "s/^.*\(--instance=[^ ][^ ]*\).*$/\1/")
		PARAMS=$(echo "$PARAMS" | egrep -s "instance=" | \
			sed "s/--instance=[^ ][^ ]* *//")
	fi

	id_container=$(update.py \
		--table=Container \
		--id_container=container.$(cksum $(which $APP) | awk '{print $1}') \
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
	[ -n "$id_container" ] || exit -1
	
	id_app=$(update.py \
		--table=Application \
		--id_application=application.$(cksum $(which $APP) | awk '{print $1}') \
		--location=$id_container \
		$PARAMS
	)
	[ -n "$id_app" ] || exit -1

	id_container=$(update.py \
		--table=Container \
		--id_container=$id_container \
		--location_type="relative_ref" \
		--location_value=$(readlink -f $APP) \
		--location_application=$id_app \
	)
	[ -n "$id_container" ] || exit -1

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_app
}

SSREPI_me() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_application=
	if [ -n "$1" ]
	then
		id_application=$1
		shift
	else
		id_application=$(_parent_script)
	fi
	PARAMS=
	for arg in $@
	do
		if [[ "$arg" != *--SSREPI- ]]
		then
			PARAM="$PARAM $arg"
		fi
	done
	if [[ $(exists.py --table=Application --id_application=$id_application)  = True ]]
	then
		id_application=$id_application
	elif [ -f $(which $id_application) ]
	then
		id_application=$(SSREPI_application \
			$id_application \
			$PARAMS \
		)
		[ -n $id_application ] || exit -1
	else
		(>&2 echo "$FUNCNAME: Application $id_application does not exist")
		exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_application
}

SSREPI_application_get_executable() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	PARAMS=
	for arg in $@
	do
		if [[ "$arg" != *--SSREPI- ]]
		then
			PARAM="$PARAM $arg"
		fi
	done
	id_application=
	if [ -n "$1" ]
	then
		id_application=$1
		shift
	else
		id_application=$(SSREPI_me)
	fi

	executable=
	if [[ $(exists.py --table=Application --id_application=$id_application)  = True ]]
	then
		id_container=$(get_value.py \
			--table=Application \
			--id_application=$id_application \
			--location \
		)
		executable=$(get_value.py \
			--table=Container \
			--id_container=$id_container \
			--location_value \
		)

	elif [ -x $(which $id_application) ]
	then
		executable=$id_application
		id_application=$(SSREPI_application \
			$id_application \
			$PARAMS \
		)
		[ -n $id_application ] || exit -1

	else
		(>&2 echo "$FUNCNAME: Application $id_application does not exist")
		exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $executable
}

SSREPI_call() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	_run $@ --in-line $STANDARD_ARGS

	if [ -z "$SSREPI_SLURM" ]
	then
		wait
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

SSREPI_invoke() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [ -z "$SSREPI_SLURM" ]
	then
		_run $@ $STANDARD_ARGS
	else
		_run $@ $STANDARD_ARGS &
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

_run() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	id_application=$1
	if [ -z "$SSREPI_pipe" ]
	then
		export SSREPI_pipe=$(SSREPI_pipeline $(SSREPI_me $(_parent_script)))
	fi

	# The reasoning behind the next two lines is that the argument may be
	# an id_application or a path may be passed as the first argument

	APP=$(SSREPI_application_get_executable $@)
	id_application=$(SSREPI_me $@)

	shift

	# Remove cwd
	CWD=
	if [[ "$@" == *--cwd* ]]
	then	
		CWD=$(echo "$@" | egrep -s "cwd=" | \
			sed "s/^.*--cwd=\([^ ][^ ]*\).*$/\1/")
		if [ ! -d "$CWD" ]
		then
			mkdir "$CWD"
		fi
		PARAMS=$(echo "$PARAMS" | egrep -s "cwd=" | \
			sed "s/--cwd=[^ ][^ ]* *//")
	fi

	inline=
	# Remove --inline
	if [[ "$@" == *--inline* ]]
	then	
		inline=1
		PARAMS=$(echo "$PARAMS" | egrep -s "\-\-inline" | \
			sed "s/--inline\s*//")
	fi

	# So PIPE is the pipe line we want to attach to

        id_pipeline=$(update.py \
		--table=Pipeline \
		--id_pipeline=calls.$id_application \
		--calls_application=$id_application \
	)
	[ -n "id_pipeline" ] || exit -1
	# Now we attach this new pipe to the existing pipe and replace
	# PIPE with this value.
        SSREPI_pipe=$(update.py \
		--table=Pipeline \
		--id_pipeline=$SSREPI_pipe \
		--next=$id_pipeline \
	)
	[ -n "SSREPI_pipe" ] || exit -1
	export SSREPI_pipe=$id_pipeline
		
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
		id_call_application=$(SSREPI_application $DEPENDENCY \
			--instance=$(which $DEPENDENCY) \
		)
		[ -n "$id_call_application" ] || exit -1
		id_dependency=$(update.py \
			--table=Dependency \
			--optionality=required \
			--dependant=$id_application \
			--dependency=$id_call_application \
		)
		[ -n "$id_dependency" ] || exit -1
	fi	

	# Arguably all this could be done from with the the thing that is being
	# called here, i.e. at a level lower than this (and we may do this
	# later), but for now we are going to assume that the thing being
	# called has no provenance primitives and we are having to do this
	# external to the script. It makes the coding slightly awkward but
	# leaves a lot of room for speed improvement at a later date. This
	# means the primitives could be embedeed in Perl, R, NetLogo, and elf
	# exectuables.	I will put this comment everywhere where we stoop to do
	# provenance at a level higher than it should. I am doing this because
	# this got very confused in my head to start with. To be clear,
	# provenance for a bunch of code should explicitly be done by that code
	# if at all possible.						

	proper_args=
	position_arg=()
	id_position_arg=()
	for arg in $@
	do
		if [[ "$arg" == *--SSREPI-argument-* ]]
		then
			if [[ "$arg" == *=* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				id_arg=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-argument-//')
				pos=$(get_value.py \
					--table=Argument \
					--application=$id_application \
					--id_argument=$id_arg \
					--order_value \
				)
				[ -n "$pos" ] || exit -1
				if [[ $pos = 'None' ]]
				then
					name=$(get_value.py \
						--table=Argument \
						--application=$id_application \
						--id_argument=$id_arg \
						--name)
					[ -n "$name" ] || exit -1
					proper_args="$proper_args --$name=$value"
				else
					arity=$(get_value.py \
						--table=Argument \
						--application=$id_application \
						--id_argument=$id_arg \
						--arity)
					argsep=$(get_value.py \
						--table=Argument \
						--application=$id_application \
						--id_argument=$id_arg \
						--argsep)
					[ -n "$argsep" ] || exit -1
					if (  [[ $arity == "+" ]] || (( $arity > 1 ))  ) && [[ $argsep == "space" ]]
					then
						value=$(echo $@ | sed 's/.*\-\-SSREPI\-argument\-'$id_arg'=//' | sed 's/\-\-.*//')
					fi
					position_arg[$pos]=$value
					id_position_arg[$pos]=$id_arg
				fi
			else
				id_arg=$(echo $arg | sed 's/--SSREPI-argument-//')
				name=$(get_value.py \
					--table=Argument \
					--application=$id_application \
					--id_argument=$id_arg \
					--name
				)
				[ -n "$name" ] || exit -1
				proper_args="$proper_args --$name"
			fi
		fi
	done

	LANGUAGE=
	id_container_type=
	if [[ $(file $(which $APP)) == *Bourne-Again* ]]
	then
		id_container_type=$(update.py \
			--table=ContainerType \
			--id_container_type=bash \
			--description="A Bourne-again bash script" \
			--format='text/x-shellscript' \
			--identifier=magic:'^.*shell script text executable.*$' \
		)
		LANGUAGE="Bash"
	elif [[ $(file $(which $APP)) == *Perl* ]]
	then
		id_container_type=$(update.py \
			--table=ContainerType \
			--id_container_type=perl \
			--description="A Perl script" \
			--format='text/x-perl' \
			--identifier=magic:'^.*perl script text executable$' \
		)
		LANGUAGE="Perl"
	elif  [[ $(file $(which $APP)) == *Rscript* ]]
	then
		id_container_type=$(update.py \
			--table=ContainerType \
			--id_container_type=R \
			--description="An R  script" \
			--format='text/plain' \
			--identifier=magic:'^.*Rscript script text executable.*'
		)
		LANGUAGE="R"
	elif  [[ $(file $(which $APP)) == *"ELF 64"* ]]
	then
		id_container_type=$(update.py \
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
	[ -n "$id_container_type" ] || exit -1

	id_application=$(SSREPI_application $id_application \
		--instance=$id_container_type \
		--language=$LANGUAGE \
	)
	[ -n "$id_application" ] || exit -1

	id_dependency=$(update.py \
		--table=Dependency \
		--optionality=required \
		--dependant=$(SSREPI_me $(_parent_script)) \
		--dependency=$id_application \
	)
	[ -n "$id_dependency" ] || exit -1

	# The bracket means that this in-between code is sub-processed, thus
	# retaining the process's separate identity for terms of provenance.
	# That is each run of the perl script is associated with a separate
	(
		THIS_PROCESS=$(SSREPI_process --executable=$id_application)

		if [ -n "$CWD" ]
		then
			cd "$CWD"
		fi
		if (( ${#position_arg[*]} != 0 ))
		then
			for pos in $(seq ${#position_arg[*]})
			do
				SSREPI_argument_value $THIS_PROCESS ${id_position_arg[$pos]} ${position_arg[$pos]}
			done
		fi
		for arg in $proper_args 
		do
			if [[ "$arg" == *=* ]]
			then
				id=$(echo $arg | cut -f 1 -d= | sed 's/^\-\-//')
				value=$(echo $arg | cut -f 2 -d=)
			else
				id=$(echo $arg | sed 's/^\-\-//')
				value="True"
			fi
			SSREPI_argument_value $THIS_PROCESS $id $value
		done

		stdout=
		stderr=
		for arg in $@
		do
			if [[ "$arg" == *--SSREPI-input-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				input_type_id=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-input-//')
				SSREPI_input_value $id_application $THIS_PROCESS $input_type_id $value
			elif [[ "$arg" == *--SSREPI-extend-stdout-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				stdout=' >>'$value
			elif [[ "$arg" == *--SSREPI-stdout-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				stdout=' >'$value
			elif [[ "$arg" == *--SSREPI-stderr-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				stderr=' >'$value
			fi
		done

		[ -n $DEBUG ] && (>&2 echo CWD: $PWD)
		if [ -n "$inline" ]
		then
			[ -n $DEBUG ] && (>&2 echo RUNNING: $APP $proper_args ${position_arg[*]} $stdout $stderr)
			eval $APP $proper_args ${position_arg[*]} $stdout $stderr
			SYS=$?
			if [ $SYS -ne 0 ]
			then
				exit -1
			fi
		elif [ -n "$SSREPI_SLURM" ]
		then
			(>&2 echo "SLURMING IT: TBC")
			
			[ -n $DEBUG ] && (>&2 echo RUNNING: srun $APP $proper_args ${position_arg[*]} $stdout $stderr)
			srun $APP $proper_args ${position_arg[*]} $stdout $stderr
		else
			# Check the number of processes running. And if it exceeded then sit here and wait.
			instances=$(ps -A -o command | grep $APP | grep -v grep | wc -l)
			while [ $instances -ge $SSREPI_NOF_CPUS ]
			do
				(>&2 echo "$FUNCNAME: Waiting...")
				sleep 60
			done
			[ -n $DEBUG ] && (>&2 echo RUNNING: $APP $proper_args ${position_arg[*]} $stdout $stderr)
			eval $APP $proper_args ${position_arg[*]} $stdout $stderr
		fi

		for arg in $@
		do
			if 	[[ "$arg" == *--SSREPI-output-* ]] || \
				[[ "$arg" == *--SSREPI-extend-stdout-* ]] || \
				[[ "$arg" == *--SSREPI-stdout-* ]] || \
				[[ "$arg" == *--SSREPI-stderr-* ]]
			then
				value=$(echo $arg | cut -f2 -d=)
				output_type_id=$(echo $arg | cut -f1 -d= | \
					sed 's/--SSREPI-output-//' | \
					sed 's/--SSREPI-stderr-//' | \
					sed 's/--SSREPI-extend-stdout-//' | \
					sed 's/--SSREPI-stdout-//')
				SSREPI_output_value $THIS_PROCESS $output_type_id $value
			fi
		done

		THIS_PROCESS=$(SSREPI_process \
			--id_process=$THIS_PROCESS \
			--executable=$id_application \
			--end_time=$(date "+%Y%m%dT%H%M%S"))

		if [ -z "$SSREPI_SLURM" ]
		then
			wait
		fi
	)
	if [ $? -ne 0 ]
	then
		(>&2 echo "$FUNCNAME: Problem with run for $APP")
		exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

SSREPI_argument() {
	
	# $1 - application_id
	# $2 - container_type
	# $@ - the rest
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_application=$1
	shift
	id_argument=$id_application.$1
	shift
	id_argument=$(update.py \
		--table=Argument \
		--id_argument=$id_argument \
		--application=$id_application \
		$@ \
	)	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_argument
}

SSREPI_argument_value() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_argument_value=$(update.py \
		--table=ArgumentValue \
		--for_process=$1 \
		--for_argument=$2 \
		--has_value=$3 \
	)	
}

SSREPI_container_type() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_container_type=$(update.py \
		--table=ContainerType \
		--id_container_type=$1 \
		--format='text/plain' \
		--identifier=$2 \
	)	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_container_type
}

SSREPI_product() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_product=$(update.py \
		--table=Product \
		--optionality=always \
		--container_type=$1 \
		--application=$2 \
		--in_file=$3 \
		--locator=$4 \
	)	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_product
}

SSREPI_output() {

	# $1 - id_application
	# $2 - id_container_type
	# $3 - pattern

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_container_type=$id_application.$2
	id_output_type=$(update.py \
		--table=ContainerType \
		--id_container_type=$id_container_type \
		--format='text/plain' \
		--identifier="name:$3" \
	)	
	[ -n "$id_output_type" ] || exit -1

	id_product=$(update.py \
		--table=Product \
		--optionality=always \
		--application=$1 \
		--container_type=$id_container_type \
		--in_file=$id_output_type \
		--locator="CWD PATH REGEX:$3" \
	)	
	[ -n "$id_product" ] || (unset $id_output_product && exit -1)

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_output_type
}

SSREPI_output_value() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
 
	# $1 - process_id - specifically output of
	# $2 - container_type_id - type of output
	# $3 - path to object

	if [ ! -e $3 ]
	then
		(>&2 echo "$FUNCNAME: Something wrong in the call \"--SSREPI-output-$id_container_type=$3\": $3 does not exist")
		exit -1 
	fi

	id_container=
	if [ -d $3 ]
	then
		id_container=$(update.py \
			--table=Container \
			--id_container=container.$(cksum "$3" | awk '{print $1}') \
			--location_value=$(readlink -f "$3") \
			--location_type="relative_ref" \
			--encoding=$(file -b --mime-encoding "$3") \
			--size=4096 \
			--modification_time=$(stat --printf="%y" "$3" | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" "$3" | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--output_of=$1 \
			--instance=$2 \
			$GENERATED_BY \
		)
	else	
		id_container=$(update.py \
			--table=Container \
			--id_container=container.$(cksum "$3" | awk '{print $1}') \
			--location_value=$(readlink -f "$3") \
			--location_type="relative_ref" \
			--encoding=$(file -b --mime-encoding "$3") \
			--size=$(stat --printf="%s" "$3") \
			--modification_time=$(stat --printf="%y" "$3" | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--update_time=$(stat --printf="%z" "$3" | \
				sed "s/://g" | \
				sed "s/-//g" | \
				sed "s/ /T/" | \
				cut -b1-15 ) \
			--hash=$(cksum "$3" | cut -f 1 -d' ') \
			--output_of=$1 \
			--instance=$2 \
			$GENERATED_BY \
		)
			
	fi
	[ -n "$id_container" ] || exit -1

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
	
SSREPI_input() {

	# $1 - id_application
	# $2 - id_container_type PREFIX
	# $3 - pattern

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_container_type=$id_application.$2
	id_input_type=$(update.py \
		--table=ContainerType \
		--id_container_type=$id_container_type \
		--format='text/plain' \
		--identifier="name:$3" \
	)	
	[ -n "$id_input_type" ] || exit -1

	id_uses=$(update.py \
		--table=Uses \
		--optionality=required \
		--application=$1 \
		--container_type=$id_container_type \
		--in_file=$id_input_type \
		--locator="CWD PATH REGEX:$3" \
	)	
	[ -n "$id_uses" ] || (unset $id_input_type && exit -1)

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_input_type
}

SSREPI_input_value() {

	# $1 - id_application
	# $2 - id_process
	# $3 - id_container_type
	# $4 - path to object

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [ ! -e $4 ]
	then
		(>&2 echo "$FUNCNAME: Something seriously wrong in the call \"--SSREPI-input-$id_container_type=$4\": $4 does not exist")
		exit -1 
	fi

	id_container=
	if [ -d $4 ]
	then
		id_container=$(update.py \
			--table=Container \
			--id_container=container.$(cksum $4 | awk '{print $1}') \
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
		id_container=$(update.py \
			--table=Container \
			--id_container=container.$(cksum $4 | awk '{print $1}') \
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
	[ -n "$id_container" ] || exit -1
	

	id_input=$(update.py \
		--table=Input \
		--usage=data \
		--process=$2 \
		--container=$id_container \
	)
	[ -n "$id_input" ] || exit -1
}
SSREPI_hutton_person() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if ! _getent passwd $1 >/dev/null 2>/dev/null 
	then
		(>&2 echo "$FUNCNAME: $0 at $BASH_LINENO: Invalid user supplied: $1")
		exit 1
	fi
        NAME=$(_getent passwd $1 | cut -f 5 -d:)
        EMAIL=$(echo $NAME | sed "s/ /./g")"@hutton.ac.uk"
	USER_HOME=$(_getent passwd $1 | cut -f 6 -d:)

        id_person=$(update.py \
                --table=Person \
                --id_person=$1 \
                --name="$NAME" \
                --email=$EMAIL \
                )
        [ -n "$id_person" ] || exit -1

        id_user=$(update.py \
                --table=User \
                --home_dir=$USER_HOME \
                --account_of=$id_person \
                --id_user=$1 \
                )
        [ -n "$id_user" ] || exit -1

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_person
}
SSREPI_person() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_person=$(update.py \
		--table=Person \
		$@ \
	)	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_person
}
SSREPI_project() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [[ "$@" != *--id_project* ]]
	then
		(>&2 echo "$FUNCNAME: $0 at $BASH_LINENO: No project id has been provided")
		echo ""
		exit -1
	fi
	id_project=$(update.py \
		--table=Project \
		$@
	)	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_project
}
SSREPI_study() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_study=$(update.py \
		--table=Study \
		$@ \
	)
	echo $id_study
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_set() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	# You would think that this should be done in the function above.
	# However the script above is called by command substitution, which is
	# a subprocess. A subprocess for which all environment variables are
	# wiped out, as soon as it terminates. So we have to do this directly.
	STANDARD_ARGS=
	while [[ $# -gt 0 ]]; do
		case $1 in
			--study*) 
				STUDY=$(echo $1 | sed 's/\-\-study=//')
				export SSREPI_STUDY=$STUDY
				export GENERATED_BY=--generated_by=$SSREPI_STUDY
				shift;;
		        --model*) 
				export STANDARD_ARGS="$STANDARD_ARGS $1"
				shift;;
		        --licence*) 
				export STANDARD_ARGS="$STANDARD_ARGS $1"
				shift;;
			--version*) 
				export STANDARD_ARGS="$STANDARD_ARGS $1"
				shift;;
		esac
	done
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_involvement() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_involvement=$(update.py \
		--table=Involvement \
		--study=$1 \
		--person=$2 \
		--role=$3 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_paper() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
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

	id_paper_container_type=$(update.py \
		--table=ContainerType \
		--id_container_type=paper \
		--description="Published or draft paper" \
		--format='application/pdf;application/msword' \
		--identifier=magic:'^.*Microsoft Word*$;magic:^.*PDF Document.*$' \
	)
	[ -n "$id_paper_container_type" ] || exit -1

	id_container=$(update.py \
		--table=Container \
		--id_container=container.$(cksum "$DOC" | awk '{print $1}') \
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
		--instance=$id_paper_container_type \
		$GENERATED_BY \
		)
	[ -n "$id_container" ] || exit -1
	

	id_paper=$(update.py \
		--table=Documentation \
		--id_documentation="$DOC" \
		--title=$(basename "$DOC") \
		--describes=$describes \
		)
		#--date=$date \
		#--location=$id_container \
	[ -n "$id_paper" ] || exit -1

	id_container=$(update.py \
		--table=Container \
		--id_container=$id_container \
		--location_type="relative_ref" \
		--location_value=$(readlink -f "$DOC") \
		--location_documentation=$id_paper \
		)
	[ -n "$id_container" ] || exit -1

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_container

}
SSREPI_make_tag() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_tag=$(update.py \
		--table=Tag \
		--id_tag=$1 \
		--description=$2 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_tag
}
SSREPI_tag() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_tag_map=$(update.py \
		--table=TagMap \
		--target_tag=$1 \
		$2
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_contributor() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	# $1 id_application
	# $2 contributor
	# $3 type of contribution

	id_contributor=$(update.py \
		--table=Person \
		--email=$2@$(hostname) \
		--id_person=$2 \
		--name=$2 \
	)
	if [[ $(exists.py --table=Application --id_application=$1) == True ]]
	then
		id_contributor=$(update.py \
			--table=Contributor \
			--application="$1" \
			--contributor=$id_contributor \
			--contribution="$3" \
		)
	elif [[ $(exists.py --table=Container --id_container=$1) == True ]]
	then
		id_contributor=$(update.py \
			--table=Contributor \
			--documentation="$1" \
			--contributor=$id_contributor \
			--contribution="$3" \
		)
	else
		(>&2 echo "$FUNCNAME: $1 neither application nor container")
		exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_pipeline() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_pipeline=$(update.py \
		--table=Pipeline \
		--id_pipeline=pipeline.$1 \
		--calls_application=$1 \
	)
	[ -n "$id_pipeline" ] || exit -1
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_pipeline
}
SSREPI_statistical_method() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_statistical_method=$(update.py \
		--table=StatisticalMethod \
		--id_statistical_method=$1 \
		--description=$2 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo "$id_statistical_method"
}
SSREPI_visualisation_method() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_visualisation_method=$(update.py \
		--table=VisualisationMethod \
		--id_visualisation_method=$1 \
		--description=$2 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo "$id_visualisation_method"
}

SSREPI_statistics() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_statistics=$(update.py \
		--table="Statistics" \
		--id_statistics=$1 \
		--date=$(date "+%Y%m%dT%H%M%S") \
		--used=$2 \
		--query=$3 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_statistics
}
SSREPI_visualisation() {

	# $1 - id_visualisation
	# $2 - method - points at VisualisationMethod
	# $3 - the means by  which the visualisation is produced
	# $4 - the container for the visualisation
	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [ -z $4 ] || [ ! -f $4 ]
	then
		(>&2 echo "$FUNCNAME: Unable to find $4")
		exit -1
	fi
	id_container=container.$(cksum $4 | awk '{print $1}')

	# The previous few lines are a real hack. This needs to be done better.
	# These objects should be returned as part of the _run() method. Using
	# the cksum is contrived IPC, i.e. the spawned process in _run()
	# talking to the calling process. This will "always" work, but it is
	# invisible to the coder and can easily be missed and thus broken in
	# future releases.  Hmmmmm, need to think about this, but for now we
	# will hack.

	id_visualisation=$(update.py \
		--table="Visualisation" \
		--id_visualisation=$1 \
		--date=$(date "+%Y%m%dT%H%M%S") \
		--visualisation_method=$2 \
		--query=$3 \
		--contained_in=$id_container \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_visualisation
}
SSREPI_employs() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_employs=$(update.py \
		--table=Employs \
		--statistical_variable=$1 \
		$2 \
		)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

SSREPI_implements() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_implements=$(update.py \
		--table=Implements \
		--application=$1 \
		$2 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

SSREPI_parameter() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_parameter=$(update.py \
		--table=Parameter \
		--id_parameter=$1 \
		--description=$2 \
		--data_type=$3 \
		$4 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_parameter
}
SSREPI_statistical_variable() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	# $1 - id_statistical_variable
        # $2 - Description
        # $3 - data type	
	# $4 - generated_by

	id_statistical_variable=$(update.py \
		--table=StatisticalVariable \
		--id_statistical_variable=$1 \
		--description=$2 \
		--data_type=$3 \
		--generated_by=$4 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_statistical_variable
}
SSREPI_variable() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	# $1 - id_variable
	# $2 - description
	# $3 - data_type

	# So a variable may be one of:

	# * Argument
	# * Assumes
	# * Content
	# * Value

	extra=
	if [[ "$@" = *--link* ]]
	then 
		extra==--is_link=1
	elif [[ "$@" = *--space* ]]
	then 
		extra==--is_space=1
	elif [[ "$@" = *--time* ]]
	then 
		extra==--is_time=1
	elif [[ "$@" = *--agent* ]]
	then 
		extra==--is_agent=1
	fi
	id_variable=$(update.py \
		--table=Variable \
		--id_variable=$1 \
		--description=$2 \
		--data_type=$3 $extra \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_variable
}
SSREPI_value() {

	# $1 - value
	# $2 - id_variable
	# $3 - file/image/visualisation/db in which it resides (the container)
	# Any other arguments to specify this more accurately.

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	val=$1
	shift 
	id_variable=$1
	shift
	if [ ! -x $1 ]
	then
		(>&2 echo "$FUNCNAME Unable to find $1")
		exit -1
	fi
	id_container=container.$(cksum $1 | awk '{print $1}')
	shift

	# The last line is a real hack. This needs to be done better. These
	# objects should be returned as part of the _run() method. Using the
	# cksum is contrived IPC, i.e. the spawned process in _run() talking to
	# the calling process. This will "always" work, but it is invisible to
	# the coder and can easily be missed and thus broken in future
	# releases.  Hmmmmm, need to think about this, but for now we will
	# hack.

	id_value=$(update.py \
		--table=Value \
		--id_value=$val \
		--variable=$id_variable \
		--contained_in=$id_container \
		$@
	)
	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_content() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_content=$(update.py \
		--table=Content \
		$@)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_content
}

SSREPI_person_makes_assumption() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_assumption=$(update.py \
		--table=Assumption \
		--id_assumption=$2 \
		--description=$3 \
		)
	if [ -z "$id_assumption" ] 
	then
		unset id_assumption
		exit -1
	fi
	id_assumes=$(update.py \
		--table=Assumes \
		--person=$1 \
		--assumption=$id_assumption)
	if [ -z "$id_assumes" ] 
	then
		unset id_assumption
		exit -1
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo "$id_assumption"
}

_ip_address() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	IP=$(/sbin/ifconfig | sed -n "2p" | awk '{print $2}' |cut -f2 -d:)
	if [[ $(uname -s) == "Darwin" ]]
	then
		IP=$(/sbin/ifconfig en0 | sed -n "5p" | awk '{print $2}' |cut -f2 -d:)
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo "$IP"
}

_mac_address() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	MAC=$(/sbin/ifconfig | sed -n "1p" | awk '{print $5}')
	if [[ $(uname -s) == "Darwin" ]]
	then
		MAC=$(/sbin/ifconfig en0 | sed -n "3p" | awk '{print $2}')
	fi
        if [ -z "$MAC" ]
        then 
		MAC=$(/sbin/ifconfig | sed -n "4p" | awk '{print $2}')
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo "$MAC"
}

_fqdn() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	# I have had to write this because of the way /etc/hosts have been set
	# up wth the canonical name for the machine is first and in our
	# /etc/hosts this is the shortname rather than the long name, so I am
	# going to use nslookup to get around this.

	if hostname -f | grep -qs "\."
	then 
		hostname -f 
	else
		nslookup -host $(hostname) | grep ^Name | awk '{print $2}'
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

_parent_script() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	# Should be able to do this in one line, but bash doesn't like it for
	# some reason

	ME=$BASHPID
	BASH_PROB=$(ps -o args= $ME)
	if [[ "$BASH_PROB" == *-xv* ]]
	then
		RESULT=$(echo $BASH_PROB | awk '{print $3}') 
	elif [[ "$BASH_PROB" = *-zsh* ]]
	then
		RESULT=$0
	else
		RESULT=$(echo $BASH_PROB | awk '{print $2}') 
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $RESULT
}

uniq() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

_getent() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
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
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

disk_space() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	SPACE=$(df -k -h . | tail -1 | awk '{print $1}' | sed 's/G$//')
	if [[ $(uname -s) == "Darwin" ]]
	then
		SPACE=$(df -k . | tail -1 | awk '{print $4}' | sed 's/G$//')
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $SPACE
}

memory() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	MEM=
	if [[ $(uname -s) == "Darwin" ]]
	then
		MEM=$(echo $(sysctl hw.memsize | cut -f2 -d' ') / 1024 / 1024 / 1024 | bc)
	else
		MEM=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $MEM
}
cpus() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	CPUS=
	if [[ $(uname -s) == "Darwin" ]]
	then
		CPUS=$(sysctl hw.ncpu | cut -f2 -d ' ')
	else
		CPUS=$(($(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1) + 1))
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $CPUS

}
