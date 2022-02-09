#!/bin/bash

# Should be sourced by the setup_infra.sh script
# Arg1: Path to infraportal installation
# Arg2: Username or UID of account to own the files
# USAGE: ./set_permissions $infraportal_path $USER

# Further reading at https://www.drupal.org/node/244924#linuxservers


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

# Allows full access for user and group, none for other
dir_perm="770"
# Allows user to execute (req. for Drush etc.), group to r+w, none for other
file_perm="760"
# Read only for user and group, none for other
settings_perm="440"

echo "Setting user:group to ${user}:33"
chown -R $user:33 .

echo "Setting directories to $dir_perm"
find . -type d -exec chmod "$dir_perm" '{}' \;

echo "Setting files to $file_perm"
find . -type f -exec chmod "$file_perm" '{}' \;

echo "Adding permissions for sites/"
find sites/ -type d -name files -exec chmod $dir_perm '{}' \;
for d in sites/*/files; do
  find $d -type d -exec chmod $dir_perm '{}' \;
  find $d -type f -exec chmod $file_perm '{}' \;
done

# Setting settings.php to read only for owner and apache
echo "Setting settings.php to $setttings.php"
find sites/ -type f -name settings.php -exec chmod $settings_perm '{}' \;

exit 1
