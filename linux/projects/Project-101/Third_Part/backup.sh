#!/bin/bash

# Check if we are root privilage or not
if [[ ${UID} -ne 0 ]]
then
    echo "Please use this script with root privilage (sudo)"
    exit 1
fi

# Define the backup directory
BACKUP_DIR="/mnt/backup"

# Define the directories to be backed up
DIRECTORIES=("/home/ec2-user/data")

# Get the hostname of the instance
HOSTNAME=$(hostname -s)

# Get the current date and time
DATE=$(date +%F-%H-%M)

# Print start status message.
echo "Back up will start in seconds..."

# Create the backup directory if it doesn't exist
if [[ ! -d "$BACKUP_DIR" ]]
then
    mkdir "$BACKUP_DIR"
fi

# Iterate through the directories to be backed up
for DIR in "${DIRECTORIES[@]}"
do
    # Create a file name for the backup.
    FILENAME="$BACKUP_DIR/$HOSTNAME-$DATE-$(basename $DIR).tgz"

    # Create the backup by using tar command.
    tar -czvf "$FILENAME" "$DIR"
done

# Or if you have only one directory that you know.
# tar -czvf "$FILENAME" "$DIR"

# Run "sed -i -e 's/\r$//' scriptname.sh" command before running script.

# Print end status message.
echo "Your backup process is done."