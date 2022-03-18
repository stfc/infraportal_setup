#!/bin/bash

set -e

# NOTES
# BETA
# Use the "u" option to set the current user as owner of the files 
# The script should be run with infraportal_setup as the working directory
# infraportal.sql should be present in infraportal_setup and be the most recent database export
# Update and copy/rename DEMO_db_info.env to contain the correct information
# Insertion of database info into docker-composer.yaml relies on placeholder tags of the form {{placeholder}}
#	TODO: Upload docker-compose.yaml with the placeholders to the main repo - the docker-compose file in infraportal_setup can then be removed.


####
# INITIAL SETUP
####

file_owner="33" # Apache UID
while getopts "u" opt; do
    case $opt in
        u )
            file_owner=$SUDO_USER;;
        \? )
            echo "Invalid option: -$OPTARG" >&2;;
    esac
done

if [ $USER != "root" ]; then
    echo "Script must be run as root";
    exit 1;
fi;

if [ ! -d "/opt/drupal" ]; then
	echo "Making /opt/drupal";
	mkdir /opt/drupal;
  chmod 770 /opt/drupal;
fi;

if [ ! -f "./db_info.env" ]; then
	echo "Please create db_info.env and fill in the database info (copy from DEMO_db_info.env)";
	exit 1
fi;
if [ ! -f "./set_permissions.sh" ]; then
	echo "Could not find set_permissions.sh in working directory. Please run $0 from infraportal_setup/";
	exit 1
fi;

# Contains the DB secrets - this should end up being provided by GitHub secrets for privacy and security concerns.
source db_info.env

infraportal_path="/opt/drupal/infrastructure-portal"

# This installation assumes a basic CentOS/SL7 image and so installs the necessary packages. There is scope to move this setup to Aquilon
# TODO: Add this to the Aquilon profile
packages=(
  "git"
  "docker-ce"
  "docker-compose"
  "haproxy"
);
echo "Starting to setup InfraPortal";
echo "Updating machine and installing: ${packages[@]}";
# sudo yum update -y && sudo yum install ${packages[@]} -y;
if [ ! -d "${infraportal_path}" ]; then
    echo "Cloning infraportal to $infraportal_path"
    echo "Checking out $INFRA_BRANCH"
    echo "git clone --branch $INFRA_BRANCH https://github.com/stfc/infrastructure-portal.git $infraportal_path"
    git clone --branch $INFRA_BRANCH https://github.com/stfc/infrastructure-portal.git $infraportal_path
fi;

####
# DATABASE CREDENTIALS
# variables sourced from db_info.env
####

# settings.php

settings_path="${infraportal_path}/sites/default/settings.php";
cp "${infraportal_path}/sites/default/default.settings.php" $settings_path;
db_settings=$(cat <<- END
\$config["system.logging"]["error_level"] = "hide"; // hide|some|all|verbose
\$settings["hash_salt"] = "$HASH_SALT";
\$settings["config_sync_directory"] = "sites/default/config";
\$databases["default"]["default"] = array (
    "database" => "$DB_NAME",
    "username" => "$DB_USER",
    "password" => "$DB_PASSWD",
    "prefix" => "",
    "host" => "$DB_CONTAINER",
    "port" => "$DB_PORT",
    "namespace" => "Drupal\\Core\\Database\\Driver\\mysql",
    "driver" => "mysql",
);
END
)
echo "$db_settings" >> $settings_path;

# docker-compose.yaml

docker_compose_path="${infraportal_path}/docker-compose.yaml";
cp beta-docker-compose.yaml $docker_compose_path;  # Can remove this line once docker-compose is updated in main repo to have placeholder db info
echo "Copied beta-docker-compose.yaml to $docker_compose_path"

# Replace placeholders with env variables
echo "Doing placeholder substitution for docker-compose"
sed -i "s/{{db_name}}/$DB_NAME/g" $docker_compose_path;
sed -i "s/{{db_user}}/$DB_USER/g" $docker_compose_path;
sed -i "s/{{db_passwd}}/$DB_PASSWD/g" $docker_compose_path;
sed -i "s/{{db_container}}/$DB_CONTAINER/g" $docker_compose_path;
sed -i "s/{{db_port}}/$DB_PORT/g" $docker_compose_path;

####
# GET DATABASE READY FOR IMPORT
####

# The DB dump is moved to a folder that the mysql container will use as part of its startup

db_dump_path="/opt/drupal/infraportal.sql"
echo "Saving website database dump to $db_dump_path";

# Copy over db file but do not overwrite if there is an existing one
if [ ! -f "$db_dump_path" ]; then
    if [ -f infraportal.sql ]; then
        echo "Copying .sql file to $db_dump_path";
        cp infraportal.sql $db_dump_path;
    else
        echo "Make sure there is a database dump in the same dir as this script named 'infraportal.sql'";
        echo "Skipping this step for now - ensure that you place a sb dump at $db_dump_path before starting the docker containers";
    fi;
else
  read -p "WARNING! There is already a sql file at $db_dump_path. If this is correct, press enter to continue (THIS WILL OVERWITE THE EXISTING FILE - PROCEED WITH CAUTION). To preserve the existing file, ctrl-C to exit this script now.";
fi;

####
# FILE PERMISSIONS
####

echo "Setting owner to $file_owner"
source ./set_permissions.sh $infraportal_path $file_owner

echo "Running as $SUDO_USER. Setting group permissions and aliases now";
usermod -aG docker $SUDO_USER;  # Adds user to group
# exec su -l $SUDO_USER;          # Refreshes groups to avoid having to logout and login
echo "Logout and back in to refresh group memberships"

# Allows drush to be run from the host machine
drush_function=$(cat <<- END
function drush() {
        cur_dir=\$(pwd)
        cd /opt/drupal/infrastructure-portal
        docker-compose exec drupal /opt/drupal/web/vendor/bin/drush "\$@"
        cd \$cur_dir
};
END
)
echo "$drush_function" >> /home/$SUDO_USER/.bashrc;
# Start the containers
systemctl enable docker --now;

echo "Installation complete. Run `docker-compose up` from the infrastructure-portal directory now!"
echo "First time starting up may take longer as the database is imported for the first time"
# TODO: Test and make this part of main script
# docker-compose up &
# This will install the site from the composer.lock file
# docker-compose -f ${infraportal_path}/docker-compose.yaml exec drupal bash -c "composer --working-dir='/opt/drupal/web' install"
# drush cr; drush updb; drush cr; # this will pause and wait for user confirmation before performing the database update
# drush config:import
# drush cr; drush updb; drush cr; # this will pause and wait for user confirmation before performing the database update
