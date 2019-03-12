#!/bin/bash

# Usage :
# bash c14-watch-archive.sh [dev or nothing]

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

# Wait for 15 seconds to be sure to be sure that archiving had enough time to launch
sleep 15

# Returned variables preparation
archiveToWatchId=""
archiveJobId=""
archiveJobStatus=""

# Retrieve the archive list of the safe
# GET /storage/c14/safe/{safe_id}/archive
# The returned json is injected in the $reponses variable
archivesJson=$(curl $s -X GET \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive")

# For each returned archive
for key in $(jq -r 'keys[]' <<< $archivesJson); do

    # uuid_ref and status retrieval
    archiveArray=($(jq -r ".[$key] | .uuid_ref, .status" <<< $archivesJson))
    archiveTempId=${archiveArray[0]}
    archiveTempStatus=${archiveArray[1]}

    # If the archive is busy
    if [[ $archiveTempStatus = "busy" ]]; then

        # This is the one to watch
        archiveToWatchId=$archiveTempId

    fi

done

# If we found a busy archive
if [[ $archiveToWatchId != "" ]]; then

    # Retrieve the actions list for an archive
    # GET /storage/c14/safe/{safe_id}/archive/{archive_id}/job
    archiveJobsJson=$(curl $s -X GET \
        -H "Authorization: Bearer $userToken" \
        -H "X-Pretty-JSON: 1" \
        "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveToWatchId/job")

    # Pour chacune des actions (y compris les actions passées)
    # For every actions (passed actions included)
    for key in $(jq -r 'keys[]' <<< $archiveJobsJson); do

        # Type and status retrieval
        archiveJobs=($(jq -r ".[$key] | .type, .status" <<< $archiveJobsJson))

        # S'il s'agit d'un archivage et qu'il est en cours
        # If it's an archival and it is in progress
        if [[ ${archiveJobs[0]} = "archive_bucket" ]] && [[ ${archiveJobs[1]} != "done" ]]; then

            # JobId retrieval
            archiveJobId=$(jq -r ".[$key] | .uuid_ref" <<< $archiveJobsJson)

        fi

    done

    # If a job is running
    if [[ $archiveJobId != "" ]]; then

        # While the archival job is not done
        while [[ $archiveJobStatus != "done" ]]; do

            # Calls the job
            # GET /storage/c14/safe/{safe_id}/archive/{archive_id}/job/{job_id}
            archiveJobJson=$(curl $s -X GET \
                -H "Authorization: Bearer $userToken" \
                -H "X-Pretty-JSON: 1" \
                "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveToWatchId/job/$archiveJobId")

            # Update the local job status
            archiveJobStatus=$(jq -r ".status" <<< $archiveJobJson)

            # In dev only, it shows the job progression
            # Warning : the % progression returned by the API doesn't seem to work, and goes from 0 to 100% suddenly
            # That's why the script does not rely on it
            if [[ $env = "dev" ]]; then
                archiveJobProgress=$(jq -r ".progress" <<< $archiveJobJson)
                echo `date +%Y-%m-%d_%H:%M:%S`" : Archiving progression : $archiveJobProgress%"
            fi

            # Waiting 15 seconds or 5 minutes to continue the loop depending on the environment
            if [[ $env = "dev" ]]; then
                sleep 15
            else
                sleep 5m
            fi

        done

        # In dev only, success message
        if [[ $env = "dev" ]]; then
            echo `date +%Y-%m-%d_%H:%M:%S`" : The archiving job for the archive $archiveToWatchId is done"
        fi

    else

        echo `date +%Y-%m-%d_%H:%M:%S`" : No archiving job was found for the archive $archiveToWatchId"
        exit 1

    fi

else

        echo `date +%Y-%m-%d_%H:%M:%S`" : No archiving job was found for the $env environment"
        exit 1

fi