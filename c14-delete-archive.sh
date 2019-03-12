#!/bin/bash

# Usage :
# bash c14-delete-archive.sh [dev or nothing]

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
    source $rootPath/c14-get-old-archive.sh $dev
fi

# If the deletion flag is OK
if [ -n $archiveDeletion ] && [ $archiveDeletion -eq 1 ]; then
    # Delete the archive
    # DELETE /storage/c14/safe/{safe_id}/archive/{archive_id}
    postJson=$(curl $s -X DELETE -H "Content-Type: application/json" \
        -H "Authorization: Bearer $userToken" \
        -H "X-Pretty-JSON: 1" \
        "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId")

    # In dev only, success message
    if [[ $dev = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : The deletion of the archive $archiveId has been successfully started"
    fi
fi