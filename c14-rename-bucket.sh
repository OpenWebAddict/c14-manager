#!/bin/bash

# Usage :
# bash c14-rename-bucket.sh [dev or nothing]

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

# Get informations about the last bucket if needed
if [ -z $bucketId ] || [ -z $bucketArchiveId ]; then
    source $rootPath/c14-get-last-bucket.sh $dev
fi

# Preparation of data to send
sendName=`date +%Y-%m-%d`"-$env"
sendDescription="$description-$env"
data='{"name":"'$sendName'","description":"'$sendDescription'"}'

# Rename the archive which the last bucket is derived
# PATCH /storage/c14/safe/{safe_id}/archive/{archive_id}
postJson=$(curl $s -X PATCH -w '%{http_code}' -H "Content-Type: application/json" \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    -d $data "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$bucketArchiveId")

if [[ $postJson != 204 ]]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : The bucket renaming failed"
    exit 1
fi