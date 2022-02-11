#!/bin/bash
# Used to adjust the memory limits for the running Drupal container - this expects the infraportal instance to be at /opt/drupal/infrastructure-portal
# Typically used for large composer commands that return a "COMPOSER_MEMORY_ERROR"
# USAGE ./adjust_mem_limit.sh $new_limit

if [ -z ${1+x} ]; then
	echo "Script takes a single argument for the PHP memory limit"
	echo "Example: "-1" for unlimited memory, "128M" for default memory"
	exit 1
fi;

memory_line="memory_limit = $1"

cd /opt/drupal/infrastructure-portal

docker-compose exec drupal bash -c "echo $memory_line > /usr/local/etc/php/conf.d/php.ini"

