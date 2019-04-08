#!/bin/bash
../timing_tool.sh

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Source database details.
source_host="localhost:5432"
source_db="magic_world"
source_user="dumbledore"
source_password="18dUmb1ed0rE81"

# select date range
start_date=2025-01-01
end_date=2042-01-02

# Documents to copy
documents_to_copy="5000"

################
if [ "$1" == "--help" ]; then
	echo "--sourceDatabaseName Source database's name"
	echo "--sourceDatabaseUser Source database's username"
	echo "--sourceDatabasePassword Source database's password"
	echo "--sourceDatabaseHost Source database's host address"
	echo " "
	echo "--documentsToCopy Count of documents intended to be copied"
	echo " "
	echo "--sourceDatabaseStartDate Start date for cloning in YYYY-MM-DD format"
	echo "--sourceDatabaseEndDate End date for cloning in YYYY-MM-DD format"
	echo "Syntax: ./database_to_csv_caching --documentsToCopy 10 --sourceDatabaseHost localhost:5432 --sourceDatabaseName magic_world --sourceDatabaseUser dumbledore --sourceDatabasePassword '18dUmb1ed0rE81' --sourceDatabaseStartDate 2025-01-01 --sourceDatabaseEndDate 2042-01-02"
else
    startTiming

	ARGUMENT_LIST=(
		"sourceDatabaseName"
		"sourceDatabaseUser"
		"sourceDatabasePassword"
		"sourceDatabaseHost"
		"documentsToCopy"
		"sourceDatabaseStartDate"
		"sourceDatabaseEndDate"
	)

	# Read arguments
	opts=$(getopt \
		--longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
		--name "$(basename "$0")" \
		--options "" \
		-- "$@"
	)

	eval set --$opts

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--sourceDatabaseName)
			sdb=$2
			shift 2
			;;
		--sourceDatabaseUser)
			sdbuser=$2
			shift 2
			;;
		--sourceDatabasePassword)
			sdbpassword=$2
			shift 2
			;;
		--sourceDatabaseHost)
			sdbhost=$2
			shift 2
			;;
		--documentsToCopy)
			documents_to_copy=$2
			shift 2
			;;
		--sourceDatabaseStartDate)
			sdate=$2
			shift 2
			;;
		--sourceDatabaseEndDate)
			edate=$2
			shift 2
			;;

		*)
			break
			;;
		esac
	done

	# Check Variable define or not, if not set default value
	[[ -z "$sdb" ]] && sdb="$source_db"
	[[ -z "$sdbuser" ]] && sdbuser="$source_user"
	[[ -z "$sdbpassword" ]] && sdbpassword="$source_password"
	[[ -z "$sdbhost" ]] && sdbhost="$source_host"
	[[ -z "$documents_to_copy" ]] && documents_to_copy="$documentsToCopy"
	[[ -z "$sdate" ]] && sdate="$start_date"
	[[ -z "$edate" ]] && edate="$end_date"

	# Create directory to store tables
	tablesDirectory="tables"

	# Check tables directory
	if [ -d $tablesDirectory ]; then
		echo "$tablesDirectory directory file, removing all contents from it ..."
		rm -rf $tablesDirectory/*
	else
		echo "$tablesDirectory directory not found creating for you ...."
		mkdir $tablesDirectory
	fi

	SCHEMA="public"

	# Full copy tables script
	cat table_list_full | grep -Ev "^$" | while read t_name; do
		PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -Atc "select schema_name from information_schema.schemata" |
            PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "\COPY (SELECT * from $SCHEMA.$t_name ) TO '$tablesDirectory/$SCHEMA.$t_name.csv' DELIMITER ',' CSV HEADER;"
            echo "Copied: $SCHEMA.$t_name"
	done

	# Copy data based on created_at or default 5000 lines.
	cat table_list_short | grep -Ev "^$" | while read t_name; do
		PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -Atc "select schema_name from information_schema.schemata" |
			while read SCHEMA; do
				if [[ "$SCHEMA" != "pg_catalog" && "$SCHEMA" != "information_schema" ]]; then
					PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "select created_at from $SCHEMA.$t_name" &>/dev/null
					if [ $? == 0 ]; then
						echo "Short condition work on $SCHEMA.$t_name"
						PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "\COPY (SELECT * from $SCHEMA.$t_name where created_at between '$sdate' and '$edate' order by created_at desc limit $documents_to_copy) TO 'tables/$SCHEMA.$t_name.csv' DELIMITER ',' CSV HEADER;"
					else
						echo "Short condition not work on $SCHEMA.$t_name"
						PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "\COPY (SELECT * from $SCHEMA.$t_name) TO 'tables/$SCHEMA.$t_name.csv' DELIMITER ',' CSV HEADER;"
        			fi
				fi
			done
	done

	# Copying users
	distributor_types=('COMPANY' 'JOB_SEEKER' 'ADMIN' 'GROUP_USER')
    t_name="users"
    limit_to_copy=100
    for distributor_type in "${distributor_types[@]}"; do
        # Copying companies
        PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -Atc "select schema_name from information_schema.schemata" |
            if [[ "$distributor_type" == "COMPANY" ]]; then
                PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "\COPY (SELECT * from $SCHEMA.$t_name where distributor_type = '$distributor_type' order by created_at desc limit $limit_to_copy) TO '$tablesDirectory/$SCHEMA.$t_name.csv' DELIMITER ',' CSV HEADER;"
            else
                PGPASSWORD="$sdbpassword" psql -h $sdbhost -U $sdbuser $sdb -c "\COPY (SELECT * from $SCHEMA.$t_name where distributor_type = '$distributor_type' order by created_at desc limit $limit_to_copy) TO '$tablesDirectory/$SCHEMA.$t_name.$distributor_type.csv' DELIMITER ',' CSV;"
        fi
            echo "Copied: $SCHEMA.$t_name.$distributor_type"
    done
    cat $tablesDirectory/$SCHEMA.$t_name.*.csv >> "$tablesDirectory/$SCHEMA.$t_name.csv"
    rm $tablesDirectory/$SCHEMA.$t_name.*.csv

    finishTiming
fi
