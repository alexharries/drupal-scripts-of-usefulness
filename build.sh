#!/usr/bin/env bash

# Halt on errors.
set -e

# Clear the screen.
clear

# Note the starting directory.
STARTINGDIRECTORY=$(pwd)

# Check for command line options, e.g.:
#
# --buildtype="LIVE"
# --buildfromtag="1.0.0"
# --createtag="1.0.1"
# --buildpath="[current build directory/../live-deployment-$TAGNAME]"

# Parse Command Line Arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --buildtype=*)
      BUILDTYPE="${1#*=}"
      echo "Build type: $BUILDTYPE"
    ;;
    --buildfromtag=*)
      BUILDFROMTAG="${1#*=}"
      echo "Building from tag: $BUILDFROMTAG"
    ;;
    --createtag=*)
      CREATETAG="${1#*=}"
      echo "Creating tag : $CREATETAG"
    ;;
    --buildpath=*)
      BUILDPATH="${1#*=}"
      echo "Build path: $BUILDPATH"
    ;;
    --filespath=*)
      FILESPATH="${1#*=}"
      echo "FILESPATH: $FILESPATH"
    ;;
  # TODO: Other fields to be added: GITHUBUSER_CORE, ADD_UPSTREAM, GITHUBUSER_UPSTREAM,
    --githubuser=*)
      GITHUBUSER_CORE="${1#*=}"
      echo "GITHUBUSER_CORE: $GITHUBUSER_CORE"
    ;;
    --githubuserupstream=*)
      GITHUBUSER_UPSTREAM="${1#*=}"
      echo "GITHUBUSER_UPSTREAM: $GITHUBUSER_UPSTREAM"
    ;;
    --addupstream=*)
      ADDUPSTREAM="${1#*=}"
      echo "ADDUPSTREAM: $ADDUPSTREAM"
    ;;
    --multisitename=*)
      MULTISITENAME="${1#*=}"
      echo "MULTISITENAME: $MULTISITENAME"
    ;;
    --featurescheckout=*)
      FEATURESCHECKOUT="${1#*=}"
      echo "FEATURESCHECKOUT: $FEATURESCHECKOUT"
    ;;
    --featurescheckoutbranch=*)
      FEATURESCHECKOUTBRANCH="${1#*=}"
      echo "FEATURESCHECKOUTBRANCH: $FEATURESCHECKOUTBRANCH"
    ;;
    --projectscheckout=*)
      PROJECTSCHECKOUT="${1#*=}"
      echo "PROJECTSCHECKOUT: $PROJECTSCHECKOUT"
    ;;
    --projectscheckoutbranch=*)
      PROJECTSCHECKOUTBRANCH="${1#*=}"
      echo "PROJECTSCHECKOUTBRANCH: $PROJECTSCHECKOUTBRANCH"
    ;;
    --help) print_help ;;
    *)
      printf "***********************************************************\n"
      printf "* Error: Invalid argument '$1', run --help for valid arguments. *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done

# done -- TODO: default to checking out develop branch for local/develop builds, and rc branch for staging
# not done -- TODO: implement choice to checkout different branches for each repo
# TODO: implement confirmation questions when buildtype is STAGING as follows:
# 1. Have you merged the work which you want to test from the develop branch onto rc?
# 2. Have you pulled any remote changes using the update.sh script?
# 3. Are your working directories clean?
# TODO: implement confirmation questions when buildtype is LIVE - "have you merged "
# 1. Have you merged the TESTED work which you want to deploy from the rc branch onto master?
# 2. Have you pulled any remote changes using the update.sh script?
# 3. Are your working directories clean?
# done -- TODO: implement build from tag step when buildtype is LIVE
# done -- TODO: implement create tag step when buildtype is LIVE

function removegit {
  # Recursively remove .git and .gitignore files.
  echo "Removing .git* files from $1..."
  find "$1/." -name '.git*' | xargs rm -rf
}

function createtag {
  git tag "$2" -a -m "Tagging version $2 for $1." && git push origin "$2"
}

echo "
*************************************************************************

This is a rough and ready script to build a Drupal codebase.

Local, development and staging builds contain the Git repositories so you
can make changes and commit them back to the remotes.

Live builds don't contain any Git files, database credentials, the Drupal
files directory, or other development tools, and are designed to be
uploaded to a live server for deployment with the deploy.sh script.

*************************************************************************

