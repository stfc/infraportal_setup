#!/usr/local/enc bash

if [ -z ${1+x} ]; then
	echo "Script takes a single argument for the PHP memory limit"
	echo "Example: "-1" for unlimited memory, "128M" for default memory"
	exit 1
fi;

memory_line="memory_limit = $1"

cd infrastructure-portal

docker-compose exec drupal bash -c "echo $memory_line > /usr/local/etc/php/conf.d/php.ini"

