#!/bin/bash
#
# This script creates a new user on the local system.
# You will be prompted to enter the username (login), the person name, and a password.
# The username, password, and host for the account will be displayed.
# sed -i -e 's/\r$//' $0
# Make sure the script is being executed with superuser privileges.
if [[ ${UID} -ne 0 ]]
then
    echo "Please use this script with root privilage (sudo)"
    exit 1
fi
# Get the username (login).
read -p "Enter an username for new user: " USER_NAME
# Get the real name (contents for the description field).
read -p "Enter a description for new user: " DESCRIPTION
# Get the password.
read -sp "Enter a password for new user: " PASSWORD
echo
# Create the account.
useradd -c "${DESCRIPTION}" -m ${USER_NAME} 2> /dev/null
# Check to see if the useradd command succeeded.
# We don't want to tell the user that an account was created when it hasn't been.
if [[ ${?} -ne 0 ]]
then
    echo "Hocam, bu kullanıcı adına sahip biri var, lütfen kullanıcı adını değiştir."
    exit 1
fi
# Set the password.
echo ${PASSWORD} | passwd --stdin $USER_NAME 
# Check to see if the passwd command succeeded.
if [[ ${?} -ne 0 ]]
then
    echo "Hocam biz şifreyi veremedik, bir daha farklı bir şifre deneyin."
    exit 1
fi
# Force password change on first login.
passwd -e $USER_NAME
# Display the username, password, and the host where the user was created.
echo
echo $USER_NAME
echo
echo "$PASSWORD will change."
echo
# If you get bad interpreter error: "sed -i -e 's/\r$//' <script_name>" command first.
