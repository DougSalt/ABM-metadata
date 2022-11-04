#!/usr/bin/env bash

# When this is called from OSX MAKE SURE YOU USE THE ABOVE HASH BANG IN THE
# CALLING PROGRAM. OSX does not support new versions of Bash (because of
# licence stupidity), so their version of bash is antiquated. You need to
# install from other sources. If you do not do the above then the script will
# pick up the older, default version of bash and this script will fail.  You
# have been warned.

# A series of functions to update ssrep.db with an actual run. 

# I have decided to do this in the bash script

# Remember because this is in-line, exit causes a stop program, return to
# abort to calling program.

# The convention here is that any function that starts with an underscore, "_"
# is an internal function.

export PRCESSSES_STARTED=()
export PROCESSES_DONE=()


DEBUG=
if [ -n "$SSREPI_DEBUG" ]
then 
    export DEBUG=1
fi
DEBUG=1

if which create_database.py >/dev/null 2>&1
then
	create_database.py
else
	(>&2 echo "No ssrepi python functions available. 
		Have you set the PATH variable correct?")
	exit -1
fi

# Create some standard containers

id_container_type=$(update.py \
	--table=ContainerType \
	--id_container_type=bash \
	--description="A Bourne-again bash script" \
	--format='text/x-shellscript' \
	--identifier=magic:'^.*shell script text executable.*$' \
)

id_container_type=$(update.py \
	--table=ContainerType \
	--id_container_type=perl \
	--description="A Perl script" \
	--format='text/x-perl' \
	--identifier=magic:'^.*perl script text executable$' \
)

id_container_type=$(update.py \
	--table=ContainerType \
	--id_container_type=R \
	--description="An R  script" \
	--format='text/plain' \
	--identifier=magic:'^.*Rscript script text executable.*'
)

id_container_type=$(update.py \
	--table=ContainerType \
	--id_container_type=elf \
	--description="64bit Linux Executable" \
	--format='application/x-executable' \
	--identifier=magic:'^.*ELF 64-bit LSB executable\, x86-64.*$'
)

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

_process() {
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
			--id_process=process_$(uniq) \
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
    if [[ $(exists.py --table=Application --id_application=$1) == "True" ]]
    then
        id_application=$1
        APP=$(_get_executable $id_application)
	elif [[ ! -f "$APP" ]]
	then
		APP=$(which $0)
        id_application=container_$(cksum $(which $APP) | awk '{print $1}') 
	else
        id_application=container_$(cksum $(which $APP) | awk '{print $1}') 
		shift
	fi

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
		--id_container=$id_application \
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
		--id_application=application_$(cksum $(which $APP) | awk '{print $1}') \
		--location=$id_container \
        --language=$LANGUAGE \
        --name=$(basename $APP) \
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
		if [[ $id_application == _parent_script ]]
		then
			return $id_application
		fi
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

_get_executable() {
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

SSREPI_run() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	_run $@ --blocking $STANDARD_ARGS
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

SSREPI_batch() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [ -n "$SSREPI_SLURM" ]
	then
		if [ -z "$SSREPI_SLURM_PREFIX" ]
		then
            export SSREPI_SLURM_PREFIX=SSREPI_$(uniq)
        fi
    fi
    _run $@ $STANDARD_ARGS
    [ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

_run() {
    [ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

    if [ -z "$SSREPI_MAX_PROCESSES" ]
    then
        SSREPI_MAX_PROCESSES=4
    fi

    # The reasoning behind the next two lines is that the argument may be
    # an id_application or a path may be passed as the first argument

    APP=$(_get_executable $@)
    id_application=$(SSREPI_me $@)
    shift

    invoking_application=application_$(cksum $(_parent_script) | \
        awk '{print $1}')

    # Now we find the end of the next chain for the the calling application
    # and add to the end of that.

    next_pipe=$invoking_application
    if [[ $(exists.py --table=Pipeline --id_pipeline=$next_pipe ) == True ]]
    then
        next=$(get_value.py \
            --table=Pipeline \
            --id_pipeline=$next_pipe \
            --next \
        ) 
    else
        next_pipe=$(update.py \
            --table=Pipeline \
            --id_pipeline=$next_pipe \
            --calls_application=$invoking_application \
        ) 
        next=None
    fi
    while [[ "$next" != "None" ]]
    do
        next_pipe=$next    
        next=$(get_value.py \
            --table=Pipeline \
            --id_pipeline=$next_pipe \
            --next \
        )
    done
    if [[ $(exists.py --table=Pipeline --id_pipeline=$id_application) == "True" ]]
    then
        our_pipe=$(update.py \
                --table=Pipeline \
                --id_pipeline=${id_application}_$(uniq) \
                --calls_application=$id_application \
        )
     else
        our_pipe=$(update.py \
                --table=Pipeline \
                --id_pipeline=$id_application \
                --calls_application=$id_application \
        )
    fi
    set -xv
    next_pipe=$(update.py \
		    --table=Pipeline \
            --id_pipeline=$next_pipe \
            --next=$our_pipe \
    )
    set +xv


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

    blocking=
    # Remove --blocking
    if [[ "$@" == *--blocking* ]]
    then	
        blocking=1
        PARAMS=$(echo "$PARAMS" | egrep -s "\-\-blocking" | \
            sed "s/--blocking\s*//")
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
    # called here, i.e. at a level lower than this (and we may do this later),
    # but for now we are going to assume that the thing being called has no
    # provenance primitives and we are having to do this external to the
    # script. It makes the coding slightly awkward but leaves a lot of room for
    # speed improvement at a later date. This means the primitives could be
    # embedeed in Perl, R, NetLogo, and elf exectuables. I will put this
    # comment everywhere where we stoop to do provenance at a level higher than
    # it should. I am doing this because this got very confused in my head to
    # start with. To be clear, provenance for a bunch of code should explicitly
    # be done by that code if at all possible.						

    proper_args=
    declare -A argument_value
    position_arg=()
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
                    separator=$(get_value.py \
                        --table=Argument \
                        --application=$id_application \
                        --id_argument=$id_arg \
                        --separator)
                    [ -n "$separator" ] || exit -1
                    if [[ "$separator" == "None" ]]
                    then
                        separator="--"
                    fi
                    assignment_operator=$(get_value.py \
                        --table=Argument \
                        --application=$id_application \
                        --id_argument=$id_arg \
                        --assignment_operator)
                    [ -n "$assignment_operator" ] || exit -1
                    if [[ $assignment_operator == "equal" ]]
                    then
                        assignment_operator="="
                    elif [[ $assignment_operator == "space" ]]
                    then
                        assignment_operator=" "
                    elif [[ $assignment_operator == "None" ]]
                    then
                        assignment_operator=" "
                    fi
                    proper_args="$proper_args ${separator}${name}${assignment_operator}$value"
                else
                    arity=$(get_value.py \
                        --table=Argument \
                        --application=$id_application \
                        --id_argument=$id_arg \
                        --arity)
                    [ -n "$arity" ] || exit -1
                    argsep=$(get_value.py \
                        --table=Argument \
                        --application=$id_application \
                        --id_argument=$id_arg \
                        --argsep)
                    [ -n "$argsep" ] || exit -1
                    if ( [[ $arity == "+" ]] || (( $arity > 1 )) ) && [[ "$argsep" == "space" ]] 
                    then
                        value=$(echo $@ | sed 's/.*\-\-SSREPI\-argument\-'$id_arg'=//' | sed 's/\-\-.*//')
                    fi
                    if [[ $arity != "+" ]] && (( $arity > 1 )) 
                    then
                        if [[ $argsep == "space" ]]
                        then
                            argsep=' '
                        fi
                        actual_nof_args=$(( $(echo $value | grep -o "$argsep" | wc -l) + 1 ))
                        if (( $actual_nof_args != $arity ))
                        then
                            (>&2 echo "$FUNCNAME: Trying to call a script $APP with wrong number of arguments in $id_arg. Asked for $arity, got $actual_nof_args")
                            exit -1
                        fi
                    fi
                    position_arg[$pos]=$value
                fi
                argument_value[$id_arg]=$value
            else
                id_arg=$(echo $arg | sed 's/--SSREPI-argument-//')
                name=$(get_value.py \
                    --table=Argument \
                    --application=$id_application \
                    --id_argument=$id_arg \
                    --name
                )
                [ -n "$name" ] || exit -1
                separator=$(get_value.py \
                    --table=Argument \
                    --application=$id_application \
                    --id_argument=$id_arg \
                    --separator)
                [ -n "$separator" ] || exit -1
                if [[ "$separator" == "None" ]]
                then
                    separator="--"
                fi
                proper_args="$proper_arg ${separator}${name}"
                argument_value[$id_arg]='True'
            fi
        fi
    done

    id_dependency=$(update.py \
        --table=Dependency \
        --optionality=required \
        --dependant=$(SSREPI_me $(_parent_script)) \
        --dependency=$id_application \
    )
    [ -n "$id_dependency" ] || exit -1

    # The bracket means that this in-between code is sub-processed, thus
    # retaining the process's separate identity for terms of provenance.  That
    # is each run of the perl script is associated with a separate

    # It also has the very useful property that I can fork the code into a
    # background process

    if [ -n "$blocking" ]
    then
        (
            THIS_PROCESS=$(_process --executable=$id_application)

            if [ -n "$CWD" ]
            then
                cd "$CWD"
            fi
            for id in "${!argument_value[@]}"
            do
                _argument_value $THIS_PROCESS $id ${argument_value[$id]}
            done
            stdout=
            stderr=
            for arg in $@
            do
                if [[ "$arg" == *--SSREPI-input-* ]]
                then
                    value=$(echo $arg | cut -f2 -d=)
                    input_type_id=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-input-//')
                    _input_value $id_application $THIS_PROCESS $input_type_id $value
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
            [ -n $DEBUG ] && (>&2 echo RUNNING: $APP $proper_args ${position_arg[*]} $stdout $stderr)
            eval $APP $proper_args ${position_arg[*]} $stdout $stderr
            SYS=$?
            if [ $SYS -ne 0 ]
            then
                exit -1
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
                    _output_value $THIS_PROCESS $output_type_id $value
                fi
            done

            THIS_PROCESS=$(_process \
                --id_process=$THIS_PROCESS \
                --executable=$id_application \
                --end_time=$(date "+%Y%m%dT%H%M%S"))

        )
        if [ $? -ne 0 ]
        then
            (>&2 echo "$FUNCNAME: Problem with run for $APP")
            exit -1
        fi
    else
        (
            THIS_PROCESS=$(_process --executable=$id_application)

            if [ -n "$CWD" ]
            then
                cd "$CWD"
            fi
            for id in "${!argument_value[@]}"
            do
                _argument_value $THIS_PROCESS $id ${argument_value[$id]}
            done
            stdout=
            stderr=
            for arg in $@
            do
                if [[ "$arg" == *--SSREPI-input-* ]]
                then
                    value=$(echo $arg | cut -f2 -d=)
                    input_type_id=$(echo $arg | cut -f1 -d= | sed 's/--SSREPI-input-//')
                    _input_value $id_application $THIS_PROCESS $input_type_id $value
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
            
            instances=$(_get_instances $APP)
            while [ $instances -ge $SSREPI_MAX_PROCESSES ]
            do
                [ -n $DEBUG ] && (>&2 echo "$FUNCNAME: Only have $SSREPI_MAX_PROCESSES processes and $instances are running, so ANTE blocking...")
                sleep 10  
                instances=$(_get_instances $APP)
            done

            if [ -z "$SSREPI_SLURM" ]
            then
                # Cannot use $APP here as it will confuse the count in _get_instances
                [ -n $DEBUG ] && (>&2 echo BACKGROUND RUNNING: with arguments $proper_args ${position_arg[*]} $stdout $stderr)
                eval $APP $proper_args ${position_arg[*]} $stdout $stderr
            else

                [ -n $DEBUG ] && (>&2 echo "SLURMING...")
                [ -n $DEBUG ] && (>&2 echo RUNNING: srun --job-name=$SSREPI_SLURM_PREFIX  $APP $proper_args ${position_arg[*]} $stdout $stderr)

                srun --job-name=$SSREPI_SLURM_PREFIX $APP $proper_args ${position_arg[*]} $stdout $stderr
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
                    _output_value $THIS_PROCESS $output_type_id $value
                fi
            done

            THIS_PROCESS=$(_process \
                --id_process=$THIS_PROCESS \
                --executable=$id_application \
                --end_time=$(date "+%Y%m%dT%H%M%S"))
        ) &

		# Check the number of processes running. And if it exceeded then sit here and wait.

		# Dammit these could be initialising but not yet running, so I might get overflow.

        instances=$(_get_instances $APP)
		while [ $instances -ge $SSREPI_MAX_PROCESSES ]
		do
			[ -n $DEBUG ] && (>&2 echo "$FUNCNAME: Only have $SSREPI_MAX_PROCESSES processes and $instances are running, so POST blocking...")
			sleep 10
            instances=$(_get_instances $APP)
		done
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
	id_argument=${id_application}_$1
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

_argument_value() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_argument_value=$(update.py \
		--table=ArgumentValue \
		--for_process=$1 \
		--for_argument=$2 \
		--has_value=$3 \
	)	
}

SSREPI_output() {

	# $1 - id_application
	# $2 - id_container_type
	# $3 - pattern

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_container_type=${id_application}_$2
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

_output_value() {
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
			--id_container=container_$(cksum "$3" | awk '{print $1}') \
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
			--id_container=container_$(cksum "$3" | awk '{print $1}') \
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
	id_container_type=${id_application}_$2
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

_input_value() {

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
			--id_container=container_$(cksum $4 | awk '{print $1}') \
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
			--id_container=container_$(cksum $4 | awk '{print $1}') \
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
	if (( $(_getent passwd $1 | wc -l) != 1 ))
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
    # So if the first argument does not exist
	if [[ ! -f "$DOC" ]]
	then
        (>&2 echo "Paper $DOC does not exist.")
	    exit -1
	fi
	shift
    
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
		--id_container=container_$(cksum "$DOC" | awk '{print $1}') \
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
	echo $id_paper

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
		--tag=$1 \
		$2
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}
SSREPI_contributor() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	# $1 id_application
	# $2 contributor
	# $3 type of contribution

	id_contributor=$2
	if [[ $(exists.py --table=Person --id_person=$2) != True ]]
	then
		id_contributor=$(update.py \
			--table=Person \
			--email=$2@$(hostname) \
			--id_person=$2 \
			--name=$2 \
		)
	fi
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
			--container="$1" \
			--contributor=$id_contributor \
			--contribution="$3" \
		)
	elif [[ $(exists.py --table=Documentation --id_documentation=$1) == True ]]
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

	# A set of statistics

	# $1 - id for this statistic
	# $2 - id for the statistical method
	# $3 - query used to produce the statistics

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
	if [ -z "$4" ] || [ ! -f "$4" ]
	then
		(>&2 echo "$FUNCNAME: Unable to find $4")
		exit -1
	fi
	id_container=container_$(cksum $4 | awk '{print $1}')

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
		--statistic_generated_by=$4 \
	)
	id_employs=$(update.py \
		--table=Employs \
		--statistical_variable=$id_statistical_variable \
		--statistical_method=$4 \
	)
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $id_statistical_variable
}
SSREPI_visualisation_variable() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")

	# $1 - id_visualisation_variable
    # $2 - Description
    # $3 - data type	
	# $4 - generated_by

	id_statistical_variable=$(update.py \
		--table=StatisticalVariable \
		--id_statistical_variable=$1 \
		--description=$2 \
		--data_type=$3 \
		--visualisation_generated_by=$4 \
	)
	id_employs=$(update.py \
		--table=Employs \
		--statistical_variable=$id_statistical_variable \
		--visualisation_method=$4 \
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
SSREPI_statistical_variable_value() {

	# $1 - value
	# $2 - id_statistical_variable
	# $3 - file/image/visualisation/db in which it resides (the container)
	# Any other arguments to specify this more accurately.

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	val=$1
	shift 
	id_variable=$1
	shift
	if [ ! -f $1 ]
	then
		(>&2 echo "$FUNCNAME Unable to find $1")
		exit -1
	fi
	id_container=container_$(cksum $1 | awk '{print $1}')
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
		--statistical_variable=$id_variable \
		--contained_in=$id_container \
		$@
	)
	
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
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
	if [ ! -f $1 ]
	then
		(>&2 echo "$FUNCNAME Unable to find $1")
		exit -1
	fi
	id_container=container_$(cksum $1 | awk '{print $1}')
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
    person=$1
    id_assumption=$2
    description=$3
    shift 3
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	id_assumption=$(update.py \
		--table=Assumption \
		--id_assumption=$id_assumption \
		--description=$description \
		)
	if [ -z "$id_assumption" ] 
	then
		unset id_assumption
		exit -1
	fi
	id_assumes=$(update.py \
		--table=Assumes \
		--person=$person \
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
	elif [[ "$BASH_PROB" = *_parent_script* ]]
	then
		RESULT=CLI
	else
		RESULT=$(echo $BASH_PROB | awk '{print $2}') 
	fi
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
	echo $RESULT
}

uniq() {
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	#cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
	cat /dev/urandom | tr -dc '0-9' | fold -w 32 | head -n 1
	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: ...exit.")
}

_getent() {

    # $1 - type of database, e.g. passwd
    # $2 - user or thing filtering on

	[ -n "$DEBUG" ] && (>&2 echo "$FUNCNAME: entering...")
	if [[ "$1" != "passwd" ]]
	then
		echo "This only works for 'passwd'"
		exit -1
	fi
	if [[ $(uname -s) != "Darwin" ]]
	then
		getent passwd $2
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

_get_instances() {
    if [ -z "$SSREPI_SLURM" ]
    then
        instances=$(ps -A -o command | grep $1 | grep -v grep | wc -l)
    else
        instances=$(( $(squeue -t RUNNING --name=$SSREPI_SLURM_PREFIX | wc -l) - 1 ))
        if [ -n "$SSREPI_SLURM_PENDING_BLOCKS" ]
        then
            instances=$(($instances + $(( $(squeue -t PENDING --name=$SSREPI_SLURM_PREFIX | wc -l) -1 )) ))
        fi
    fi
    echo $instances
}