Once this script has completed, you will have a directory structure
similar to this (not all contents shown for brevity, and the live
build structure won't contain all these parts):

/ core
  / configuration
  / patches
  / privatefiles
  / profiles
    / greyhead
  / www
    / (Drupal 7 - index.php, cron.php, etc)
    / sites -> symlink to /sites-common
    / profiles
      / greyheadprofile-> symlink to /core/profiles/greyheadprofile
      / fourprofile-> symlink to /core/profiles/fourprofile
/ sites-common
  / all
    / drush -> symlink to /sites-projects/_drush_aliases
    / libraries
    / modules
      / contrib
      / custom
        / greyhead_* -> various greyhead modules (Git submodules)
      / features -> optional symlink to /features
    / themes
      / bootstrap
      / greyhead_bootstrap (Git submodule)
  / default
  / [your multisite name] -> optional symlink to /sites-projects/[your multisite name]
  . sites.php
/ sites-projects
  / _drush_aliases
  / [your multisite name]
    / modules
      / custom
        / project_customisations (custom module)
    / themes
      / [your project name]_bootstrap_subtheme (optional)
    / files -> symlink to the project's files directory
    . settings.php
    . settings.site_urls.php
/ multisite-template
/ multisite-maker
. local_databases.php (your database settings file)
. local_settings.php

*************************************************************************

Note: your webroot should point to /core/www

*************************************************************************

These directories will contain the following Git repositories:

core: this contains a copy of the latest release of Drupal 7, and the
code which configures the Drupal site for your local installation such as
setting development variables, etc.

sites-common: this provides the Drupal /sites/all and /sites/default
directories, /sites/sites.php and a couple of other common files. This repo
will be symlinked into core/www/sites

multisite-template: provides a multisite directory to create a new
multisite in the codebase.

A choice of two Features repos:

Either: alexharries/drupal7_common_features, at
core/www/sites/all/modules/features

Or: (Four Communications only) drupal7_four_features, at
core/www/sites/all/modules/features

sites-projects: the directory where your individual multisite projects
are kept. This will either be a checkout from a repo URL you specify,
one of two pre-configured Github repos (as long as you have access to clone
them), or a freshly-created directory which you will need to save, e.g. by
creating a git repository for.

This will contain the multisite directory with code (modules, themes, etc)
specifically for this Drupal website build. Individual projects' directories
are then symlinked into the core/www/sites/ directory.

multisite-maker: Multisite Maker is a quick 'n dirty way for you to
let non-technical Drupal users self-serve by setting up their own throwaway
Drupal instances. To enable, create a symlink from the www directory to the
multisitemaker directory; see
https://github.com/fourcommunications/multisite-maker for full
destructions.

*************************************************************************

Important information about branches
------------------------------------
Note that LOCAL and DEV builds will check out the 'develop' branch of each
repo, if you choose to download one; STAGING builds will use 'rc' branches,
while LIVE builds use MASTER.

You need to make sure you have merged from the dev branch to rc to move
from development into staging, and merge from the rc branch to master
once everything passes testing ready for a live build

*************************************************************************

"

if [ "x$BUILDTYPE" = "x" ]; then
  until [ ! "x$BUILDTYPE" = "x" ]; do
    echo -n "What type of build is this?

1: LOCAL
2: DEV
3: STAGING
4: LIVE (To deploy a live build created with this script, see live-deploy.sh)

: "

    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^1" ;then
      BUILDTYPE="LOCAL"
    elif echo "$answer" | grep -iq "^2" ;then
      BUILDTYPE="DEV"
    elif echo "$answer" | grep -iq "^3" ;then
      BUILDTYPE="STAGING"
    elif echo "$answer" | grep -iq "^4" ;then
      BUILDTYPE="LIVE"
    fi
  done
fi

echo "Build type: $BUILDTYPE"

if [ "x$MULTISITENAME" = "x" ]; then
  echo -n "
  *************************************************************************

  What is the multisite directory name for this build?

  This will be the directory in sites/ which contains modules, themes and files
  for this build.

  If you leave this blank, you will have to manually create the multisite
  directory from the multisites template (or build it yourself of course).

  You can enter 'default' if you want this site to use the sites/default
  directory, but this will cause problems if you want to deploy this code to a
  dev, staging or live server using these deployment scripts.

  :"

  read MULTISITENAME
  echo "

  Using: $MULTISITENAME.

  "
fi

# Remove hyphens from $MULTISITENAME, if any exist.
MULTISITENAMENOHYPHENS=$(echo "$MULTISITENAME" | sed 's/[\._-]//g')

# ---

# Have we been asked to build a live deployment? Find out if we are to build
# from a pre-existing tag, or create a new one (or both, conceivably...).
if [ "$BUILDTYPE" = "LIVE" ]; then
  if [ "x$BUILDFROMTAG" = "x" ]; then
    echo -n "
*************************************************************************

Do you want to build from a pre-existing tag? If so, enter the tag version.

Example: '1.2.2' (no quotes or 'v').

: "

    read BUILDFROMTAG
  fi

  if [ "x$CREATETAG" = "x" ]; then
    echo -n "
*************************************************************************

Do you want to create a new tag? If so, enter the tag version.

Example: '1.2.3' (no quotes or 'v').

: "

    read CREATETAG
  fi
fi

# Set a depth modifier. We also use this to recursively remove the git
# directories.
GITCLONECOMMAND="git clone"
REMOVEGIT="no"
BUILDARCHIVENAME=""

# Determine the branches to use for projects. If we've been asked to build from
# a particular tag, then we will attempt to check each project out at that tag.
if [ ! "x$BUILDFROMTAG" = "x" ]; then
  REMOVEGIT="yes"
  PROJECTSBRANCH="$BUILDFROMTAG"
  GITCLONECOMMAND="$GITCLONECOMMAND --depth 1"
  BUILDARCHIVENAME="drupal7-v$BUILDFROMTAG-$MULTISITENAME"
  BUILDTYPE="LIVE"
elif [[ "$BUILDTYPE" = "LOCAL" || "$BUILDTYPE" = "DEV" ]]; then
  PROJECTSBRANCH="develop"
#  BUILDARCHIVENAME="develop"
elif [[ "$BUILDTYPE" = "STAGING" ]]; then
  PROJECTSBRANCH="rc"
#  BUILDARCHIVENAME="staging"
elif [[ "$BUILDTYPE" = "LIVE" ]]; then
  PROJECTSBRANCH="master"

  if [ ! "x$CREATETAG" = "x" ]; then
    BUILDARCHIVENAME="drupal7-v$CREATETAG-$MULTISITENAME"
  fi
fi

if [ "x$URI" = "x" ]; then
  echo -n "
  *************************************************************************

  (Optional) What is the URL of this build of the Drupal site, without
  'http://' - e.g. 'www.example.com'?

  You need to provide this if you want to configure the database connection
  using this script, or have Drupal automagically create the
  settings.this_site_url.info file.

  You must provide this if you are building for a live deployment, unless
  you know that the settings.site_urls.info file contains the live site's
  URL.

  :"

  read URI
  echo "

  Using: $URI

  "
fi

# ---

BUILDPATH_SUBDIR="$MULTISITENAME"
if [ "x$BUILDPATH_SUBDIR" = "x" ]; then
  BUILDPATH_SUBDIR="default"
fi

# Get ths current path.
PWD=$(pwd)

# Example PWD: /Volumes/Sites/4Com/builds/develop/monkey/scripts-of-usefulness

# Example build path: /Volumes/Sites/4Com/builds/develop/monkey/scripts-of-usefulness/../../../$BUILDSUBDIRECTORY/$MULTISITENAME
# ... which becomes: /Volumes/Sites/4Com/builds/develop/crapterliving
BUILDPATH_DEFAULT="$PWD/$BUILDTYPE"

# If this if a live deployment, add the build archive name to the build path.
if [ "$BUILDTYPE" = "LIVE" ]; then
  BUILDPATH_DEFAULT="$BUILDPATH_DEFAULT"
# If this isn't a live deployment, add the multisite directory to the default
# build path.
else
  BUILDPATH_DEFAULT="$BUILDPATH_DEFAULT/$MULTISITENAME"
fi

if [ "x$BUILDPATH" = "x" ]; then
  BUILDPATH="$PWD"
  until [ ! -d "$BUILDPATH" ]; do
    echo "
  *************************************************************************

  What directory should we build Drupal in, without a trailing slash?

  This directory MUST NOT already exist (since you could accidentally
  overwrite another project build).

  Leave blank to use the default: '$BUILDPATH_DEFAULT'
  "

  if [ "$BUILDTYPE" = "LIVE" ]; then
    echo "Because this is a LIVE deployment, the build directory /$BUILDARCHIVENAME will be created below this build path.
    "
  fi

  echo -n ": "
    read BUILDPATH_ENTERED
    if [ ! "x$BUILDPATH_ENTERED" = "x" ]; then
      BUILDPATH="$BUILDPATH_ENTERED"
    else
      BUILDPATH="$BUILDPATH_DEFAULT"
    fi

    # If it's a live build, append the build archive name to the path.
    if [ "$BUILDTYPE" = "LIVE" ]; then
      BUILDPATH="$BUILDPATH/$BUILDARCHIVENAME"
    fi

    if [ -d "$BUILDPATH" ]; then
      echo "
***************************************************************
WARNING:
Directory '$BUILDPATH' already exists; moving it to
$BUILDPATH-old
***************************************************************
    "
      mv "$BUILDPATH" "$BUILDPATH-old"
    fi
  done
fi

echo "Making directory $BUILDPATH..."
mkdir -p "$BUILDPATH"

if [ ! -d "$BUILDPATH" ]; then
  echo "Couldn't create $BUILDPATH. Please fix this and re-run. Thanks!"
  exit
fi

echo "
Using: $BUILDPATH.

"

# Create a directory to track the build progress - we could use this to allow
# restarting of the script, if interrupted.
mkdir "$BUILDPATH/build-information"

# Create files to represent variables.
echo "$BUILDPATH" > "$BUILDPATH/build-information/buildpath.txt"
echo "$BUILDTYPE" > "$BUILDPATH/build-information/buildtype.txt"
echo "$URI" > "$BUILDPATH/build-information/uri.txt"
echo "$MULTISITENAME" > "$BUILDPATH/build-information/multisitename.txt"
echo "$PROJECTSBRANCH" > "$BUILDPATH/build-information/projectsbranch.txt"

# ---

# Only request files path if this isn't a live build.
if [ ! "$BUILDTYPE" = "LIVE" ]; then

  FILESPATHDEFAULT="$BUILDPATH/../../files/$BUILDTYPE/$MULTISITENAMENOHYPHENS"
  if [ ! -d "$FILESPATH" ]; then
    until [ -d "$FILESPATH" ]; do
      echo -n "
    *************************************************************************

    What is the absolute path of the Drupal files directory (including the
    directory itself), and without trailing slash?

    A symlink to this directory will be created in your multisite's directory.

    Default: '$FILESPATHDEFAULT': "
      read FILESPATHENTERED
      if [ "x$FILESPATHENTERED" = "x" ]; then
        FILESPATH="$FILESPATHDEFAULT"
      else
        FILESPATH="$FILESPATHENTERED"
      fi
      echo "

      Using: $FILESPATH - attempting to make the directory if it doesn't
      already exist..."

      mkdir -p "$FILESPATH"

      if [ ! -d "$FILESPATH" ]; then
        echo "Oh no! Unable to create the directory at $FILESPATH - does this script have permission to make directories there?"
      fi
    done
  fi
fi

# ---

# Have we been passed in a --githubuser parameter? If not, get it now.
GITHUBUSER_DEFAULT="alexharries"

if [ "x$GITHUBUSER_CORE" = "x" ]; then
  GITHUBUSER_CORE="$GITHUBUSER_DEFAULT"

  echo -n "
  *************************************************************************

  What is the Github account from which you want to clone the drupal7_core repo? Leave blank to use the default: '$GITHUBUSER_CORE'
  :"
  read GITHUBUSER_CORE_ENTERED
  if [ ! "x$GITHUBUSER_CORE_ENTERED" = "x" ]; then
    GITHUBUSER_CORE="$GITHUBUSER_CORE_ENTERED"
  fi
fi

echo "Using: $GITHUBUSER_CORE"

# ---

# Do we know if we're adding an upstream repo to core?
if [ ! "$BUILDTYPE" = "LIVE" ] && [ ! "$ADDUPSTREAM" = "yes" ] && [ ! "$ADDUPSTREAM" = "no" ]; then
  # Have we been passed in a --githubuser parameter? If not, get it now.
  echo -n "
  *************************************************************************

  Do you want to add an upstream remote for drupal7_core? E.g. if this is a
  forked repo, you can add the fork's source repo so you can then pull in changes
  by running: git fetch upstream; git checkout master; git merge upstream/master

  Press Y/n: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^y" ;then
    ADDUPSTREAM="yes"
  else
    ADDUPSTREAM="no"
  fi
fi

if [ "x$FEATURESCHECKOUT" = "x" ]; then
  echo -n "
  *************************************************************************

  Which Features repo do you want to clone, if any?

  1. fourcommunications/drupal7_four_features (restricted access)
  2. alexharries/drupal7_common_features (restricted access)
  3. Another git repository and branch of your choosing
  4. No Features checkout.

  : "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^1" ;then
    # fourcomms
    FEATURESCHECKOUT="fourcommunications"
  elif echo "$answer" | grep -iq "^2" ;then
    # alexharries
    FEATURESCHECKOUT="alexharries"
  elif echo "$answer" | grep -iq "^3" ;then
    # other
    FEATURESCHECKOUT="custom"
  elif echo "$answer" | grep -iq "^4" ;then
    # none
    FEATURESCHECKOUT="none"
  fi
fi

if [ "$FEATURESCHECKOUT" = "fourcommunications" ]; then
  FEATURESCLONEURL="git@github.com:fourcommunications/drupal7_four_features.git"
fi

if [ "$FEATURESCHECKOUT" = "alexharries" ]; then
  FEATURESCLONEURL="git@github.com:alexharries/drupal7_common_features.git"
fi

# Work out what branch we want to check out our project files from.
if [ "$FEATURESCHECKOUT" = "fourcommunications" ] || [ "$FEATURESCHECKOUT" = "alexharries" ]; then
  FEATURESCHECKOUTBRANCH_DEFAULT="$PROJECTSBRANCH"
fi

if [ "x$FEATURESCHECKOUTBRANCH" = "x" ]; then
  # Don't ask for Features branch if we have a default.
  if [ "x$FEATURESCHECKOUTBRANCH_DEFAULT" = "x" ]; then
    FEATURESCHECKOUTBRANCH_DEFAULT="master"
  fi

  if [ "$FEATURESCHECKOUT" = "fourcommunications" ] || [ "$FEATURESCHECKOUT" = "alexharries" ] || [ "$FEATURESCHECKOUT" = "custom" ]; then
    echo -n "
  *************************************************************************

  What branch should be checked out for the Features repository? (Leave blank for default '$FEATURESCHECKOUTBRANCH_DEFAULT') : "
    read FEATURESCHECKOUTBRANCH

    if [ "x$FEATURESCHECKOUTBRANCH" = "x" ]; then
      FEATURESCHECKOUTBRANCH="$FEATURESCHECKOUTBRANCH_DEFAULT"
    fi
  fi
fi

if [ "$FEATURESCHECKOUT" = "custom" ]; then
  echo -n "
*************************************************************************

What is the full clone URL of the repo? : "
  read FEATURESCLONEURL

  if [ "x$FEATURESCLONEURL" = "x" ]; then
    echo "No URL entered - cancelling and will create an empty dir instead."
    FEATURESCHECKOUT="create"
  fi
fi

if [ "$ADDUPSTREAM" = "yes" ]; then
  if [ "x$GITHUBUSER_UPSTREAM" = "x" ]; then
    # Add remotes.
    GITHUBUSER_UPSTREAM="$GITHUBUSER_DEFAULT"
    echo -n "
*************************************************************************

What is the upstream Github account to pull changes from?
Leave blank to use the default: '$GITHUBUSER_UPSTREAM'
: "

    read GITHUBUSER_UPSTREAM_ENTERED
    if [ ! "x$GITHUBUSER_UPSTREAM_ENTERED" = "x" ]; then
      GITHUBUSER_UPSTREAM="$GITHUBUSER_UPSTREAM_ENTERED"
    fi
  fi
fi

# Don't allow adding upstream if $GITHUBUSER_UPSTREAM is empty.
if [ "$ADDUPSTREAM" = "yes" ] && [ "x$GITHUBUSER_UPSTREAM" = "x" ]; then
  ADDUPSTREAM="no"
fi

if [ "x$PROJECTSCHECKOUT" = "x" ]; then
  echo -n "
  *************************************************************************

  Please choose which drupal7_sites_projects directory you want to check
  out or create:

  1. fourcommunications/drupal7_sites_projects (restricted access)
  2. alexharries/drupal7_sites_projects (restricted access)
  3. Another git repository and branch of your choosing
  4. No checkout - just create a directory (you're responsible for saving)

  : "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^1" ;then
    # fourcomms
    PROJECTSCHECKOUT="fourcommunications"
  elif echo "$answer" | grep -iq "^2" ;then
    # alexharries
    PROJECTSCHECKOUT="alexharries"
  elif echo "$answer" | grep -iq "^3" ;then
    # other
    PROJECTSCHECKOUT="custom"
  elif echo "$answer" | grep -iq "^4" ;then
    # none
    PROJECTSCHECKOUT="create"
  fi
fi

if [ "$PROJECTSCHECKOUT" = "fourcommunications" ]; then
  PROJECTSCLONEURL="git@github.com:fourcommunications/drupal7_sites_projects.git"
fi

if [ "$PROJECTSCHECKOUT" = "alexharries" ]; then
  PROJECTSCLONEURL="git@github.com:alexharries/drupal7_sites_projects.git"
fi

# Work out what branch we want to check out our project files from.
if [ "$PROJECTSCHECKOUT" = "fourcommunications" ] || [ "$PROJECTSCHECKOUT" = "alexharries" ]; then
  PROJECTSCHECKOUTBRANCH_DEFAULT="$PROJECTSBRANCH"
fi

if [ "$PROJECTSCHECKOUT" = "custom" ]; then
  echo -n "
*************************************************************************

What is the full clone URL of the repo? : "
  read PROJECTSCLONEURL

  if [ "x$PROJECTSCLONEURL" = "x" ]; then
    echo "No URL entered - cancelling and will create an empty dir instead."
    PROJECTSCHECKOUT="create"
  fi
fi

if [ "x$PROJECTSCHECKOUTBRANCH" = "x" ]; then
  # Don't ask for Projects branch if we have a default.
  if [ "x$PROJECTSCHECKOUTBRANCH_DEFAULT" = "x" ]; then
    PROJECTSCHECKOUTBRANCH_DEFAULT="master"
  fi

  if [ "$PROJECTSCHECKOUT" = "fourcommunications" ] || [ "$PROJECTSCHECKOUT" = "alexharries" ] || [ "$PROJECTSCHECKOUT" = "custom" ]; then
    echo -n "
  *************************************************************************

  What branch should be checked out for the Projects repository? (Leave blank for default '$PROJECTSCHECKOUTBRANCH_DEFAULT') : "
    read PROJECTSCHECKOUTBRANCH

    if [ "x$PROJECTSCHECKOUTBRANCH" = "x" ]; then
      PROJECTSCHECKOUTBRANCH="$PROJECTSCHECKOUTBRANCH_DEFAULT"
    fi
  fi
fi





























































# Start doing.

echo "Cloning Drupal core branch $PROJECTSBRANCH from $GITHUBUSER_CORE into $BUILDPATH/core ..."

cd "$BUILDPATH"
${GITCLONECOMMAND} --branch "$PROJECTSBRANCH" --recursive "git@github.com:$GITHUBUSER_CORE/drupal7_core.git" core
cd "core"

if [ ! "x$CREATETAG" = "x" ]; then
  createtag "$MULTISITENAME" "$CREATETAG"
fi

if [ "$REMOVEGIT" = "yes" ]; then
  removegit "$BUILDPATH/core"
else
  # Ignore file permission changes.
  git config core.fileMode false

  if [ "$ADDUPSTREAM" = "yes" ]; then
    cd "$BUILDPATH/core"

    echo "Using: $GITHUBUSER_UPSTREAM. Adding remote..."

    REMOTE="git@github.com:$GITHUBUSER_UPSTREAM/drupal7_core.git"

    git remote add upstream "$REMOTE"

    echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
    git remote -v

    echo "Continuing..."
  fi
fi

# ---

GITHUBUSER_SITES_COMMON="$GITHUBUSER_CORE"

echo "Using: $GITHUBUSER_SITES_COMMON

Cloning Drupal sites common branch $PROJECTSBRANCH from $GITHUBUSER_SITES_COMMON into $BUILDPATH/sites-common ..."

cd "$BUILDPATH"
${GITCLONECOMMAND} --branch "$PROJECTSBRANCH" --recursive "git@github.com:$GITHUBUSER_SITES_COMMON/drupal7_sites_common.git" sites-common
cd "sites-common"

if [ ! "x$CREATETAG" = "x" ]; then
  createtag "$MULTISITENAME" "$CREATETAG"
fi

if [ "$REMOVEGIT" = "yes" ]; then
  removegit "$BUILDPATH/sites-common"
else
  # Ignore file permission changes.
  git config core.fileMode false

  if [ "$ADDUPSTREAM" = "yes" ]; then
    cd "$BUILDPATH/sites-common"

    echo "Using: $GITHUBUSER_UPSTREAM. Adding remote..."

    REMOTE="git@github.com:$GITHUBUSER_UPSTREAM/drupal7_sites_common.git"

    git remote add upstream "$REMOTE"

    echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
    git remote -v

    echo "
  Continuing...
  "
  fi
fi

# ---

## Only clone multisite template if this is a LOCAL build.
# ^ This is wrong. We delete multisite template later; we need it during build
# to provide the .htaccess template.

GITHUBUSER_MULTISITE_TEMPLATE="$GITHUBUSER_SITES_COMMON"

echo "Using: $GITHUBUSER_MULTISITE_TEMPLATE

Cloning Drupal multisite template branch $PROJECTSBRANCH from $GITHUBUSER_MULTISITE_TEMPLATE into $BUILDPATH/multisite-template ..."

cd "$BUILDPATH"
${GITCLONECOMMAND} --branch "$PROJECTSBRANCH" --recursive "git@github.com:$GITHUBUSER_MULTISITE_TEMPLATE/drupal7_multisite_template.git" multisite-template
cd "multisite-template"

if [ ! "x$CREATETAG" = "x" ]; then
  createtag "$MULTISITENAME" "$CREATETAG"
fi

if [ "$REMOVEGIT" = "yes" ]; then
  removegit "$BUILDPATH/multisite-template"
else
  # Ignore file permission changes.
  git config core.fileMode false

  if [ "$ADDUPSTREAM" = "yes" ]; then
    cd "$BUILDPATH/multisite-template"

    echo "Using: $GITHUBUSER_UPSTREAM. Adding remote..."

    REMOTE="git@github.com:$GITHUBUSER_UPSTREAM/drupal7_multisite_template.git"

    git remote add upstream "$REMOTE"

    echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
    git remote -v

    echo "
  Continuing...
  "
  fi
fi

# Now multisitemaker.
GITHUBUSER_MULTISITEMAKER="$GITHUBUSER_SITES_COMMON"

echo "Using: $GITHUBUSER_MULTISITEMAKER

Cloning Drupal multisite maker branch $PROJECTSBRANCH from $GITHUBUSER_MULTISITEMAKER into $BUILDPATH/multisite-maker ..."

cd "$BUILDPATH"
${GITCLONECOMMAND} --branch "$PROJECTSBRANCH" --recursive "git@github.com:$GITHUBUSER_MULTISITEMAKER/greyhead_multisitemaker.git" multisite-maker
cd "multisite-maker"

if [ ! "x$CREATETAG" = "x" ]; then
  createtag "$MULTISITENAME" "$CREATETAG"
fi

if [ "$REMOVEGIT" = "yes" ]; then
  removegit "$BUILDPATH/multisite-maker"
else
  # Ignore file permission changes.
  git config core.fileMode false

  if [ "$ADDUPSTREAM" = "yes" ]; then
    cd "$BUILDPATH/multisite-maker"

    echo "Using: $GITHUBUSER_UPSTREAM. Adding remote..."

    REMOTE="git@github.com:$GITHUBUSER_UPSTREAM/greyhead_multisitemaker.git"

    git remote add upstream "$REMOTE"

    echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
    git remote -v

    echo "
  Continuing...
  "
  fi
fi

# Now drupal-scripts-of-usefulness.
GITHUBUSER_SCRIPTS="$GITHUBUSER_MULTISITEMAKER"

echo "Using: $GITHUBUSER_SCRIPTS

Cloning scripts of usefulness branch $PROJECTSBRANCH from $GITHUBUSER_SCRIPTS into $BUILDPATH/scripts-of-usefulness ..."

cd "$BUILDPATH"
${GITCLONECOMMAND} --branch "$PROJECTSBRANCH" --recursive "git@github.com:$GITHUBUSER_SCRIPTS/drupal-scripts-of-usefulness.git" scripts-of-usefulness
cd "scripts-of-usefulness"

if [ ! "x$CREATETAG" = "x" ]; then
  createtag "$MULTISITENAME" "$CREATETAG"
fi

if [ "$REMOVEGIT" = "yes" ]; then
  removegit "$BUILDPATH/scripts-of-usefulness"
else
  # Ignore file permission changes.
  git config core.fileMode false

  if [ "$ADDUPSTREAM" = "yes" ]; then
    cd "$BUILDPATH/scripts-of-usefulness"

    echo "Using: $GITHUBUSER_UPSTREAM. Adding remote..."

    REMOTE="git@github.com:$GITHUBUSER_UPSTREAM/drupal-scripts-of-usefulness.git"

    git remote add upstream "$REMOTE"

    echo "Remote '$REMOTE' added. Please check the following output is correct:

  "
    git remote -v

    echo "
  Continuing...
  "
  fi
fi

# Download Drupal 7 core.
COMMAND="\"$BUILDPATH/scripts-of-usefulness/script-components/download-drupal7-core.sh\" --multisitename=\"$MULTISITENAME\" --corepath=\"$BUILDPATH/core\" --drupalversion=7"
eval ${COMMAND}

cd "$BUILDPATH"

if [ "$FEATURESCHECKOUT" = "fourcommunications" ] || [ "$FEATURESCHECKOUT" = "alexharries" ] || [ "$FEATURESCHECKOUT" = "custom" ]; then
  cd "$BUILDPATH"
  ${GITCLONECOMMAND} --branch "$FEATURESCHECKOUTBRANCH" --recursive "$FEATURESCLONEURL" features
  cd features

  if [ ! "x$CREATETAG" = "x" ]; then
    createtag "$MULTISITENAME" "$CREATETAG"
  fi

  if [ "$REMOVEGIT" = "yes" ]; then
    removegit "$BUILDPATH/features"
  else
    # Ignore file permission changes.
    git config core.fileMode false
  fi

  # Link core/www/sites/all/modules/features to $BUILDPATH/features
  ln -s "$BUILDPATH/features" "$BUILDPATH/core/www/sites/all/modules/features"
fi

# sites-projects

if [ "$PROJECTSCHECKOUT" = "fourcommunications" ] || [ "$PROJECTSCHECKOUT" = "alexharries" ] || [ "$PROJECTSCHECKOUT" = "custom" ]; then
  echo "Checking out $PROJECTSCLONEURL to sites-projects..."

  cd "$BUILDPATH"
  ${GITCLONECOMMAND} --branch "$PROJECTSCHECKOUTBRANCH" --recursive "$PROJECTSCLONEURL" sites-projects
  cd sites-projects

  if [ ! "x$CREATETAG" = "x" ]; then
    createtag "$MULTISITENAME" "$CREATETAG"
  fi

  if [ "$REMOVEGIT" = "yes" ]; then
    removegit "$BUILDPATH/sites-projects"
  else
    # Ignore file permission changes.
    git config core.fileMode false
  fi
fi

if [ "$PROJECTSCHECKOUT" = "create" ]; then
  mkdir -p "$BUILDPATH/sites-projects"
fi

if [ -d "$BUILDPATH/sites-projects" ]; then
  # If Drupal core and drupal7_sites_common were checked out ok, and we have
  # a multisite name, symlink the project dir and drush aliases in now.
  if [ ! "x$MULTISITENAME" = "x" ]; then
    # Symlink the multisite directory from sites/ to its physical location.
    MULTISITEPHYSICALLOCATION="$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS"
    MULTISITESYMLINKLOCATION="$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS"

    if [[ ! -d "$MULTISITEPHYSICALLOCATION" && -d "$BUILDPATH/multisite-template" ]]; then
      echo -p "
*************************************************************************

Multisite directory $MULTISITEPHYSICALLOCATION not found. Do you want to create it from the multisite template? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        # Copy the sites template and comment out the URL template in
        # settings.site_urls.info.
        cp -R "$BUILDPATH/multisite-template/sites-template" "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS"
        perl -pi -e "s/SETTINGS_SITE_URLS\[\] = {{DOMAIN}}/; SETTINGS_SITE_URLS\[\] = {{DOMAIN}}/g" "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/settings.site_urls.info"

        MULTISITEDIRECTORY="$BUILDPATH/sites-projects"
        MULTISITETHEMEPATH="$MULTISITEDIRECTORY/$MULTISITENAMENOHYPHENS/themes"
        MULTISITETHEMETEMPLATEPATH="$MULTISITETHEMEPATH/username_bootstrap_subtheme"

        echo -n "
*************************************************************************

Do you want to create a Bootstrap sub-subtheme and commit it to the repo?

(Le quoi? See git@github.com:alexharries/greyhead_bootstrap for more info.)

Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
          # Create the Bootstrap sub-subtheme.

          THEMENAME="${MULTISITENAMENOHYPHENS}_bootstrap_subtheme"

          echo "Creating the subtheme $THEMENAME at $BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/themes:"

          cd "$MULTISITETHEMEPATH"
          mv username_bootstrap_subtheme "$THEMENAME"
          cd "$THEMENAME"
          mv username_bootstrap_subtheme.info "${THEMENAME}.info"

          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "${THEMENAME}.info"
          perl -pi -e "s/{{username}}/$MULTISITENAMENOHYPHENS/g" "prepros.cfg"
          perl -pi -e "s/function username/function $MULTISITENAMENOHYPHENS/g" "template.php"

          echo "Done."

          echo -n "
  *************************************************************************

  Do you want to create a symlink to a node_modules directory so you can run
  Grunt in the theme to aggregate LESS into CSS?

  Y/n: "

          old_stty_cfg=$(stty -g)
          stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
          if echo "$answer" | grep -iq "^y" ;then
            # Get the target path.
            NODEMODULESPATH_DEFAULT="/Volumes/Sites/Greyhead Design/node_modules"

            echo -n "
          *************************************************************************

          What is the path to the node_modules directory (ending in the node_modules
          directory name. Don't include a trailing slash).

          For example: /Volumes/Sites/Greyhead Design/node_modules

          Leave blank for default '$NODEMODULESPATH_DEFAULT') : "
            read NODEMODULESPATH

            if [ "x$NODEMODULESPATH" = "x" ]; then
              NODEMODULESPATH="$NODEMODULESPATH_DEFAULT"
            fi
          fi

          cd "${MULTISITETHEMEPATH}/${MULTISITENAMENOHYPHENS}_bootstrap_subtheme"
          ln -s "$NODEMODULESPATH" node_modules

        else
          echo "Removing theme template from $MULTISITETHEMETEMPLATEPATH"
          rm -r "$MULTISITETHEMETEMPLATEPATH"
        fi

        # Commit and push.
        echo "Committing..."
        cd "$MULTISITEDIRECTORY"

        git add "./$MULTISITENAMENOHYPHENS"
        git commit -m "Setting up $MULTISITENAMENOHYPHENS multisite directory."
        git push

        echo "Committed.
        "
      fi
    fi

    if [ -e "$MULTISITESYMLINKLOCATION" ]; then
      rm "$MULTISITESYMLINKLOCATION"
    fi

    ln -s "$MULTISITEPHYSICALLOCATION" "$MULTISITESYMLINKLOCATION"

    # Link a couple of useful scripts into the project directory.
    ln -s "$BUILDPATH/scripts-of-usefulness/drush-rebuild-registry.sh" "$MULTISITEPHYSICALLOCATION/"
    ln -s "$BUILDPATH/scripts-of-usefulness/enable-development-settings.sh" "$MULTISITEPHYSICALLOCATION/"

    DRUSHALIASNAME="$MULTISITENAME.aliases.drushrc.php"
    DRUSHALIASESDIRECTORY="$BUILDPATH/sites-projects/_drush_aliases"
    DRUSHALIASPHYSICALLOCATION="$DRUSHALIASESDIRECTORY/$DRUSHALIASNAME"

    # If the alias doesn't exist but the sites-projects dir does,
    # we can attempt to create it.
    if [[ ! -f "$DRUSHALIASPHYSICALLOCATION" && -d "$BUILDPATH/sites-projects" ]]; then
      echo -n "
*************************************************************************

Do you want to create the Drush alias file $DRUSHALIASPHYSICALLOCATION? Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        # Make the aliases directory if not present.
        if [ ! -d "$DRUSHALIASESDIRECTORY" ]; then
          mkdir -p "$DRUSHALIASESDIRECTORY"
        fi

        cp "$BUILDPATH/multisite-template/template.aliases.drushrc.php" "$DRUSHALIASPHYSICALLOCATION"
      fi
    fi

    if [ -f "$DRUSHALIASPHYSICALLOCATION" ]; then

      # Check whether the alias has been set up for this build type already;
      # if not, offer to add it now.
      if grep -q "{{${BUILDTYPE}MULTISITENAMENOHYPHENS}}" "$DRUSHALIASPHYSICALLOCATION"; then
        echo "
*************************************************************************

Alias file already configured for this build type."
      else
        # Not configured - do we want to?

        echo -n "
*************************************************************************

This drush alias file hasn't been configured for a $BUILDTYPE environment yet;
do you want to add configuration for this build type and commit it now?

This will allow you to do, for example:

$ drush @${MULTISITENAMENOHYPHENS}.${BUILDTYPE} cc all

Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
#          echo "Ha! Fooled you! This script can't set up the drush alias because bash/perl is a pain in the arse at replacing a placeholder with a slash. If you can figure it out, please help yourself to a biscuit. You've earnt it."

          perl -pi -e "s/{{MULTISITENAMENOHYPHENS}}/$MULTISITENAMENOHYPHENS/g" "$DRUSHALIASPHYSICALLOCATION"

#          perl -pi -e "s/{{-user}}/$USERNAME/g" "$USERNAMESHORT.aliases.drushrc.php"

          perl -pi -e "s/{{BUILDPATH-$BUILDTYPE}}/$BUILDPATH/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ "x$URI" = "x" ]; then
            echo -n "What is the site URL, without http:// or any trailing slash?: "
            read URI
          fi

          perl -pi -e "s/{{URI-$BUILDTYPE}}/$URI/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ ! "x$DRUSHREMOTEHOST" = "x" ]; then
            if [ "$BUILDTYPE" = "LOCAL" ]; then
              DRUSHREMOTEHOST="127.0.0.1"
            else
              echo -n "What is the remote hostname or IP? Leave blank for the default '$URI': "
              read DRUSHREMOTEHOST

              if [ "x$DRUSHREMOTEHOST" = "x" ]; then
                DRUSHREMOTEHOST="127.0.0.1"
              fi
            fi
          fi

          perl -pi -e "s/{{DRUSHREMOTEHOST-$BUILDTYPE}}/$DRUSHREMOTEHOST/g" "$DRUSHALIASPHYSICALLOCATION"

          if [ ! "x$DRUSHREMOTEUSER" = "x" ]; then
            echo -n "What is the username to run Drush commands as, on the remote host?

This is usually the user account under which the website is hosted, and not www-data.

Leave blank for the default '$MULTISITENAMENOHYPHENS': "
            read DRUSHREMOTEUSER
          fi

          perl -pi -e "s/{{DRUSHREMOTEUSER-$BUILDTYPE}}/$DRUSHREMOTEUSER/g" "$DRUSHALIASPHYSICALLOCATION"

          cd "$DRUSHALIASESDIRECTORY"
          git add "$DRUSHALIASPHYSICALLOCATION"
          git commit -m "Added Drush alias file for $MULTISITENAME. May be mangled, so please check."
          git push

          echo "Alias file configured. Maybe. Please verify it's okay:

*************************************************************************
"
        cat "$DRUSHALIASPHYSICALLOCATION"
        echo "
*************************************************************************
"
        fi
      fi

#      echo "
#*************************************************************************
#
#Symlinking $DRUSHALIASPHYSICALLOCATION to $BUILDPATH/core/www/sites/all/drush/$DRUSHALIASNAME:"
#
#      if [ -d "$BUILDPATH/core/www/sites/all/drush" ]; then
#        mkdir "$BUILDPATH/core/www/sites/all/drush"
#      fi
#
#      ln -s "$DRUSHALIASPHYSICALLOCATION" "$BUILDPATH/core/www/sites/all/drush/$DRUSHALIASNAME"
    fi

    if [ ! "x$URI" = "x" ]; then
      echo "
*************************************************************************

Creating the settings.this_site_url.info file at $BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/settings.this_site_url.info"

      echo "SETTINGS_SITE_URLS[] = $URI" > "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/settings.this_site_url.info"

      echo "

      Done.

      "
    fi
  fi
fi

# Create symlinks.
echo "
*************************************************************************

";

if [[ -d "$BUILDPATH/core/www" && -d "$BUILDPATH/sites-common" ]]; then
  # Symlink common first.
  COMMONSITESSYMLINKPATH="$BUILDPATH/core/www/sites"
  COMMONSITESPHYSICALPATH="$BUILDPATH/sites-common"
  if [ -e "$COMMONSITESSYMLINKPATH" ]; then
    rm "$COMMONSITESSYMLINKPATH"
  fi

  echo "Linking $COMMONSITESSYMLINKPATH to $COMMONSITESPHYSICALPATH:"
  ln -s "$COMMONSITESPHYSICALPATH" "$COMMONSITESSYMLINKPATH"

  # Symlink drush aliases.
  DRUSHALIASESSYMLINKPATH="$BUILDPATH/core/www/sites/all/drush"
  DRUSHALIASESPHYSICALPATH="$BUILDPATH/sites-projects/_drush_aliases"
  if [ -e "$DRUSHALIASESSYMLINKPATH" ]; then
    rm
  fi

  echo "Linking $DRUSHALIASESSYMLINKPATH to $DRUSHALIASESPHYSICALPATH:"
  ln -s "$DRUSHALIASESPHYSICALPATH" "$DRUSHALIASESSYMLINKPATH"
fi

# Symlink the multisite itself.
MULTISITESYMLINKPATH="$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS"
MULTISITEPHYSICALPATH="$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS"
if [[ -d "$BUILDPATH/core/www" && -d "$MULTISITEPHYSICALPATH" && ! -e "$MULTISITESYMLINKPATH" ]]; then
  echo "Linking $MULTISITESYMLINKPATH to $MULTISITEPHYSICALPATH:"
  ln -s "$MULTISITEPHYSICALPATH" "$MULTISITESYMLINKPATH"
fi

if [[ -d "$BUILDPATH/core/www" && -d "$BUILDPATH/multisite-maker" ]]; then
  # Symlink multisitemaker.
  MULTISITEMAKERSYMLINKPATH="$BUILDPATH/core/www/multisitemaker"
  MULTISITEMAKERPHYSICALPATH="$BUILDPATH/multisite-maker"
  if [ -e "$MULTISITEMAKERSYMLINKPATH" ]; then
    rm "$MULTISITEMAKERSYMLINKPATH"
  fi

  echo "Linking $MULTISITEMAKERSYMLINKPATH to $MULTISITEMAKERPHYSICALPATH:"
  ln -s "$MULTISITEMAKERPHYSICALPATH" "$MULTISITEMAKERSYMLINKPATH"
fi

# Only symlink to files if we're not building for live, if the multisite dir
# is set up, and there isn't already a files link/directory.
if [[ ! "$BUILDTYPE" = "LIVE" && -d "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS" ]]; then
  echo "
*************************************************************************

Symlinking $BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/files to $FILESPATH: "

  if [ -e "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/files" ]; then
    echo "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/files exists; moving it to $BUILDPATH/files-old..."
    mv "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/files" "$BUILDPATH/files-old"
  fi

  ln -s "$FILESPATH" "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS/files"
fi

# ---

# Only create local_databases.php and local_settings.php files if we're not
# building for live.
if [ ! "$BUILDTYPE" = "LIVE" ]; then
  echo -n "
  *************************************************************************

  Do you already have local_databases.php and local_settings.php files or do you
  need to create new ones from the multisite template?

  1. I already have local_databases.php and local_settings.php files.
  2. I need to create local_databases.php and local_settings.php files.

  1/2: "

  LOCALFILESCHOICE=""
  until [ "$LOCALFILESCHOICE" = "1" ] || [ "$LOCALFILESCHOICE" = "2" ]; do
    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^1" ;then
      LOCALFILESCHOICE="1"
    elif echo "$answer" | grep -iq "^2" ;then
      LOCALFILESCHOICE="2"
    fi
  done

  if [ "$LOCALFILESCHOICE" = "1" ]; then
    # Yes, get the files' absolute path.
    EXISTING_LOCALSETTINGSPATH_DEFAULT="$BUILDPATH/../local_settings.php"

    until [ -f "$EXISTING_LOCALSETTINGSPATH" ]; do
      echo -n "
  *************************************************************************

  What is the absolute path to the local_settings.php file, including the filename?

  Leave blank to use the default: '$EXISTING_LOCALSETTINGSPATH_DEFAULT'
  : "
      read EXISTING_LOCALSETTINGSPATH_ENTERED
      if [ ! "x$EXISTING_LOCALSETTINGSPATH_ENTERED" = "x" ]; then
        EXISTING_LOCALSETTINGSPATH=$EXISTING_LOCALSETTINGSPATH_ENTERED
      else
        EXISTING_LOCALSETTINGSPATH=$EXISTING_LOCALSETTINGSPATH_DEFAULT
      fi

      if [ ! -f "$EXISTING_LOCALSETTINGSPATH" ]; then
        echo "Oops! '$EXISTING_LOCALSETTINGSPATH' either doesn't exist or isn't accessible. Please try again..."
      fi
    done

    EXISTING_LOCALDATABASESPATH_DEFAULT="$BUILDPATH/../local_databases.php"

    until [ -f "$EXISTING_LOCALDATABASESPATH" ]; do
      echo -n "
  *************************************************************************

  What is the absolute path to the local_databases.php file, including the filename?

  Leave blank to use the default: '$EXISTING_LOCALDATABASESPATH_DEFAULT'
  : "
      read EXISTING_LOCALDATABASESPATH_ENTERED
      if [ ! "x$EXISTING_LOCALDATABASESPATH_ENTERED" = "x" ]; then
        EXISTING_LOCALDATABASESPATH=${EXISTING_LOCALDATABASESPATH_ENTERED}
      else
        EXISTING_LOCALDATABASESPATH=${EXISTING_LOCALDATABASESPATH_DEFAULT}
      fi

      if [ ! -f "$EXISTING_LOCALDATABASESPATH" ]; then
        echo "Oops! '$EXISTING_LOCALDATABASESPATH' either doesn't exist or isn't accessible. Please try again..."
      fi
    done

    # Symlink local_settings and local_databases.
    ln -s ${EXISTING_LOCALDATABASESPATH} "$BUILDPATH/core/local_databases.php"
    ln -s ${EXISTING_LOCALSETTINGSPATH} "$BUILDPATH/core/local_settings.php"

#    # Is there a Drush alias?
#    if [ -f "$DRUSHALIASPHYSICALLOCATION" ]; then
#      echo "
#  *************************************************************************
#
#  Symlinking $DRUSHALIASPHYSICALLOCATION to $BUILDPATH/core/www/sites/all/drush/$DRUSHALIASNAME: "
#
#      if [ -d "$BUILDPATH/core/www/sites/all/drush" ]; then
#        mkdir "$BUILDPATH/core/www/sites/all/drush"
#      fi
#
#      ln -s "$DRUSHALIASPHYSICALLOCATION" "$BUILDPATH/core/www/sites/all/drush/$DRUSHALIASNAME"
#    fi

  elif [ "$LOCALFILESCHOICE" = "2" ]; then
    # No existing local settings/db file, but we want one.
    LOCALDATABASESPATH="$BUILDPATH/core/local_databases.php"

    echo "
  *************************************************************************

  Copying local_databases.php and local_settings.php to $BUILDPATH/core.

  You will be asked for the database connection details shortly; if you don't
  want to or can't set them up now, you will need to edit the file at
  $LOCALDATABASESPATH to set them."

    cp "$BUILDPATH/multisite-template/local_databases.template.php" "$LOCALDATABASESPATH"

    LOCALSETTINGSFILEPATH="$BUILDPATH/core/local_settings.php"
    cp "$BUILDPATH/multisite-template/local_settings.template.php" "$LOCALSETTINGSFILEPATH"
  fi

  # ---

  # Only ask for DB connection details if we just created the
  # $LOCALDATABASESPATH file.
  if [ ! "x$LOCALDATABASESPATH" = "x" ] && [ ! "x$MULTISITENAME" = "x" ]; then
    echo -n "
  *************************************************************************

  Do you know the database connection details, and want to set them in $LOCALDATABASESPATH? Y/n: "

    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^y" ;then
      # Get DB connection details: DB name, username, password, host, and port.
      until [ ! "x$DBNAME" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database name? (required): "
        read DBNAME
        if [ "x$DBNAME" = "x" ]; then
            echo "Oh no! You need to provide the database name. Please go back and try again."
        fi
      done
      echo "Using: $DBNAME.

      ---"

      until [ ! "x$DBUSERNAME" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database username? (required): "
        read DBUSERNAME
        if [ "x$DBUSERNAME" = "x" ]; then
            echo "Oh no! You need to provide the database username. Please go back and try again."
        fi
      done
      echo "Using: $DBUSERNAME.

      ---"

      until [ ! "x$DBPASSWORD" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the database password? (required): "
        read DBPASSWORD
        if [ "x$DBPASSWORD" = "x" ]; then
            echo "Oh no! You need to provide the database password - blank passwords aren't allowed (sorry). Please go back and try again."
        fi
      done
      echo "Using: $DBPASSWORD.

      ---"

      echo -n "
  *************************************************************************

  What is the database host? Leave empty for the default: 127.0.0.1: "
      read DBHOST
      if [ "x$DBHOST" = "x" ]; then
        DBPORT="127.0.0.1"
      fi
      echo "Using: $DBHOST

      ---"

      echo -n "
  *************************************************************************

  What is the database port? Leave empty for the default: 3306: "
      read DBPORT
      if [ "x$DBPORT" = "x" ]; then
        DBPORT=3306
      fi
      echo "Using: $DBPORT

      ---"

      # Create the DB connection string and inject into $LOCALDATABASESPATH before
      # "  // {{BUILDSHINSERT}}".

      # AROOGA ALERT! Finding a working search-replace command has been a f***ing
      # nightmare :( So please, if you're as synaptically challenged as I am, please
      # please please don't mess with the code on the following lines unless,
      # well, you wrote perl. Or something. I dunno. I've just spent three hours
      # trying to fix this. Three hours! Why did I do that? I could have taken a
      # plane to Spain in that time and now I could be sunning myself on a beach,
      # drinking cheap, warm Sangria out of a carton smeared with sand from the
      # "beach" I've rocked up to, which in reality is no more than a handful of
      # builders' sand (you know, the stuff that turns your skin orange) tossed
      # over the rubble and other apocryphal detritus that is left over when a
      # fast, cheap, dodgy building project on the continent leaves town.

      # So, er, yeah. Be careful with this code please...

      CONNECTIONSTRING="'$MULTISITENAME' => array('$URI' => array('database' => '$DBNAME', 'username' => '$DBUSERNAME', 'password' => '$DBPASSWORD', 'port' => '$DBPORT')),"

      cd "$BUILDPATH/core"
      echo ${CONNECTIONSTRING} > local_databases.tmp

      sed -e '/BUILDSHINSERT}}/r./local_databases.tmp' local_databases.php > local_databases_2.php
      mv local_databases_2.php local_databases.php
      rm local_databases.tmp

      # Here ends todays whinge...

      echo "
  *************************************************************************

  Done. Please check the output of local_databases.php to make sure it looks okay:

  ****************************************************************************"

      cat "$LOCALDATABASESPATH"

      echo "
  ****************************************************************************
      "
    fi

    echo -n "
  *************************************************************************

  Do you have a database dump you want to import? Y/n: "

    old_stty_cfg=$(stty -g)
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
    if echo "$answer" | grep -iq "^y" ;then
      # Get the DB path.
      DATABASEDUMPPATH="monkey"

      until [ -e "$DATABASEDUMPPATH" ] || [ "x$DATABASEDUMPPATH" = "x" ]; do
        echo -n "
  *************************************************************************

  What is the absolute path to the database dump file, including the filename? (Leave blank to skip importing the database dump.)
  : "
        read DATABASEDUMPPATH

        if [ ! "x$DATABASEDUMPPATH" = "x" ]; then
          if [ ! -e "$DATABASEDUMPPATH" ]; then
            echo "Oops! '$DATABASEDUMPPATH' either doesn't exist or isn't a readable file. Please try again..."
          else
            COMMAND="mysql -u \"$DBUSERNAME\" -p\"$DBPASSWORD\" \"$DBNAME\" < \"$DATABASEDUMPPATH\""
            echo "Attempting import: $COMMAND...
            "
            eval ${COMMAND}
            echo "MySQL import done."
          fi
        fi

      done
    else
      echo -n "
  *************************************************************************

  If the database contains an existing Drupal installation, do you want to rebuild caches?

  This is recommended to prevent errors caused by the file system structure changing.

  Y/n: "

      old_stty_cfg=$(stty -g)
      stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
      if echo "$answer" | grep -iq "^y" ;then
        echo "Testing database..."

        # Run the script which clears caches and rebuilds the registry.
        COMMAND="\"$BUILDPATH/scripts-of-usefulness/drush-rebuild-registry.sh\" --uri=\"$URI\" --multisitename=\"$MULTISITENAME\" --buildpath=\"$BUILDPATH\" --drupalversion=7"
        eval ${COMMAND}
      else

        # Do they want us to install Drupal?
        echo -n "
  *************************************************************************

  Do you want to run the Drupal installer? This will wipe the database and
  set up a minimal Drupal install with a number of base modules and settings
  configured.

  Y/n: "

        old_stty_cfg=$(stty -g)
        stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
        if echo "$answer" | grep -iq "^y" ;then
          # Get the admin username and password.
          echo -n "
  *************************************************************************

  Please choose an administrator username for the root Drupal user: "
          read ADMINUSERNAME

          echo -n "
  *************************************************************************

  Please choose a password for $ADMINUSERNAME: "
          read ADMINPASS

          echo -n "
  *************************************************************************

  What is the site's name, e.g. 'Widgets Online': "
          read SITENAME

          echo -n "
  *************************************************************************

  What is the site's email address?: "
          read SITEMAIL

          echo -n "
  *************************************************************************

  What install profile should we use? Leave blank for the default, 'greyheadprofile': "
          read PROFILE

          if [ "x$PROFILE" = "x" ]; then
            PROFILE="greyheadprofile"
          fi

          FEATURESTOENABLE="drupal_search paragraph_page development_settings backup_migrate_daily"

          echo -n "
  *************************************************************************

  Should $URI be accessed over http or https? Enter 'http' or 'https', or leave blank for 'https': "
          read PROTOCOL

          if [ "x$PROTOCOL" = "x" ]; then
            PROTOCOL="https"
          fi

          FEATURESTOENABLE="drupal_search paragraph_page development_settings backup_migrate_daily"

          # Do they want to enable four_communications_base_modules?
          if [ "$FEATURESCHECKOUT" = "fourcommunications" ]; then
            FEATURESTOENABLE="$FEATURESTOENABLE four_communications_base_modules fourcomms_update_notifications four_communications_user_roles four_login_toboggan_settings"
          # Otherwise, do they want to enable common_base_modules?
          elif [ -d "$BUILDPATH/features/common_base_modules" ]; then
            FEATURESTOENABLE="$FEATURESTOENABLE common_base_modules update_notifications_redirect common_user_roles login_toboggan_settings"
          fi

          echo "
  *************************************************************************

  Beginning install.

  IMPORTANT: if the install process fails, check that the mysql server is
  running. If you are using MAMP, you may need to use 'localhost' instead of
  '127.0.0.1' to connect.

  Running Drush site install command:

    cd \"$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS\"

    drush --uri=\"$URI\" site-install -d \"$PROFILE\" --db-url=\"mysql://$DBUSERNAME:$DBPASSWORD@$DBHOST:$DBPORT/$DBNAME\" --account-name=\"$ADMINUSERNAME\" --account-pass=\"$ADMINPASS\" --account-mail=\"$SITEMAIL\" --site-name=\"$SITENAME\" --site-mail=\"$SITEMAIL\"

    drush --uri=\"$URI\" en features \"$FEATURESTOENABLE\" -y

    drush --uri=\"$URI\" fra -y

    drush --uri=\"$URI\" cc all

  ...

  "

          drush --uri="$URI" site-install -d "$PROFILE" --db-url="mysql://$DBUSERNAME:$DBPASSWORD@$DBHOST:$DBPORT/$DBNAME" --account-name="$ADMINUSERNAME" --account-pass="$ADMINPASS" --account-mail="$SITEMAIL" --site-name="$SITENAME" --site-mail="$SITEMAIL"
          cd "$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS"

          echo "
  *************************************************************************

  Drupal installed - enabling features..."

          drush --uri="$URI" en features "$FEATURESTOENABLE" -y

          echo "
  *************************************************************************

  Reverting features..."

          drush --uri="$URI" fra -y

          if [ ! "x$THEMENAME" = "x" ]; then

            echo "
    *************************************************************************

    Setting the theme to $THEMENAME:"

            drush --uri="$URI" enable "$THEMENAME" -y
            drush --uri="$URI" vset theme_default "$THEMENAME" -y

          fi

          echo "
  *************************************************************************

  Clearing caches..."

          drush --uri="$URI" cc all

          # Open the site in a web browser.
          COMMAND="\"$BUILDPATH/scripts-of-usefulness/script-components/open-url.sh\" $PROTOCOL://$URI"
          eval ${COMMAND}

          echo "
  *************************************************************************

  You can now browse your site at $PROTOCOL://$URI - yay!"

        fi
      fi
    fi
  fi
fi

# If we're building for live, move the directories around and create the tar.gz
# archive.
if [ "$BUILDTYPE" = "LIVE" ]; then
  echo "Moving files around for live..."

#  This is the directory structure we have - a . indicates the directory needs
#  to be moved, if it exists.
#
#  /
#    core
#      www
#        sites -> /sites-common
#  . features*
#  . sites-common
#      [MULTISITENAME]* -> /sites-projects/[MULTISITENAME]
#      all
#        libraries
#        modules
#          contrib
#          custom
#          features* -> /features
#        themes
#      sites.php
#    sites-projects*
#    . [MULTISITENAME]
#
#  This is the directory structure we want:
#
#  /
#    core
#      www
#        sites
#          [MULTISITENAME]*
#          all
#            libraries
#            modules
#              contrib
#              custom
#              features
#            themes
#          sites.php
#
#  Therefore, directories to be moved, if they exist:
#
#  . sites-common (must go first)
#  . features*
#  . [MULTISITENAME]

  cd "$BUILDPATH"

  # If sites-common is present.
  if [ -d "$BUILDPATH/sites-common" ]; then
    # If core/www/sites exists.
    if [ -e "$BUILDPATH/core/www/sites" ]; then
      rm -rf "$BUILDPATH/core/www/sites"
    fi

    # Move sites-common to core/www/sites.
    mv "$BUILDPATH/sites-common" "$BUILDPATH/core/www/sites"
  fi

  # If features is present.
  if [ -d "$BUILDPATH/features" ]; then
    # If core/www/sites/all/features exists.
    if [ -e "$BUILDPATH/core/www/sites/all/modules/features" ]; then
      rm -rf "$BUILDPATH/core/www/sites/all/modules/features"
    fi

    # Move features to core/www/sites/all/features.
    mv "$BUILDPATH/features" "$BUILDPATH/core/www/sites/all/modules/features"
  fi

  # If sites-projects/$MULTISITENAMENOHYPHENS is present.
  if [ -d "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS" ]; then
    # If core/www/sites/$MULTISITENAMENOHYPHENS exists.
    if [ -e "$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS" ]; then
      rm -rf "$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS"
    fi

    # Move sites-projects/$MULTISITENAMENOHYPHENS to
    # core/www/sites/$MULTISITENAMENOHYPHENS.
    mv "$BUILDPATH/sites-projects/$MULTISITENAMENOHYPHENS" "$BUILDPATH/core/www/sites/$MULTISITENAMENOHYPHENS"
  fi

  # Lastly, remove the rest of sites-projects an multisite-template.
  rm -rf "$BUILDPATH/sites-projects"
  rm -rf "$BUILDPATH/multisite-template"

  # Now create the tar.gz. Change to the parent dir of the build directory.
  cd "$BUILDPATH/.."

  # Create a new directory called drupal7-$MULTISITENAMENOHYPHENS-v$CREATETAG.tar.gz
  TAGARCHIVENAME="$BUILDARCHIVENAME.tar.gz"
  tar -czvf "$BUILDPATH/../$TAGARCHIVENAME" "$BUILDARCHIVENAME"

  # Do we want to keep the build directory, e.g. for debuggerising purposes?
  echo -n "
*************************************************************************

The live deployment has been built and tagged, and an archive created in

$BUILDPATH/../$TAGARCHIVENAME

Do you want to remove the unarchived Drupal build, e.g. for debugging, or
would you like to delete them?

(R)emove or (K)eep: "

  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
  if echo "$answer" | grep -iq "^r" ;then
    echo "Removing $BUILDPATH ..."
    cd "$BUILDPATH/.."
    rm -rf "$BUILDPATH"
  else
    cd "$BUILDPATH"
  fi
else
  cd "$BUILDPATH"
fi

echo "
*************************************************************************

All finished. Enjoy! :)

*************************************************************************
"

