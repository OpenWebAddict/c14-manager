#!/bin/bash

# Usage :
# bash c14-get-infos.sh [dev or nothing]

# Path of the script
rootPath="$(dirname "$0")"

# Environment : set $dev, $env and $progress if needed
if [ -z ${dev+x} ]; then
    source $rootPath/get-env.sh $1
fi


# C14 variables retrieval in the scope, according to the environment
# platformIds, protocols and sshIds are arrays
userToken=$(xmllint --xpath 'string(infos/userToken)' $rootPath/c14-infos.xml)
safeId=$(xmllint --xpath 'string(infos/safeId)' $rootPath/c14-infos.xml)
description=$(xmllint --xpath 'string(infos/description)' $rootPath/c14-infos.xml)
platformIds=($(xmllint --xpath 'string(infos/platformIds)' $rootPath/c14-infos.xml))
protocols=($(xmllint --xpath 'string(infos/protocols)' $rootPath/c14-infos.xml))
duplicates=$(xmllint --xpath 'string(infos/duplicates)' $rootPath/c14-infos.xml)
archivesRetention=$(xmllint --xpath 'string(infos/archivesRetention)' $rootPath/c14-infos.xml)
parity=$(xmllint --xpath 'string(infos/parity)' $rootPath/c14-infos.xml)
crypto=$(xmllint --xpath 'string(infos/crypto)' $rootPath/c14-infos.xml)
if [[ $dev = "dev" ]]; then
    sshIds=($(xmllint --xpath 'string(infos/sshIdsDev)' $rootPath/c14-infos.xml))
else
    sshIds=($(xmllint --xpath 'string(infos/sshIds)' $rootPath/c14-infos.xml))
fi

# The absence of mandatory variables stops the script
if [ -z $userToken ] || [ -z $safeId ] || [ -z $description ] || [ -z $platformIds ] || [ -z $protocols ] || [ -z $duplicates ] || [ -z $archivesRetention ] || [ -z $parity ] || [ -z $crypto ] || [ -z $sshIds ]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : At least one C14 mandatory environment variable is missing"
    exit 1
fi