#!/usr/bin/env bash
#
# This script assembles a copy of Drupal 7 for local development, or for a
# dev or staging server, by asking a number of questions about the type of
# build required.
#
# ---
#
# The type of build and the differences between each are as follows. All builds
# will download the latest stable release of Drupal 7 from the Drupal.org
# website.
#
# Local development build: checks out the -dev branch of Drupal 7 core
# and the -master branch of Drupal 7 common, as well as any additional
# repositories such as custom Features repos.
#
# Local development builds will also check out additional components such
# as the multisite template, which can be used by the developer to create
# a new multisite instance.
#
# Dev server builds: very similar to the local development builds, but doesn't
# check out the multisite template.
#
# Staging server builds: essentially the same as the dev server build, except
# the -rc branches are checked out instead of -dev as appropriate.
#
# ---
#
# Other things the builder needs to know:
#
# All install types will ask for the database connection details, if known. If
# provided, the local_databases.php file will have an entry created for
# the site, and the user has the opportunity to import a database dump if they
# wish.
#
# The script also needs to know the site's URL, so that the
# settings.this_site_url.info file can be created.
#
# The multisite directory name is needed to set up an existing multisite; the
# script can also create a new multisite if this is a local development build,
# if required.
#
# Optionally, the Drupal installer can be run, if the database details have
# been filled out and no database was imported.
#
#
#
set -e

