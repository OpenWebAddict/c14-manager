#!/bin/bash

# Usage :
# sudo bash oc-set-custom-theme.sh [0 ou 1]

# Path of the script
rootPath="$(dirname "$0")"

# Get ownCloud variables if needed
if [ -z $toBackupRootPath ]; then
    source $rootPath/oc-get-infos.sh $dev
fi

# The script stops if no customTheme is defined
if [ -z $ocCustomTheme ]; then
    echo `date +%Y-%m-%d_%H:%M:%S`" : No customTheme is defined to activate or deactivate it"
    exit 1
fi

# Set custom depending on the argument
if [ -z "$1" ]
then
	custom=1
elif [ "$1" = "1" ]
then
	custom=1
elif [ "$1" = "0" ]
then
	custom=0
else
	custom=1
fi

# Custom theme activation or deactivation
if [ $custom = 1 ]
then
	sudo -u $wwwUser php $toBackupRootPath/occ app:enable $ocCustomTheme
else
	sudo -u $wwwUser php $toBackupRootPath/occ app:disable $ocCustomTheme
fi
