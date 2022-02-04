MOTIVATION FOR DOCKER

To make implementation of code changes, moving of server hosts, and general site maintenance easier.
To remove as many steps that require developer interaction wiht deploying and maintaining InfraPortal as possible
To allow for a CI/CD pipeline to be developed that will automate testing and deployment of any changes

HOW TO DEPLOY

The included script file "setup_infra.sh" can be run on a fresh machine (CentOS/SL7) and will result in an active InfraPortal instance on port 80 of the host machine.

If required, a manual deployment can be done by utlising the existing docker-compose file.
    1. A database dump should be placed in the directory specified by "volumes" under the mysql docker container. Default is /opt/drupal/infraportal.sql
    2. Clone the InfraPortal repo and checkout the relevant branch
    3. 
