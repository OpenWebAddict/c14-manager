#!/bin/bash

# Usage :
# bash c14-bucket-to-archive.sh [dev or nothing]

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
data='{"duplicates":'$duplicates'}'

# Archive the bucket
# POST /storage/c14/safe/{safe_id}/archive/{archive_id}/archive
postJson=$(curl $s -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    -d $data "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$bucketArchiveId/archive")

if [[ $postJson != true ]]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : The bucket archive failed"
    exit 1
else
    # In dev only, success message
    if [[ $env = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : The bucket has been successfully archived"
    fi
fi