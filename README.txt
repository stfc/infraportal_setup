MOTIVATION FOR DOCKER

To make implementation of code changes, moving of server hosts, and general site maintenance easier.
To remove as many steps that require developer interaction wiht deploying and maintaining InfraPortal as possible
To allow for a CI/CD pipeline to be developed that will automate testing and deployment of any changes


USAGE
The included script file "setup_infra.sh" can be run on a fresh machine (CentOS/SL7) and will result in an active InfraPortal instance on port 80 of the host machine.
Steps:
    1. Clone the repo to anywhere on the host machine
    2. cd into infraportal_setup
    3. Move a database export to `infraportal_setup/infraportal.sql`
    4. Fill in the required details in db_info.env
    5. Run setup_infra.sh (requires root)
        a. The "-u" flag can be used to set the owner of the Drupal files to $USER
        b. Without the "-u" flag, apache (UID: 33) will be set to owner
    6. cd to /opt/drupal/infraportal and run `docker-compose up`

MANUAL DEPLOYMENT
If required, a manual deployment can be done by utlising the existing docker-compose file.
    1. A database dump should be placed in the directory specified by "volumes" under the mysql docker container. Default is /opt/drupal/infraportal.sql
    2. Clone the InfraPortal repo and checkout the relevant branch
    3. Fill in the database connection details in sites/default/settings.php
        a. `cp sites/default/default.settings.php sites/default/settings.php`
    4. Ensure docker-compose.yml has matching database information as is set in settings.php
    5. Set file and directory permissions as required by Drupal and your specific site
        a. It is advised that vendor/bin/* is set to executable (770)
        b. sites/default/files/* should be writtable by apache (770)
