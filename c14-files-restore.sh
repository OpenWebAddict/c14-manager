#!/bin/bash

# Usage :
# sudo bash c14-files-restore.sh [dev or nothing]

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
    `date +%Y-%m-%d_%H:%M:%S`" : Before you create a bucket, you need to specify SSH in the protocol's array to proceed an rsync with C14"
    exit 1
fi

# Preparation of folders to restore
sendToBackupPaths=""
for toBackupPath in ${toBackupPaths[@]}; do
    sendToBackupPaths="$sendToBackupPaths $toBackupRootPath/$toBackupPath"
done

# Files restoration from C14
sshpass -p $bucketSshPass rsync -aA --inplace --delete $progress -e "ssh -o StrictHostKeyChecking=no -p $bucketSshPort" $sendToBackupPaths $toBackupRootPath

# If a DB is defined, DB backups are restored too
if [[ -v dbName ]] && [[ $dbName != "" ]] && [[ -v dbUser ]] && [[ $dbUser != "" ]] && [[ -v dbPass ]] && [[ $dbPass != "" ]]; then
    sshpass -p $bucketSshPass rsync -aA --inplace --delete $progress -e "ssh -o StrictHostKeyChecking=no -p $bucketSshPort" $bucketSshPath"/dbbackups" $rootPath
fi

# Set proper rights on the ownCloud folder
source $rootPath/oc-set-rights.sh