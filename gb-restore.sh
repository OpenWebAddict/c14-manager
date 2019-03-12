#!/bin/bash

# Usage :
# sudo bash gb-restore.sh [dev or nothing]

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

# Retrieve C14 last bucket informations
source $rootPath/c14-get-last-bucket.sh $dev

# Restore files from the C14 bucket
source $rootPath/c14-files-restore.sh $dev

# Restore the database from the last local dump
source $rootPath/oc-db-restore.sh $dev

# Unset maintenance for ownCloud
if [ -n $useOc ] && [ $useOc -eq 1 ]; then
    source $rootPath/oc-set-maintenance.sh 0
fi