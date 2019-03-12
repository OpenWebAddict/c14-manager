#!/bin/bash

# Usage :
# bash oc-get-infos.sh [dev or nothing]

# Path of the script
rootPath="$(dirname "$0")"

# Environment : set $dev, $env and $progress if needed
if [ -z ${dev+x} ]; then
    source $rootPath/get-env.sh $1
fi

# ownCloud variables retrieval in the scope, according to the environment
# toBackupPaths is an array
useOc=$(xmllint --xpath 'string(infos/useOc)' $rootPath/oc-infos.xml)
toBackupRootPath=$(xmllint --xpath 'string(infos/toBackupRootPath)' $rootPath/oc-infos.xml)
toBackupPaths=($(xmllint --xpath 'string(infos/toBackupPaths)' $rootPath/oc-infos.xml))
ocCustomTheme=$(xmllint --xpath 'string(infos/ocCustomTheme)' $rootPath/oc-infos.xml)
wwwUser=$(xmllint --xpath 'string(infos/wwwUser)' $rootPath/oc-infos.xml)
sshUser=$(xmllint --xpath 'string(infos/sshUser)' $rootPath/oc-infos.xml)
dbName=$(xmllint --xpath 'string(infos/dbName)' $rootPath/oc-infos.xml)
dbUser=$(xmllint --xpath 'string(infos/dbUser)' $rootPath/oc-infos.xml)
dbPass=$(xmllint --xpath 'string(infos/dbPass)' $rootPath/oc-infos.xml)
dbRetention=$(xmllint --xpath 'string(infos/dbRetention)' $rootPath/oc-infos.xml)

# The absence of mandatory variables stops the script
if [ -z $useOc ] || [ -z $toBackupRootPath ] || [ -z $toBackupPaths ]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : At least one ownCloud mandatory environment variable is missing"
    exit 1
fi