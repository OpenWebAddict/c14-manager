# C14 Manager


# Purpose

This repo allows automatic incremental backup to C14, secure storage solution of online.net. It is designed to work with any solution that one would like to backup regularly.

Initially addressed specifically to OwnCloud, this set of scripts is also (optionally) intended to administer and maintain an OwnCloud instance.


# Prerequisites

Git, sshpass, xmllint, curl and jq.
```bash
sudo apt-get install git sshpass libxml2-utils curl jq
```

No restrictions on the outgoing ports of the host machine, since C14 changes port with each new bucket.


# Compatibility

Tested with Debian 9 "Stretch" and Ubuntu 18.04, using ownCloud 10.0.x.

SQL commands obviously require MariaDB or MySQL to work. They have been tested on MariaDB 15.1.x (Installed by default on Debian 9). 

The set of scripts is coded in bash. It uses some "modern" bash features, so it may have unexpected behavior if run by an older version than bash v4.

Be sure to check the version of your host machine :
```bash
bash --version
```


# Installation (as the current ssh user)

```bash
cd /var/www
git clone https://github.com/OpenWebAddict/c14-manager.git
cd c14-manager
touch oc-infos.xml c14-infos.xml
chmod 644 oc-infos.xml c14-infos.xml
```

- Here is a functional and commented example of the config file `oc-infos.xml` :
```xml
<?xml version="1.0"?>
<infos>
    <useOc><![CDATA[1]]></useOc> <!-- Determines whether you are using ownCloud-specific features during automatic backups -->
    <toBackupRootPath><![CDATA[/var/www/owncloud]]></toBackupRootPath> <!-- Root path of the solution to Backup to C14 -->
    <toBackupPaths><![CDATA[config apps-external data]]></toBackupPaths> <!-- Subfolders of the solution to Backup to C14 -->
    <ocCustomTheme><![CDATA[mytheme]]></ocCustomTheme> <!-- ownCloud Custom theme path, leave empty if you don't have one -->
    <wwwUser><![CDATA[www-data]]></wwwUser> <!-- Web server user, usually www-data on Debian -->
    <sshUser><![CDATA[owa]]></sshUser> <!-- Current user of the host machine that has rights to your git repo and backup files -->
    <dbName><![CDATA[owacloud]]></dbName> <!-- Info about your machine database, leave empty if you do not use any DB -->
    <dbUser><![CDATA[owa]]></dbUser>
    <dbPass><![CDATA[crappypassword]]></dbPass>
    <dbRetention><![CDATA[4]]></dbRetention> <!-- Number of dump of the DB that you want to keep simultaneously -->
</infos>
```

- Here is a functional and commented example of the config file `c14-infos.xml` :
```xml
<?xml version="1.0"?>
<infos>
    <userToken><![CDATA[742289kli256op850pze2b462x3k025f92774594]]></userToken> <!-- Online's user token -->
    <sshIds><![CDATA[2f0285iu-j98p-3f85-s5yt-8574r5bb02a9]]></sshIds> <!-- SSH Key Id of your production machine -->
    <sshIdsDev><![CDATA[2f0285iu-j98p-3f85-s5yt-8574r5bb02b]]></sshIdsDev> <!-- SSH Key Id of your development machine -->
    <safeId><![CDATA[74bg2op2-12gv-784f-652s-r5896f01234n]]></safeId> <!-- C14 safe id -->
    <description><![CDATA[OWA.Backup]]></description> <!-- Description for every archive -->
    <platformIds><![CDATA[2]]></platformIds> <!-- Id(s) of the storage platform(s) de stockage for your archives -->
    <protocols><![CDATA[SSH FTP WEBDAV]]></protocols> <!-- Allowed protocol(s) to join your buckets on C14 -->
    <duplicates><![CDATA[1]]></duplicates> <!-- Number of archives created when a bucket is archived -->
    <archivesRetention><![CDATA[2]]></archivesRetention> <!-- Number of archives to keep simultaneously on C14 -->
    <parity><![CDATA[intensive]]></parity> <!-- Account type used to create buckets -->
    <crypto><![CDATA[aes-256-cbc]]></crypto> <!-- Archival encryption method -->
</infos>
```

