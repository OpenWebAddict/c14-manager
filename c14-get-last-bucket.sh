#!/bin/bash

# Usage :
# bash c14-get-last-bucket.sh [dev or nothing]

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
declare -A buckets=()
declare -A bucketsDate=()
declare -A bucketsArchiveId=()

# For each returned archive
for key in $(jq -r 'keys[]' <<< $archivesJson); do

    # uuid_ref and status retrieval
    archiveArray=($(jq -r ".[$key] | .uuid_ref, .status" <<< $archivesJson))
    archiveId=${archiveArray[0]}
    archiveStatus=${archiveArray[1]}

    # If the archive is active
    if [[ $archiveStatus = "active" ]]; then

        # Call of detailed informations about the bucket
        # GET /storage/c14/safe/{safe_id}/archive/{archiveId}/bucket
        bucketInfosJson=$(curl $s -X GET \
            -H "Authorization: Bearer $userToken" \
            -H "X-Pretty-JSON: 1" \
            "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId/bucket")

        # Does the bucket return an error ? ( If yes, its' probably an archive : error code 7 )
        bucketInfosError=$(jq -r ".error" <<< $bucketInfosJson)

        # If there is no error
        if [[ $bucketInfosError = null ]]; then

            # Call of detailed informations about the archive from which the bucket is derived
            # GET /storage/c14/safe/{safe_id}/archive/{archiveId}
            bucketArchiveInfosJson=$(curl $s -X GET \
            -H "Authorization: Bearer $userToken" \
            -H "X-Pretty-JSON: 1" \
            "https://api.online.net/api/v1/storage/c14/safe/$safeId/archive/$archiveId")

            # Archive name retrieval from which the bucket is derived
            bucketName=$(jq -r ".name" <<< $bucketArchiveInfosJson)

            # If bucket's name matches the environment
            if [[ "$bucketName" == *"$env"* ]]; then

                # The archive id from which the bucket is derived is stored in an array
                bucketsArchiveId[$i]=$archiveId

                # Bucket's date retrieval in an array
                bucketsDate[$i]=$(jq -r ".archival_date" <<< $bucketInfosJson)

                # Same thing for the returned json
                buckets[$i]=$bucketInfosJson

                # lastDate and lastKey temporarily and arbitrarily set
                lastDate=$(jq -r ".archival_date" <<< $bucketInfosJson)
                lastKey=$i

                ((i++))

            fi

        fi

    fi
done

# If the returned bucket's array is not empty and bigger than 1
if [ ${#bucketsDate[@]} -ne 0 ] && (( ${#bucketsDate[@]} > 1 )); then

    j=0
    # For each bucket
    for bucketDate in ${bucketsDate[@]}; do

        # Bucket's date and lastDate comparison
        if [[ (($bucketDate > $lastDate)) ]]; then

            # lastDate and lastKey change
            lastDate=$bucketDate
            lastKey=$j

        fi

        ((j++))

    done

fi

# If the returned bucket's array is not empty
if [ ${#bucketsDate[@]} -ne 0 ]; then

    # Set last bucket's informations in the scope

    # variables that are alreay retrieved
    bucketId=$(jq -r ".uuid_ref" <<< ${buckets[$lastKey]})
    bucketArchiveId=${bucketsArchiveId[$lastKey]}

    # In dev only, success message
    if [[ $env = "dev" ]]; then
        echo `date +%Y-%m-%d_%H:%M:%S`" : The last found bucket is $bucketArchiveId"
    fi

    # Connection variables retrieval according to the defined environment protocols
    k=0
    archiveProtocols=($(jq -r ".credentials[].protocol" <<< ${buckets[$lastKey]} | tr '[:lower:]' '[:upper:]'))
    for archiveProtocol in ${archiveProtocols[@]}; do

        if [[ $archiveProtocol = "SSH" ]] && [[ "${protocols[*]}" =~ "SSH" ]]; then

            # Raw SSH variables
            bucketSshLogin=$(jq -r ".credentials[$k].login" <<< ${buckets[$lastKey]})
            bucketSshPass=$(jq -r ".credentials[$k].password" <<< ${buckets[$lastKey]})
            bucketSshUri=$(jq -r ".credentials[$k].uri" <<< ${buckets[$lastKey]})

            # Grep on the uri to extract the SHH port
            bucketSshPort=$(grep -Po ':[0-9]{3,6}' <<< $bucketSshUri)
            bucketSshPort="${bucketSshPort/:/''}"

            # Path : deletion of ssh:// and the port at the end, adding buffer at the end
            bucketPath="${bucketSshUri/ssh:\/\//''}"
            bucketSshPath="${bucketPath/$bucketSshPort/''}/buffer"

        elif [[ $archiveProtocol = "FTP" ]] && [[ "${protocols[*]}" =~ "FTP" ]]; then

            # Raw FTP variables : it may need a custom development if you want to backup through FTP
            bucketFtpLogin=$(jq -r ".credentials[$k].login" <<< ${buckets[$lastKey]})
            bucketFtpPass=$(jq -r ".credentials[$k].password" <<< ${buckets[$lastKey]})
            bucketFtpUri=$(jq -r ".credentials[$k].uri" <<< ${buckets[$lastKey]})

        elif [[ $archiveProtocol = "WEBDAV" ]] && [[ "${protocols[*]}" =~ "WEBDAV" ]]; then

            # Raw WebDAV variables : it may need a custom development if you want to backup through WebDAV
            bucketWebdavLogin=$(jq -r ".credentials[$k].login" <<< ${buckets[$lastKey]})
            bucketWebdavpPass=$(jq -r ".credentials[$k].password" <<< ${buckets[$lastKey]})
            bucketWebdavUri=$(jq -r ".credentials[$k].uri" <<< ${buckets[$lastKey]})

        fi
        ((k++))

    done

else

    echo `date +%Y-%m-%d_%H:%M:%S`" : No bucket was found for the $env environment"
    exit 1

fi