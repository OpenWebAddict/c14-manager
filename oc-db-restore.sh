#!/bin/bash

# Usage :
# bash oc-db-restore.sh [dev or nothing]

# Path of the script
rootPath="$(dirname "$0")"

# Environment : set $dev, $env and $progress if needed
if [ -z ${dev+x} ]; then
    source $rootPath/get-env.sh $1
fi

# Get ownCloud variables if needed
if [ -z $toBackupRootPath ]; then
    source $rootPath/oc-get-infos.sh $dev
fi

# If a DB is defined, do the restoration
if [[ -v dbName ]] && [[ $dbName != "" ]] && [[ -v dbUser ]] && [[ $dbUser != "" ]] && [[ -v dbPass ]] && [[ $dbPass != "" ]]; then

    # Path of local DB dumps
    dbPath=$rootPath/dbbackups

    # Searching for the last local DB backup
    backups=""
    for backups in $dbPath/*\.sql ; do
        backup=$backups
    done

    # Drop then restoration of the DB from the dump
    if [ -z "$backup" ]
    then
        echo `date +%Y-%m-%d_%H:%M:%S`" : No DB backup found"
        exit 1
    else
        mysql $v -u $dbUser -p$dbPass -e"DROP DATABASE $dbName;CREATE DATABASE $dbName;USE $dbName;SOURCE $backup;"
    fi

else
    # In dev only, information message
    if [[ $dev = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : One ore more database variable is missing : DB restoration skipped"
    fi
fi