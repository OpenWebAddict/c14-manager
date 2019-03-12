#!/bin/bash

# Usage :
# sudo bash oc-update-reverse.sh

# Path of the script
rootPath="$(dirname "$0")"

# Get ownCloud variables if needed
if [ -z $toBackupRootPath ]; then
    source $rootPath/oc-get-infos.sh $dev
fi

# Old ownCloud version control
if [ ! -d $toBackupRootPath".old" ]
then
	echo `date +%Y-%m-%d_%H:%M:%S`" : No old release found"
    exit 1
fi

# Maintenance on : stops cron and apache
source $rootPath/set-maintenance.sh 1
service cron stop
service apache2 stop

# Deactivation of some apps that could be problematic
sudo -u $wwwUser php $toBackupRootPath/occ app:disable activity
sudo -u $wwwUser php $toBackupRootPath/occ app:disable files_pdfviewer
sudo -u $wwwUser php $toBackupRootPath/occ app:disable gallery

# Old folder restoration in the root path
rsync -aAxP --delete --exclude=config --exclude=apps-external --exclude=data $toBackupRootPath".old/" $toBackupRootPath

# Trying to reactivate some unactivated core apps
sudo -u $wwwUser php $toBackupRootPath/occ app:enable activity
sudo -u $wwwUser php $toBackupRootPath/occ app:enable files_pdfviewer
sudo -u $wwwUser php $toBackupRootPath/occ app:enable gallery

# Set of the proper rights
source $rootPath/set-rights.sh

# Maintenance off : starts cron and apache
service apache2 start
service cron start
source $rootPath/set-maintenance.sh 0