- `useOc` can be 0 or 1. Set to 1 if you use this repo to backup an ownCloud instance, otherwise leave it at 0.
- `toBackupPaths` can be a string or a list of strings separated by spaces.
- `ocCustomTheme` is linked to ownCloud, optional and can be left empty. The scripts that use it will only work if the custom theme is stored in the OwnCloud's `apps-external` folder.
- `dbName`,` dbUser` and `dbPass` are optional. Note that backup and restore BDD work for any solution using recent versions of MySQL or MariaDB.

- You can find your Online.net `userToken` here : https://console.online.net/fr/api/access
- You must enter at least one SSH key per environment (dev and prod) here: https://console.online.net/en/account/ssh-keys and write down their respective ids. `sshIds` and` sshIdsDev` can be a string or a list of strings separated by spaces.
- You must create a C14 safe here : https://console.online.net/fr/storage/c14/safe/list and retrieve your `safeId` "xxxx" which is https://console.online.net/fr/storage/c14/archive/list/"xxxx"
- `description` is a string that does not support spaces, be vigilant!
- `platformIds` can be a string or a list of strings separated by spaces. 1 is the id of DC2 (datacenter) and 2 is the id of DC4 (anti-nuclear shelter). It is advisable to choose only one platform to avoid bugs.
- `protocols` can be a string or a list of strings separated by spaces. This repo uses rsync through SSH to perform backups. Backups will not work if you do not choose at least SSH. It is also advisable to choose FTP as well if the machine is completely crashed, so that you can recover your data from any machine.
- It is advisable to leave `duplicates` on 1. A higher number can lead to huge bugs on C14 (infinite archive suppression for exemple).
- `parity` can be "standard","enterprise" or "intensive" depending on the offer you have subscribed to. As this sript executes 3 operations per cycle, it is advisable to use it in "intensive". See https://documentation.online.net/en/c14/offers
- It is advisable to leave `archivesRetention` on 2 for cost reasons. Each archive kept simultaneously on C14 generates a cost.
- `crypto` can be changed to "none", but it is obviously not recommended.


# First usage

Create your first bucket with the command :
```bash
bash c14-create-bucket.sh [dev or nothing]
```

You should see your bucket appear one the web interface https://console.online.net/fr/storage/c14/archive/list/safeId

Perform a first full backup cycle with the command :
```bash
sudo bash gb-backup.sh [dev or nothing]
```

You should now see an archive, then after the command return, a bucket again in the interface https://console.online.net/fr/storage/c14/archive/list/safeId

To automate the next cycles, modify the Cron table by adapting [dev or nothing] according to the environment you are on. In this example the $wwwUser that triggers Cron is www-data for Debian, but it's up to you to adapt it to your distribution :
```bash
sudo crontab -u www-data -e
```

```bash
# Backup on C14 every Wednesday at 04h00
0 4 * * 3 /var/www/lnbcloud/c14-gb-backup.sh [dev or nothing] >> /var/www/lnbcloud/backups.log 2>&1
```

If something goes wrong, a history of the script output will be available in the file /var/www/lnbcloud/backups.log


# Repo structure

This repo allows you to manage remote tasks related to C14 through the C14 API and some local maintenance tasks that are specific to ownCloud.

For this reason, the "flat" structure of the repo files is organized in this way :

- The files rather related to ownCloud and having an impact on the local machine are prefixed by "oc"
- Files that allow interaction with C14 are prefixed by "c14"
- Files allowing to manage a whole life cycle of backup or restoration, and which call a large number of others, are prefixed by "gb" (for global)

The structure of the repo is also designed so that each script can be used individually, to facilitate testing and manual maintenance interventions. An individually launched script is able to fetch the other scripts on which it depends.

Most scripts take a "dev" argument as an input, which, if specified, modifies their behavior by launching them in "dev mode" :
- The environment variables, such as sshIds, fits according to those stored in the xml config files.
- The scripts launched in the dev mode will be "verbose" and will provide a consistent output, especially on the commands curl, rsync and MySQL, but also on the return messages in bash.


# Functioning principles and backup cycles of C14

C14 distinguishes two states for one storage space :
- Temporary storage space or "bucket", remotely reachable through different protocols (SSH, FTP or WebDAV). In this state, one can make backups or restorations. However, the space is not encrypted or isolated from the rest of the world, or even stored on different servers to be sure not to lose its data.
- The archive, which is encrypted with a key, can be reproduced on several medias (the number depends on `duplicates`). It can't be reached except through the C14 API to unarchive it and create a new bucket that contains the files from its original archive.

It is possible to archive a bucket. It will be transformed into an archive.

