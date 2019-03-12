#!/bin/bash

# Usage :
# bash c14-create-bucket.sh [dev or nothing]

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

# Preparation of the plateform id's array
sendPlatformIds=""
for platformId in ${platformIds[@]}; do
    sendPlatformIds=$sendPlatformIds$platformId,
done
sendPlatformIds=${sendPlatformIds::-1}

# Preparation of data to send
sendName=`date +%Y-%m-%d`"-$env"
sendDescription="$description-$env"
data='{"name":"'$sendName'","description":"'$sendDescription'","parity":"'$parity'","crypto":"'$crypto'","protocols":['$sendProtocols'],"ssh_keys":['$sendSshIds'],"days":7,"platforms":['$sendPlatformIds']}'

# Creates the archive
# POST /storage/c14/safe/{safe_id}/archive
postJson=$(curl $s -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    -d $data "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive")

echo `date +%Y-%m-%d_%H:%M:%S`" : The bucket has been successfully created with id $postJson"