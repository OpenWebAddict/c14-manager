#!/bin/bash

# Usage :
# sudo bash oc-set-maintenance.sh [0 ou 1]

# Path of the script
rootPath="$(dirname "$0")"

# Get ownCloud variables if needed
if [ -z $toBackupRootPath ]; then
    source $rootPath/oc-get-infos.sh $dev
fi

configfile=$toBackupRootPath"/config/config.php"

if [ -z "$1" ]
then
	maintenance=1
elif [ "$1" = "1" ]
then
	maintenance=1
elif [ "$1" = "0" ]
then
	maintenance=0
else
	maintenance=1
fi

if [ $maintenance = 1 ]
then
	sed -i -e "s/'maintenance' => false,/'maintenance' => true,/g" $configfile
else
	sed -i -e "s/'maintenance' => true,/'maintenance' => false,/g" $configfile
fi