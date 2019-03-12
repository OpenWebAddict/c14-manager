#!/bin/bash

# Usage :
# bash oc-db-backup.sh [dev or nothing]

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

# If a DB is defined, do the backup
if [[ -v dbName ]] && [[ $dbName != "" ]] && [[ -v dbUser ]] && [[ $dbUser != "" ]] && [[ -v dbPass ]] && [[ $dbPass != "" ]] && [[ -v dbRetention ]] && [[ $dbRetention != "" ]]; then

    # Path of local DB dumps
    dbPath=$rootPath/dbbackups
    if [ ! -d "$dbPath" ]
    then
        mkdir $dbPath
        chmod -R 775 $dbPath
        chown -R $sshUser:$wwwUser $dbPath
    fi
    currentdate=`date +%Y-%m-%d-%H:%M:%S`
    mysqldump --single-transaction $v -u $dbUser -p$dbPass --databases $dbName > $dbPath"/db-"$currentdate".sql"
    chmod 755 $dbPath"/db-"$currentdate".sql"

    # Deletes the old local DB dumps
    # Max retention is based on the dbRetention environment variable
    i=0
    for backups in $dbPath/*\.sql ; do
        backup[$i]=$backups
        ((i++))
    done
    if [ ${#backup[@]} = $(($dbRetention+1)) ]
    then
        rm ${backup[0]}
    fi

else
    # In dev only, information message
    if [[ $dev = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : One ore more database variable is missing : DB backup skipped"
    fi
fi