#!/bin/bash

# Should be sourced by the setup_infra.sh script
# Arg1: Path to infraportal installation
# Arg2: Username or UID of account to own the files
# USAGE: ./set_permissions $infraportal_path $USER

usage() { echo "$0 usage: ./$0 <path_to_infraportal> <target_user>"; exit 1; }

if [[ -z "$1" ]]; then
  echo "No path supplied"
  infraportal_path="/opt/drupal/infrastructure-portal"
else
  infraportal_path="$1"
fi
echo "InfraPortal instance at $infraportal_path will have it permissions changed"


if [[ -z "$2" ]]; then
  echo "No username supplied. Setting owner to apache (UID: 33)"
  user="33"
else
  user="$2"
fi
echo "Will set owner to $user"


cd $infraportal_path || { echo "Failed to move to '$infraportal_path'. Try again" ; exit 1; }
echo "Moved to $(pwd)"

echo "Locking down directories to 750"
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;    # 750

echo "Locking down files to 640"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;      # 640

echo "Setting user:group to ${user}:33"
chown -R $user:33 .

echo "Making ://public writable"
chmod -R 770 sites/default/files

echo "Making */bin executable"
find . -type d -name bin -exec chmod u=rwx,g=rwx,o=  '{}' \; #770

exit 1
