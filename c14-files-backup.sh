#!/bin/bash

# Usage :
# bash c14-files-backup.sh [dev or nothing]

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

# Get C14 variables if needed
if [ -z $userToken ]; then
    source $rootPath/c14-get-infos.sh $dev
fi

# Get informations about the last bucket if needed
if [ -z $bucketId ] || [ -z $bucketArchiveId ]; then
    source $rootPath/c14-get-last-bucket.sh $dev
fi

# Stop the script if SSH is not in the protocol's array
if [ -z $bucketSshPath ]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : Before you create a bucket, you need to specify SSH in the protocol's array to proceed an rsync with C14"
    exit 1
fi

# Preparation of folders to backup
sendToBackupPaths=""
for toBackupPath in ${toBackupPaths[@]}; do
    sendToBackupPaths="$sendToBackupPaths $toBackupRootPath/$toBackupPath"
done

# If a DB is defined, DB backups are included to rsync
if [[ -v dbName ]] && [[ $dbName != "" ]] && [[ -v dbUser ]] && [[ $dbUser != "" ]] && [[ -v dbPass ]] && [[ $dbPass != "" ]]; then
    sendToBackupPaths="$sendToBackupPaths $rootPath/dbbackups"
fi

# Files backup to C14
sshpass -p $bucketSshPass rsync -aA --inplace --delete $progress -e "ssh -o StrictHostKeyChecking=no -p $bucketSshPort" $sendToBackupPaths $bucketSshPath