#!/bin/bash
../timing_tool.sh

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Source database details.
source_host="localhost:5432"
source_db="magic_world"
source_user="dumbledore"
source_password="18dUmb1ed0rE81"

# Destination database
destination_host="db.localhost.mil"
destination_db="magic_world"
destination_user="dumbledore64"
destination_password="18dUmb1ed0rE81"

################
if [ "$1" == "--help" ]; then
    echo "--sourceDatabaseName Source database's name"
    echo "--sourceDatabaseUser Source database's username"
    echo "--sourceDatabasePassword Source database's password"
    echo "--sourceDatabaseHost Source database's host address"
    echo " "
    echo "--destinationDatabaseName Destination database's name"
    echo "--destinationDatabaseUser Destination database's username"
    echo "--destinationDatabasePassword Destination database's password"
    echo "--destinationDatabaseHost Destination database's host address"
    echo " "
    echo "Syntax: ./csv_to_database_migration.sh --sourceDatabaseHost localhost:5432 --sourceDatabaseName magic_world --sourceDatabaseUser dumbledore --sourceDatabasePassword '18dUmb1ed0rE81' --destinationDatabaseHost db.localhost.mil --destinationDatabaseUser dumbledore64 --destinationDatabaseName db.localhost.mil --destinationDatabasePassword 18dUmb1ed0rE81"
else
    startTiming

    ARGUMENT_LIST=(
        "sourceDatabaseName"
        "sourceDatabaseUser"
        "sourceDatabasePassword"
        "sourceDatabaseHost"
        "destinationDatabaseName"
        "destinationDatabaseUser"
        "destinationDatabasePassword"
        "destinationDatabaseHost"
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
        --destinationDatabaseName)
            ddb=$2
            shift 2
            ;;
        --destinationDatabaseUser)
            ddbuser=$2
            shift 2
            ;;
        --destinationDatabasePassword)
            ddbpasswrod=$2
            shift 2
            ;;
        --destinationDatabaseHost)
            ddbhost=$2
            shift 2
            ;;
        *)
            break
            ;;
        esac
    done
    # Check variable define or not, if not set default value
    [[ -z "$sdb" ]] && sdb="$source_db"
    [[ -z "$sdbuser" ]] && sdbuser="$source_user"
    [[ -z "$sdbpassword" ]] && sdbpassword="$source_password"
    [[ -z "$sdbhost" ]] && sdbhost="$source_host"

    [[ -z "$ddb" ]] && ddb="$destination_db"
    [[ -z "$ddbuser" ]] && ddbuser="$postdestination_user"
    [[ -z "$ddbpasswrod" ]] && ddbpasswrod="$destination_password"
    [[ -z "$ddbhost" ]] && ddbhost="$destination_host"

    # Create directory to store tables
    tablesDirectory="tables"

    # Check destination database.
    if PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser -lqt | cut -d \| -f 1 | grep -qw $ddb; then
        echo "Database exists"
    else
        PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser -c "create database $ddb"
        if [ $? == 0 ]; then
            echo "Database successfully was created."
        else
            echo "Database creation failed!"
        fi
    fi

    # Drop all tables from destination database
    TABLES=$(PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb -t --command "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public'")
    echo Dropping tables:${TABLES}
    PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb --command "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

    # Create tables on destination database.
    PGPASSWORD="$sdbpassword" pg_dump -h $sdbhost -U $sdbuser --disable-trigger -s -d $sdb | PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb 2>/dev/null

    dataCopy () {
        SCHEMA="public"
        [[ -z "$tableName" ]] && tableName="$1"

        PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb --command "alter TABLE $SCHEMA.$tableName DISABLE TRIGGER ALL"
        PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb -c "\copy $SCHEMA.$tableName from '$tablesDirectory/$SCHEMA.$tableName.csv' DELIMITER ','  CSV HEADER;"
        PGPASSWORD="$ddbpasswrod" psql -h $ddbhost -U $ddbuser $ddb --command "alter TABLE $SCHEMA.$tableName ENABLE TRIGGER ALL"
    }

    # Full copy tables script
    cat table_list_full | grep -Ev "^$" | while read tableName; do
        dataCopy $tableName
    done

    # Copy Data based on Created_at or default 5000 lines.

    cat table_list_short | grep -Ev "^$" | while read tableName; do
        dataCopy $tableName
    done

    dataCopy users

    finishTiming
fi
