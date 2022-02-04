#!/bin/bash

# Should be sourced by the setup_infra.sh script
# If run manually, the path (full or relative) to the infrastrcture-portal directory will be required
# The "-u" option can be used to set the owner of the files.
# USAGE: ./set_permissions -u $USER
# Will set the files to be owned by the account running the script

set -e

while getopts "u:" opt; do
    case $opt in
        u )
            user="$OPTARG"
            echo "Will set owner of files to: $user"
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done


(return 0 2>/dev/null) && sourced=1 || sourced=0

if [[ $sourced -eq 0 ]]; then
    read -p 'Please enter the path to infrastructure-portal:\n'
    cd ${REPLY}
fi
echo "Moved to $(pwd)"


echo "Locking down directories"
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;    # 750

echo "Locking down files"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;      # 640

if [[ ! -v user ]]; then
    echo '$user not set so defaulting to 33'
    user=33
fi
echo "Setting user:group to ${user}:33"
chown -R $user:33 .

echo "Making ://public writable"
chmod -R 770 sites/default/files

echo "Making */bin executable"
find . -type d -name bin -exec chmod u=rwx,g=rqx,o=  '{}' \; #770