# Help menu
print_help() {
cat <<-HELP
This script is used to interactively deploy a tagged Drupal 7 release.

Usage: (sudo) bash ${0##*/}

... and then follow the prompts.

HELP
}

print_help

# This script must be run as root.
if [ $(id -u) != 0 ]; then
  printf "**********************************************\n"
  printf "* Error: You must run this with sudo or root *\n"
  printf "**********************************************\n"
  exit 1
fi

# Get a date-time stamp: $DATETIMENOW=YYYYMMDD-HHMMSS
DATETIMENOW=`date +%Y%m%d-%H%M%S`

ARCHIVELOCATIONDEFAULT=~
until [ -d "$ARCHIVELOCATION" ]; do
  echo "What is the ABSOLUTE path to the directory, without the trailing slash, which contains the tagged release archive? Default: '$ARCHIVELOCATIONDEFAULT'"
  read ARCHIVELOCATIONENTERED
  if [ "x$ARCHIVELOCATIONENTERED" = "x" ]; then
    ARCHIVELOCATION=$ARCHIVELOCATIONDEFAULT
  else
    ARCHIVELOCATION=$ARCHIVELOCATIONENTERED
    ARCHIVELOCATIONDEFAULT=$ARCHIVELOCATIONENTERED
  fi
  if [ ! -d "$ARCHIVELOCATION" ]; then
    echo "Oh no! Unable to find a directory at $ARCHIVELOCATION - is it definitely there and definitely a directory?"
  fi
done
echo "Using: $ARCHIVELOCATION"
echo ---
# Try and guess the username from the owner of this directory.
THISSCRIPTOWNER=`ls -ld . | awk 'NR==1 {print $3}'`
if [ ! "x$THISSCRIPTOWNER" = "x" ]; then
  USERNAME=$THISSCRIPTOWNER
else
  USERNAME=$USER
fi
echo "What is the Linux username which should be set as owner of the webserver's files? Default: '$USERNAME'"
read USERNAMEENTERED
if [ ! "x$USERNAMEENTERED" = "x" ]; then
  USERNAME=$USERNAMEENTERED
fi
echo "Using: $USERNAME"
echo ---
MULTISITENAME=$USERNAME
echo "What is the multisite directory name for this deployment? E.g.: $USERNAME or nhsnwlondon - default: '$MULTISITENAME'"
read MULTISITENAMEENTERED
if [ ! "x$MULTISITENAMEENTERED" = "x" ]; then
  MULTISITENAME=$MULTISITENAMEENTERED
fi
echo "Using: $MULTISITENAME"
echo ---
until [ ! "x$TAGVERSION" = "x" ]; do
  echo "What is the tag version number? Don't enter the leading 'v', e.g.: '1.2.3' (required)"
  read TAGVERSION
  if [ "x$TAGVERSION" = "x" ]; then
      echo "Oh no! You need to provide a tag version. Please go back and try again."
  fi
done
echo "Using: $TAGVERSION"
echo ---
ARCHIVEEXTENSIONDEFAULT=tar.gz
echo "What is the tag file extension, without the leading 'dot'? Default: '$ARCHIVEEXTENSIONDEFAULT'"
read ARCHIVEEXTENSIONENTERED
if [ "x$ARCHIVEEXTENSIONENTERED" = "x" ]; then
  ARCHIVEEXTENSION=$ARCHIVEEXTENSIONDEFAULT
else
  ARCHIVEEXTENSION=$ARCHIVEEXTENSIONENTERED
fi
echo "Using: $ARCHIVEEXTENSION"
echo ---
ARCHIVENAMEDEFAULT=drupal7-$MULTISITENAME-v$TAGVERSION
until [ -f "$ARCHIVELOCATION/$ARCHIVENAME.$ARCHIVEEXTENSION" ]; do
  echo "Please confirm the tag filename (without the extension), or correct it now - default: '$ARCHIVENAMEDEFAULT'"
  read ARCHIVENAMEENTERED
  if [ ! "x$ARCHIVENAMEENTERED" = "x" ]; then
    ARCHIVENAME=$ARCHIVENAMEENTERED
  else
    ARCHIVENAME=$ARCHIVENAMEDEFAULT
  fi
  echo "Using: $ARCHIVENAME - testing..."
  if [ -f "$ARCHIVELOCATION/$ARCHIVENAME.$ARCHIVEEXTENSION" ]; then
    echo "Found $ARCHIVELOCATION/$ARCHIVENAME.$ARCHIVEEXTENSION."
  else
    echo "Oh no! Unable to find the tag archive at '$ARCHIVELOCATION/$ARCHIVENAME.$ARCHIVEEXTENSION' - is it definitely there and definitely a file?"
  fi
done
echo ---
PATHTOSETTINGSDEFAULT="/home/$USERNAME"
until [ -f "$PATHTOSETTINGS/local_databases.php" ]; do
  echo "What is the absolute path to local_databases.php?"
  echo "It should be located outside of the deployment directory - usually in"
  echo "$USERNAME's home directory. Symlinks to this file will be created in"
  echo "your deployment directory. Don't enter a trailing slash."
  echo "Default: '$PATHTOSETTINGSDEFAULT'"
  echo -n ":"
  read PATHTOSETTINGSENTERED
  if [ "x$PATHTOSETTINGSENTERED" = "x" ]; then
    PATHTOSETTINGS=$PATHTOSETTINGSDEFAULT
  else
    PATHTOSETTINGS=$PATHTOSETTINGSENTERED
  fi
  echo "Using: $PATHTOSETTINGS - testing..."
  if [ -f "$PATHTOSETTINGS/local_databases.php" ]; then
    echo "Found $PATHTOSETTINGS/local_databases.php."
  else
    echo "Oh no! Unable to find $PATHTOSETTINGS/local_databases.php - is it definitely there and definitely a file?"
  fi
done
echo ---
FILESPATHDEFAULT=$PATHTOSETTINGS/files
until [ -d "$FILESPATH" ]; do
  echo "What is the absolute path of the Drupal files directory (including the directory itself), and without trailing slash? Default: '$FILESPATHDEFAULT'"
  read FILESPATHENTERED
  if [ "x$FILESPATHENTERED" = "x" ]; then
    FILESPATH=$FILESPATHDEFAULT
  else
    FILESPATH=$FILESPATHENTERED
  fi
  echo "Using: $FILESPATH - testing..."
  if [ ! -d "$FILESPATH" ]; then
    echo "Oh no! Unable to find a directory at $FILESPATH - is it definitely there and definitely a directory?"
  fi
done
echo ---
PATHTOWEBROOTDEFAULT=$PATHTOSETTINGS/public_html
until [ -L "$PATHTOWEBROOT/current" ]; do
  echo "What is the absolute path to the directory which contains the 'current' symlink for the live site, without trailing slash? Default: '$PATHTOWEBROOTDEFAULT'"
  read PATHTOWEBROOT
  if [ "x$PATHTOWEBROOT" = "x" ]; then
    PATHTOWEBROOT=$PATHTOWEBROOTDEFAULT
  fi
  echo "Using: $PATHTOWEBROOT - testing..."
  if [ ! -L "$PATHTOWEBROOT/current" ]; then
    echo "Oh no! Unable to find the symlink $PATHTOWEBROOT/current - is it definitely there and definitely a symlink?"
  else
    echo "Found $PATHTOWEBROOT/current."
  fi
done
echo ---
echo "(Optional) What is the URL of the Drupal site, without 'http://' - e.g. www.example.com? You may need to provide this if more than one database is available for the $MULTISITENAME directory. If you leave this blank but Drush complains it can't identify the right database in the local_databases.php file, you may need to provide the site URL."
read SITEURI
echo "Using: $SITEURI"
echo ---
echo "Ready to begin the deployment when you are. The next step will NOT interrupt the live website; it just unpacks the files from the new tag, sets up symlinks and file permissions, and takes a database dump."
echo ""
echo -n "Ready? Press 'Y' for awesomeness, or any other key to put the kibosh on the whole messy affair."
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
  echo "Hokay then, we shall begin..."
else
  echo ""
  echo "Wise choice. See you soon :)"
  exit
fi
echo ---
cd $PATHTOWEBROOT && mv $ARCHIVELOCATION/$ARCHIVENAME.$ARCHIVEEXTENSION . && tar -xvf $ARCHIVENAME.$ARCHIVEEXTENSION && rm *.tar.gz && cd $ARCHIVENAME/sites && mkdir ../tmp && mv all ../tmp/ && mv sites.php ../tmp/ && mv $MULTISITENAME ../tmp/ && rm -rf * && mv ../tmp/* . && rmdir ../tmp/ && cd .. && touch sites/$MULTISITENAME/ENVIRONMENT_TYPE_LIVE.txt && if ! test -d "$PATHTOSETTINGS/privatefiles"; then mv privatefiles $PATHTOSETTINGS/;fi && if test -d "$PATHTOSETTINGS/privatefiles"; then rm -rf privatefiles && ln -s $PATHTOSETTINGS/privatefiles && chown -h $USERNAME:www-data privatefiles;fi && mkdir -p $PATHTOSETTINGS/privatefiles/$MULTISITENAME/tmp && chown -R www-data:$USERNAME $PATHTOSETTINGS/privatefiles/$MULTISITENAME && chmod -R 0770 $PATHTOSETTINGS/privatefiles/$MULTISITENAME && ln -s $PATHTOSETTINGS/local_databases.php && chown -h $USERNAME:www-data local_databases.php && cd www/sites/$MULTISITENAME && ln -s $FILESPATH files && cd ../../../deployment-scripts && ./fix-permissions.sh --drupal_user=$USERNAME
echo ---
cd $PATHTOWEBROOT/current/www/sites/$MULTISITENAME/
PWD=$(pwd)
echo "Current directory: $PWD"
echo ""
echo "Files deployed alongside the live site. Taking a database dump..."
drush --uri=$SITEURI --root="$PATHTOWEBROOT/current/www" sql-dump --result-file=$PATHTOSETTINGS/$MULTISITENAME-db-$DATETIMENOW.sql
echo ---
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "***************************                 *****************************"
echo "***************************  DANGER ZONE!   *****************************"
echo "***************************                 *****************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo ""
echo "Read the following - it's important. Honestly. THIS BIT IS IMPORTANT! :)"
echo ""
echo ""
echo "1 of 2. Multiple web servers: if you are updating a site which uses more than one web application server - e.g. in a load-balanced setup - you should take all but one web server out of the application pool, run the code deployment and database updates from that server first, then smoke test the site as normal."
echo ""
echo "Once the first web server has passed testing, you can then run the code deployment on each remaining webserver, one at a time, before adding each one back into the pool."
echo ""
echo "You MUST make absolutely certain that the old and new copies of the Drupal code will not try to run concurrently, due to the high risk of database corruption, lost data, etc."
echo ""
echo "If you have already run the code and database updates on the first webserver in the pool, you can safely exit this script here because you do not need to make any further database changes."
echo ""
echo -n "Press 'Y' to indicate that you have read and understood this, or any other key to quit the deployment."
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
else
  echo ""
  echo "Deployment cancelled."
  exit
fi
echo "2 of 2. Multiple databases: this script assumes you either have only one database server, or you have a multiple-database setup with replication running in such a way that changes to one database are reflected effectively immediately on the other database server(s)."
echo ""
echo "If that isn't the case for you, then you should STOP this script and make your own deployment plan."
echo ""
echo -n "Press 'Y' to indicate that you have read and understood this, or any other key to quit the deployment."
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
else
  echo ""
  echo "Deployment cancelled."
  exit
fi
echo ""
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************                     ***************************"
echo "*************************  Ready to deploy?   ***************************"
echo "*************************                     ***************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo ""
echo "Arooga alert: are you absolutely sure you want to deploy tag $TAGVERSION from the archive '$ARCHIVENAME'?"
echo ""
echo "Pressing 'Y' will take your site offline, re-point the 'current' symlink, run any database updates, and revert ALL features."
echo ""
echo -n "Ready? Press 'Y' for awesomeness, or any other key to put the kibosh on the whole messy affair."
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
else
  echo ""
  echo "Wise choice. See you soon :)"
  exit
fi
echo ---
echo -n "Sure you're sure? Y again for yes."
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
  echo "Switching to new code..."
else
  echo ""
  echo "Wise choice. See you soon :)"
  exit
fi
echo ---
echo "*************************************************************************"
echo -n "Step 1 of 6: put site into maintenance mode and re-point symlink... "
drush --uri=$SITEURI vset maintenance_mode 1 && cd ../../../..; mv current current-old; ln -s $ARCHIVENAME current; chown -h $USERNAME:www-data current && cd current/www/sites/$MULTISITENAME
echo "- done: 'current' symlink re-pointed to '$ARCHIVENAME'."
echo ---
echo "*************************************************************************"
echo "Step 2 of 6: restart services..."
echo ""
echo -n "Restart Apache? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service apache2 restart
fi
echo ---
echo -n "Restart Nginx? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service nginx restart
fi
echo ---
echo -n "Restart APC? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service apc restart
fi
echo ---
echo -n "Restart PHP5-FPM? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service php5-fpm restart
fi
echo ---
echo -n "Restart Memcached? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service memcached restart
fi
echo ---
echo -n "Restart Redis? Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  service redis-server restart
fi
echo ---
echo "*************************************************************************"
echo "Step 3 of 6: rebuilding Drupal's caches..."
echo ""
echo -n "Rebuild Drupal's registry? You may need to do this if files have been moved, or the {system} table is significantly out of sync with the file structure. Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  drush --uri=$SITEURI rr
fi
echo ---
echo "*************************************************************************"
echo "Step 4 of 6: database updates - if this step freezes for more than ten minutes, you may need to CTRL+C this script and run the remaining commands manually, which are:"
echo ""
echo "drush --uri=$SITEURI updb -y; drush --uri=$SITEURI fra -y; drush --uri=$SITEURI cc all"
echo ""
UPDBTIMENOW=`date +%H:%M:%S`
echo "Starting database updates at $UPDBTIMENOW..."
drush --uri=$SITEURI updb -y
echo ---
echo "*************************************************************************"
echo "Step 5 of 6: Reverting Features..."
drush --uri=$SITEURI fra -y
echo ---
echo "*************************************************************************"
echo "Step 6 of 6: Flushing caches..."
drush --uri=$SITEURI cc all
echo ---
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "***************************                 *****************************"
echo "***************************  SMOKING ZONE!  *****************************"
echo "***************************                 *****************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo "*************************************************************************"
echo ""
echo "Please smoke test the live site as a logged-in user to check that nothing is obviously amiss."
echo ""
echo "If you spot major problems and need to roll-back the deployment, press 'n' at the next prompt and this script will restore your database dump and reinstate the old symlink."
echo ""
echo -n "Is the site okay to go back online? (If you choose 'n' here, you will be asked to confirm if you want to try rolling back to the previous version of the site.) Y/n"
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
if echo "$answer" | grep -iq "^y" ;then
  echo ""
  echo "Putting site back online..."
  drush --uri=$SITEURI vset maintenance_mode 0
  echo ""
  echo -n "Do you want to restart Varnish? Y/n"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    echo ""
    service varnish restart
    echo ""
    echo "Deployment complete. Whew! Please remember to remove any deployments which are more than one version older than the live site."
    echo ""
  fi

  exit

else
  echo ""
  echo -n "Do you want to attempt to roll back to the previous version of the site, by restoring the previous files and database? Y/n"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    echo ""
    echo "Ok, switching back to the previous tag now..."
    echo ""
    cd ../../../.. && mv current current-failed && mv current-old current && cd current/www/sites/$MULTISITENAME
    echo "Previous code restored. Re-importing database dump. Note that Drush will report extra debugging information which may be useful in case of further problems..."
    echo ""
    drush -d --uri=$SITEURI sql-drop && drush -d --uri=$SITEURI --root="$PATHTOWEBROOT/current/www" sql-cli < $PATHTOSETTINGS/$MULTISITENAME-db-$DATETIMENOW.sql
    echo ""
    echo "Roll-back complete. Please review the output above for any errors."
    echo ""
    echo "Putting site back online..."
    drush --uri=$SITEURI vset maintenance_mode 0
    echo ""
    echo -n "Do you want to restart Varnish? Y/n"
    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^y" ;then
      echo ""
      service varnish restart
      echo ""
      echo "All done. Sorry things didn't go to plan. The new tag's files have been left in place in case you want to review them."
    fi

    exit
    echo ""
  else
    echo ""
    echo "No roll-back will be attempted. The website is still in maintenance mode."
  fi
  echo ""
  echo "(Good luck)."
  echo ""
fi
