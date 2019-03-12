#!/bin/bash

# Usage :
# bash c14-archive-to-bucket.sh [dev or nothing]

# Path of the script
rootPath="$(dirname "$0")"

# Environment : set $dev, $env and $progress if needed
if [ -z ${dev+x} ]; then
    source $rootPath/get-env.sh $1
fi

# Get C14 variables if needed
if [ -z $userToken ]; then
    source $rootPath/c14-get-infos.sh $dev
fi

# Get informations about the last archive if needed
if [ -z $archiveId ] || [ -z $archiveKey ]; then
    source $rootPath/c14-get-last-archive.sh $dev
fi

# Preparation of the protocol's array
sendProtocols=""
for protocol in ${protocols[@]}; do
    sendProtocols=$sendProtocols\"$protocol\",
done
sendProtocols=${sendProtocols::-1}

# Preparation of the SSH Key id's array
sendSshIds=""
for sshId in ${sshIds[@]}; do
    sendSshIds=$sendSshIds\"$sshId\",
done
sendSshIds=${sendSshIds::-1}

# Preparation of data to send
data='{"location_id":"'$archiveLocationId'","rearchive":false,"key":'$archiveKey',"protocols":['$sendProtocols'],"ssh_keys":['$sendSshIds']}'

# Unpacks the bucket
# POST /storage/c14/safe/{safe_id}/archive/{archive_id}/unarchive
postJson=$(curl $s -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    -d $data "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId/unarchive")

if [[ $postJson != true ]]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : The archive unpacking failed"
    exit 1
else
    # In dev only, success message
    if [[ $env = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : The archive has been successfully unpacked"
    fi
fi