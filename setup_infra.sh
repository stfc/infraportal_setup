#!/bin/bash

set -e

# NOTES
#
# The script should be run with infraportal_setup as the working directory
# infraportal.sql should be present in infraportal_setup and be the most recent database export
# Update and copy/rename DEMO_db_info.env to contain the correct information
# Insertion of database info into docker-composer.yaml relies on placeholder tags of the form {{placeholder}}
#	TODO: Upload docker-compose.yaml with the placeholders to the main repo - the docker-compose file in infraportal_setup can then be removed.
# Use the "u" option to set the current user as owner of the files 



# Using the "-u" flag will set the infraportal files to be owned by $USER
file_owner="33" # Apache UID
while getopts "u" opt; do
    case $opt in
        u )
            file_owner=$SUDO_USER
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done


# In order to setup aliases for composer and drush, this should be run as the user of the server administrator
# Although they are stored in the Drupal container, the "composer" and "drush" commands will work on the host

if [ $USER != "root" ]; then
    echo "Script must be run as root";
    exit 1;
fi;

if [ ! -d "/opt/drupal" ]; then
	echo "Making /opt/drupal";
	mkdir /opt/drupal;
fi;

# Contains the DB secrets - this should end up being provided by GitHub secrets for privacy and security concerns.
source db_info.env

cur_dir=$(pwd)
infraportal_path="/opt/drupal/infrastructure-portal"

# This installation assumes a basic CentOS/SL7 image and so installs the necessary packages. There is scope to move this setup to Aquilon
echo "Starting to setup InfraPortal";
echo "Updating machine and installing git";
sudo yum update -y && sudo yum install git docker-ce docker-compose -y;
if [ ! -d "${infraportal_path}" ]; then
    git clone https://github.com/stfc/infrastructure-portal.git $infraportal_path
fi;
cd $infraportal_path;
echo "Switching to branch $infra_branch";
git checkout $infra_branch;

# Setting database details in settings.php
settings_path='sites/default/settings.php';
cp 'sites/default/default.settings.php' $settings_path;
# variables sourced from db_info.env
db_settings=$(cat <<- END
\$config["system.logging"]["error_level"] = "all"; // hide|some|all|verbose
\$settings["hash_salt"] = "KAJENFL-wewefAKJERNFLKEJ-LEKbdfbRJALKGBREKJGB-AELRGKJB";
\$settings["config_sync_directory"] = "../config";
\$databases["default"]["default"] = array (
    "database" => "$db_name",
    "username" => "$db_user",
    "password" => "$db_passwd",
    "prefix" => "",
    "host" => "$db_container",
    "port" => "$db_port",
    "namespace" => "Drupal\\Core\\Database\\Driver\\mysql",
    "driver" => "mysql",
);
END
)
echo "$db_settings" >> $settings_path;

# The DB dump is moved to a folder that the mysql container will use as part of its startup
echo "Saving website database dump to /opt/drupal/";
# Move back to the script folder
cd $cur_dir

# Copy over db file but do not overwrite if there is an existing one
if [ ! -f "/opt/drupal/infraportal.sql" ]; then
    echo "Copying .sql file to /opt/drupal/";
    if [ -f infraportal.sql ]; then
        cp infraportal.sql /opt/drupal/infraportal.sql;
    else
        echo "Make sure there is a database dump in the same dir as this script named 'infraportal.sql'";
    fi;
else
    read -p "There is already a sql file in /opt/drupal. If this is correct, press enter to continue. Otherwise ctrl-C to exit this script";
fi;

docker_compose_path="${infraportal_path}/docker-compose.yaml";
cp docker-compose.yaml $docker_compose_path;  # Can remove this line once docker-compose is updated in main repo to have placeholder db info

# Replace placeholders with env variables
sed -i "s/{{db_name}}/$db_name/g" $docker_compose_path;
sed -i "s/{{db_user}}/$db_user/g" $docker_compose_path;
sed -i "s/{{db_passwd}}/$db_passwd/g" $docker_compose_path;
sed -i "s/{{db_container}}/$db_container/g" $docker_compose_path;
sed -i "s/{{db_port}}/$db_port/g" $docker_compose_path;


echo "Setting owner to $file_owner"
source ./set_permissions.sh -u $file_owner $infraportal_path

echo "Running as $SUDO_USER. Setting group permissions and aliases now";
usermod -aG docker $SUDO_USER;  # Adds user to group
# exec su -l $SUDO_USER;          # Refreshes groups to avoid having to logout and login
echo "Logout and back in to refresh group memberships"

# Allows drush to be run from the infrastructure-portal dir
echo "alias drush='docker-compose exec drupal /opt/drupal/web/vendor/bin/drush'" >> /home/$SUDO_USER/.bash_aliases;

# Start the containers
systemctl start docker;

echo "Installation complete. Run `docker-compose up` from the infrastructure-portal directory now!"
echo "First time starting up may take longer as the database is imported for the first time"
# Uncomment if infraportal should be automatically started
# docker-compose up &