It is also possible to unarchive an archive. The archive will remain, but a new bucket containing its files will be created. It will not be visible in the safe web interface and will only reappear after the "re-archiving" of the bucket.

After the creation of a bucket, C14 ends up automatically archiving it after 7 days maximum. However, if a bucket was created from an unarchived archive, you can specify that you do not want to re-archive it automatically.

To guarantee the good use of C14, here is the whole life cycle that this repo applies :
- There is always an active bucket per environment and a maxiumum of n archives kept on C14 (n = `archivesRetention`)
- At each cycle, the global script synchronizes the files to this bucket
- Rename it on today's date
- Archive it
- Deletes the oldest archive if the total archives number exceeds `archivesRetention`
- Unarchive the newly created archive, so create a new bucket (with automatic rearchiving option to "false") to update the latest files to be synchronized for the next cycle

It is important to note that, since an archive does not provide any information about the associated SSH key(s), it is not possible to know which environment (dev or prod) belongs to an archive. For this reason, the repo integrates the environment directly into the bucket and archive names, and it is `IMPERATIVE` to keep this logic if you do not want your dev and prod storage spaces to mix.


# Manual use : ownCloud specific commands

Maintenance on or off :
```bash
sudo bash oc-set-maintenance.sh [0 ou 1]
```

Activate or deactivate your custom theme :
```bash
sudo bash oc-set-custom-theme.sh [0 ou 1]
```

Update ownCloud (sensitive) :
```bash
sudo bash oc-update.sh [owncloud version]
```

Cancel the last ownCloud's update (sensitive) :
```bash
sudo bash oc-update-reverse.sh
```


# Manual use : local commands

DB Backup :
```bash
bash oc-db-backup.sh [dev or nothing]
```

DB restore from the last dump (sensitive) :
```bash
bash oc-db-restore.sh [dev or nothing]
```


# Manual use : C14 commands

Create a new bucket for the environment :
```bash
bash c14-create-bucket.sh [dev or nothing]
```

Archive the last bucket of the environment :
```bash
bash c14-bucket-to-archive.sh [dev or nothing]
```

Unpack the last archive of the environment :
```bash
bash c14-archive-to-bucket.sh [dev or nothing]
```

Rename the last bucket with today's date :
```bash
bash c14-rename-bucket.sh [dev or nothing]
```

Monitor the status of a current archiving job :
```bash
bash c14-watch-archive.sh [dev or nothing]
```

Delete the oldest archive that exceeds the retention limit (sensitive) :
```bash
bash c14-delete-archive.sh [dev or nothing]
```

Backup files to the last bucket of the environment :
```bash
bash c14-files-backup.sh [dev or nothing]
```

Restore files from the last bucket of the environment (sensitive) :
```bash
sudo bash c14-files-restore.sh [dev or nothing]
```


# Manual use : global commands

Start a global backup cycle for the environment :
```bash
sudo bash gb-backup.sh [dev or nothing]
```

Fully restore files and the DB from the last bucket of the environment (sensitive) :
```bash
sudo bash gb-restore.sh [dev or nothing]
```


# Portability

Even though it was originally designed for ownCloud, this repo was coded with a relatively high abstraction layer, and is therefore usable to set up backups of any other solution or website to C14, without any change.

The only automated tasks related to ownCloud are called in the "gb-xxxx" files. These maintenance tasks will not be called if you passed the `useOc` variable to 0.

Other very specific ownCloud tasks, such as activating a custom theme, rights set, or ownCloud version update, are not intended to be automated and will not interfere with the proper operation of the repo.

If what you have to back up does not include a database, just leave this information empty in the environment variables.

This repo uses rsync trough SSH to perform a C14 sync. To use FTP or WebDAV instead of rsync for backups and restores, you will need to:
- Choose at least one in the c14-infos.xml configuration file, in addition to SSH
- Probably encode further processing of FTP and/or WebDAV variables near the end of the file c14-get-last-bucket.sh
- Edit the files c14-files-backup.sh and c14-files-restore.sh accordingly


# Documentation

ownCloud : https://doc.owncloud.org/server/10.0/admin_manual/contents.html

C14 : https://documentation.online.net/en/c14/start

Online.net API : https://console.online.net/en/api/

Bash : http://manpagesfr.free.fr/man/man1/bash.1.html

xmllint : http://xmlsoft.org/xmllint.html

jq : https://stedolan.github.io/jq/tutorial/

curl : https://curl.haxx.se/docs/manpage.html
