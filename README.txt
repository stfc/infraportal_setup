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


DEPLOYING UPDATES

There are two possible deployment paths, depending on whether all files (including those managed by composer) are commited to VCS (this is the current method as of 14/02/2022), or if only custom and modified files are included (planned method to be implemented)

1. All files under VCS
  a. Either on beta, or a new infraportal instance, run the required composer and drush commands.
  b. This should automatically update composer.json and composer.lock
    i. eg running `composer require drupal/core:9.2` will update composer.json and will update drupal core folders.
  c. Commit all changes
  d. On prod, navigate to the infraportal folder (defaults to /opt/drupal/infrastructure-portal)
  e. Pull changes
  f. Run `drush updb && drush cr` to get the changes to update the database and refresh the cache
  g. All changes should now be present on the prod site

For custom module updates, or non-composer mananged files, the same process applies. Just swap step 1a with "Apply file updates manually"

2. Only non-composer managed files under VCS
  a. Either on beta, or a new infraportal instance, add custom file changes
    i. For any contributed modules/themes changes, use composer. The changed files will not be commited, but composer.json and composer.lock will
  b. For contrib modules that need custom changes, use the patches file and add an entry in composer.json (follow the format of the existing patches or see https://github.com/cweagans/composer-patches)
  c. Commit the changed files and patches
    i. Composer managed files should be ignored by .gitignore.Do NOT force add these to the commit.
  d. On prod, navigate to the infraportal folder (defaults to /opt/drupal/infrastructure-portal)
  e. Pull the changes
  f. Run `composer update`, `drush updb && drush cr`
  g. All changes should now be present on the prod site

N.B The move to having composer managed files be ignored by git is in preparation for a CI/CD implementation that will include building a custom Drupal image for Docker which will have the composer commands run as part of its build process. This will simplify the change process to "push changes to active branch, wait for automated workflow to complete, re-start Drupal on the target host with the new docker image"
