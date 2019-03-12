#!/bin/bash

# Usage :
# bash c14-get-last-archive.sh [dev or nothing]

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

# Retrieve the archive list of the safe
# GET /storage/c14/safe/{safe_id}/archive
# The returned json is injected in the $reponses variable
archivesJson=$(curl $s -X GET \
    -H "Authorization: Bearer $userToken" \
    -H "X-Pretty-JSON: 1" \
    "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive")

# Returned variables preparation
i=0
lastDate=""
lastKey=""
declare -A archives=()
declare -A archivesDate=()

# For each returned archive
for key in $(jq -r 'keys[]' <<< $archivesJson); do

    # uuid_ref and status retrieval
    archiveArray=($(jq -r ".[$key] | .uuid_ref, .status" <<< $archivesJson))
    archiveId=${archiveArray[0]}
    archiveStatus=${archiveArray[1]}

    # If the archive is active
    if [[ $archiveStatus = "active" ]]; then

        # Call of detailed informations about the archive
        # GET /storage/c14/safe/{safe_id}/archive/{archiveId}/bucket
        archiveInfosJson=$(curl $s -X GET \
            -H "Authorization: Bearer $userToken" \
            -H "X-Pretty-JSON: 1" \
            "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId")

        # Is the archive a bucket ?
        archiveBucket=$(jq -r ".bucket" <<< $archiveInfosJson)

        # If it's not a bucket
        if [[ $archiveBucket = null ]]; then

            # Archive name retrieval
            archiveName=$(jq -r ".name" <<< $archiveInfosJson)

            # If archive's name matches the environment
            if [[ "$archiveName" == *"$env"* ]]; then

                # Archive's date retrieval in an array
                archivesDate[$i]=$(jq -r ".creation_date" <<< $archiveInfosJson)

                # Same thing for the returned json
                archives[$i]=$archiveInfosJson

                # lastDate and lastKey temporarily and arbitrarily set
                lastDate=$(jq -r ".creation_date" <<< $archiveInfosJson)
                lastKey=$i

                ((i++))

            fi

        fi

    fi
done

# If the returned archive's array is not empty and bigger than 1
if [ ${#archivesDate[@]} -ne 0 ] && (( ${#archivesDate[@]} > 1 )); then

    j=0
    # For each archive
    for archiveDate in ${archivesDate[@]}; do

        # Archive's date and lastDate comparison
        if [[ (($archiveDate > $lastDate)) ]]; then

            # lastDate and lastKey change
            lastDate=$archiveDate
            lastKey=$j

        fi

        ((j++))

    done

fi

# If the returned archive's array is not empty
if [ ${#archivesDate[@]} -ne 0 ]; then

    # Set last archive's informations in the scope

    # archiveId is alreay retrieved
    archiveId=$(jq -r ".uuid_ref" <<< ${archives[$lastKey]})

    # Archive's encryption key retrieval
    # GET /storage/c14/safe/{safe_id}/archive/{archive_id}/key
    archiveKey=$(curl $s -X GET \
        -H "Authorization: Bearer $userToken" \
        -H "X-Pretty-JSON: 1" \
        "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId/key")

    # Archive's site id retrieval
    # GET /storage/c14/safe/{safe_id}/archive/{archive_id}/location
    locationJson=$(curl $s -X GET \
        -H "Authorization: Bearer $userToken" \
        -H "X-Pretty-JSON: 1" \
        "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId/location")
    archiveLocationId=$(jq -r ".[].uuid_ref" <<< $locationJson)

    # In dev only, success message
    if [[ $env = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : The last found archive is $archiveId"
    fi

else

    echo `date +%Y-%m-%d_%H:%M:%S`" : No archive was found for the $env environment"
    exit 1

fi