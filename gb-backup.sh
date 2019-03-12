#!/bin/bash

# Usage :
# bash gb-backup.sh [dev or nothing]
# Has to be executed by $wwwUser or by sudo/root

# Path of the script
rootPath="$(dirname "$0")"

# Environnement : set de $dev, $env et $progress
source $rootPath/get-env.sh $1

# Get ownCloud variables
source $rootPath/oc-get-infos.sh $dev

# Get C14 variables
source $rootPath/c14-get-infos.sh $dev

# Set maintenance for ownCloud
if [ -n $useOc ] && [ $useOc -eq 1 ]; then
    source $rootPath/oc-set-maintenance.sh 1
fi

# DB local backup
source $rootPath/oc-db-backup.sh $dev

# Retrieve C14 last bucket informations
source $rootPath/c14-get-last-bucket.sh $dev

# Backup files to the C14 bucket
source $rootPath/c14-files-backup.sh $dev

# Unset maintenance for ownCloud
if [ -n $useOc ] && [ $useOc -eq 1 ]; then
    source $rootPath/oc-set-maintenance.sh 0
fi

# Starting now, ownCloud doesn't need to be in maintenance anymore
# But operations are still running on C14

# Rename the C14 bucket with the day's date
source $rootPath/c14-rename-bucket.sh $dev

# C14 bucket archiving
source $rootPath/c14-bucket-to-archive.sh $dev

# Waiting for the end of the archiving
source $rootPath/c14-watch-archive.sh $dev

# Old archive to delete informations retrieval if needed
source $rootPath/c14-get-old-archive.sh $dev

# Old archive deletion if needed
source $rootPath/c14-delete-archive.sh $dev

# Retrieve C14 last bucket informations
source $rootPath/c14-get-last-archive.sh $dev

# Unpacking the archive to a new bucket
source $rootPath/c14-archive-to-bucket.sh $dev