#!/bin/bash

# Usage :
# sudo bash oc-update.sh [ownCloud version]

# Path of the script
rootPath="$(dirname "$0")"

# Get ownCloud variables if needed
if [ -z $toBackupRootPath ]; then
    source $rootPath/oc-get-infos.sh $dev
fi

# Argument control
if [ -z "$1" ]
then
	echo `date +%Y-%m-%d_%H:%M:%S`" : You need to specify a version number as an argument to which you want to update ownCloud, for exemple 10.0.1"
    exit 1
else
    version=$1
fi

# Downloads the new release if needed
if [ ! -f $rootPath"/owncloud-${version}.tar.bz2" ]
then
	wget "https://download.owncloud.org/community/owncloud-${version}.tar.bz2" -P $rootPath
fi

# Maintenance on : stops cron and apache
source $rootPath/set-maintenance.sh 1
service cron stop
service apache2 stop

# Deactivation of some apps that could be problematic
# It may need a resettlement after the update
sudo -u $wwwUser php $toBackupRootPath/occ app:disable activity
sudo -u $wwwUser php $toBackupRootPath/occ app:disable files_pdfviewer
sudo -u $wwwUser php $toBackupRootPath/occ app:disable gallery

# Set folders to exclude
exludeToBackupPaths=""
for toBackupPath in ${toBackupPaths[@]}; do
    exludeToBackupPaths="$exludeToBackupPaths --exclude=$toBackupPath"
done

# Creates a copy of the actual release in a temporary folder just in case
# Custom folders are excluded, they are already saved in C14
rsync -aAxP --delete $exludeToBackupPaths $toBackupRootPath"/" $toBackupRootPath".old"

# Deleting every files in the ownCloud folder
rm -f $toBackupRootPath/*

# Then every folder, except for custom folders
rm -R $toBackupRootPath/apps
rm -R $toBackupRootPath/core
rm -R $toBackupRootPath/l10n
rm -R $toBackupRootPath/lib
rm -R $toBackupRootPath/ocs
rm -R $toBackupRootPath/ocs-provider
rm -R $toBackupRootPath/resources
rm -R $toBackupRootPath/settings
rm -R $toBackupRootPath/temp
rm -R $toBackupRootPath/updater

# Extracts the new release files instead of
tar -xjf $rootPath/owncloud-${version}.tar.bz2 -C /var/www/

# Set of the proper rights
source $rootPath/set-rights.sh

# Exemple files deletion
rm $toBackupRootPath/core/skeleton/Documents
rm $toBackupRootPath/core/skeleton/Photos

# Update execution (can take some time)
sudo -u $wwwUser php $toBackupRootPath/occ upgrade

# Trying to reactivate some unactivated core apps
sudo -u $wwwUser php $toBackupRootPath/occ app:enable activity
sudo -u $wwwUser php $toBackupRootPath/occ app:enable files_pdfviewer
sudo -u $wwwUser php $toBackupRootPath/occ app:enable gallery

# Maintenance off : starts cron and apache
service apache2 start
service cron start
source $rootPath/set-maintenance.sh 0