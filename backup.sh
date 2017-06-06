#!/usr/bin/env bash

# CD Here
cd "$(dirname "$0")";

################################################################################
# Vars
################################################################################

# Default vars
localRotate=2;
dropboxBackDirName=${HOSTNAME};
dirs=();
databases=();
tarAsSudo=false;
tarAsSudoPassword=false;

# Import environment variables
. env.sh

# Set the current date
date=$(date +"%Y-%m-%d__%H-%M-%S");






################################################################################
# File backup
################################################################################

# Create the backup directory
mkdir backups/${date};

# Iterate through specified directories and back up
for dir in "${dirs[@]}"; do
    # Get the dir name (actually, not going to use this,
    # comment out for future reference)
    # dirName=$(basename "${dir}");

    # Replace all forward slashes in path with underscores
    dirNameSafe=${dir//\//_};

    # Create gzipped tarball of specified directory
    if [ ${tarAsSudo} = false ]; then
        tar -czf backups/${date}/${dirNameSafe}.tar.gz ${dir};
    else
        if [ ${tarAsSudoPassword} = false ]; then
            sudo tar -czf backups/${date}/${dirNameSafe}.tar.gz ${dir};
        else
            echo ${tarAsSudoPassword} | sudo -S tar -czf backups/${date}/${dirNameSafe}.tar.gz ${dir};
        fi
    fi
done;






################################################################################
# MySQL backup
################################################################################

# Iterate through specified databases and back up
for database in "${databases[@]}"; do
    # Get database variables
    host=${database}_host;
    username=${database}_username;
    password=${database}_password;

    # Dump specified database
    mysqldump -u${!username} -p${!password} -h${!host} ${database} | gzip -9 > backups/${date}/${database}.sql.gz;
done;






################################################################################
# Upload to Dropbox
################################################################################

./Dropbox-Uploader/dropbox_uploader.sh upload backups/${date} ${dropboxBackDirName}/${date}






################################################################################
# Cleanup
################################################################################

# Get count of files in directory
count=0;
for dir in backups/*; do
	count=$((count+1));
done;

# Set the cuttoff
cuttoff=$((count-${localRotate}));

echo ${cuttoff};

# Delete older backups if applicable
if [ ${cuttoff} -gt 0 ]; then

    # Iterate through backup directories
    i=0;
    for dir in backups/*; do

        # Increment var
        i=$((i+1));

        # If we're past the cuttoff, get out of loop
        if [ ${i} -gt ${cuttoff} ]; then
            break;
        fi;

        # Remove directory and contents
        rm -rf ${dir};

    done;

fi;
