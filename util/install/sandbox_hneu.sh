#!/bin/sh
##
## Installs the pre-requisites for running edX on a single Ubuntu 12.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

##
## Sanity check
##
if [[ ! "$(lsb_release -d | cut -f2)" =~ $'Ubuntu 12.04' ]]; then
   echo "This script is only known to work on Ubuntu 12.04, exiting...";
   exit;
fi

##
## Set ppa repository source for gcc/g++ 4.8 in order to install insights properly
##
sudo apt-get install -y python-software-properties
sudo add-apt-repository ppa:ubuntu-toolchain-r/test

##
## Update and Upgrade apt packages
##
sudo apt-get update -y
sudo apt-get upgrade -y

##
## Install system pre-requisites
##
sudo apt-get install -y build-essential software-properties-common python-software-properties curl git-core libxml2-dev libxslt1-dev python-pip python-apt python-dev libxmlsec1-dev libfreetype6-dev swig gcc-4.8 g++-4.8
sudo pip install --upgrade pip
sudo -H pip install --upgrade virtualenv

##
## Update alternatives so that gcc/g++ 4.8 is the default compiler
##
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50

## Did we specify an openedx release?
if [ -n "$OPENEDX_RELEASE" ]; then
  EXTRA_VARS="-e edx_platform_version=$OPENEDX_RELEASE \
    -e certs_version=$OPENEDX_RELEASE \
    -e forum_version=$OPENEDX_RELEASE \
    -e xqueue_version=$OPENEDX_RELEASE \
    -e configuration_version=$OPENEDX_RELEASE \
	-e EDXAPP_LMS_BASE=edx1.hneu.net \
	-e EDXAPP_PREVIEW_LMS_BASE=preview.edx1.hneu.net \
	-e EDXAPP_LMS_PREVIEW_NGINX_PORT=80 \
	-e EDXAPP_CMS_NGINX_PORT=18010 \
	-e EDXAPP_LMS_NGINX_PORT=80 \
	-e EDXAPP_SITE_NAME=edx1.hneu.net \
	-e edxapp_use_custom_theme=true \
	-e edxapp_theme_name=mycustomtheme \
	-e edxapp_theme_source_repo=git://github.com/edxhneu/edx-theme.git \
	-e edxapp_theme_version=HEAD \
  "
  CONFIG_VER=$OPENEDX_RELEASE
else
  CONFIG_VER="master"
fi

##
## Clone the configuration repository and run Ansible
##
cd /var/tmp
git clone https://github.com/edx/configuration
cd configuration
git checkout $CONFIG_VER

##
## Install the ansible requirements
##
cd /var/tmp/configuration
sudo -H pip install -r requirements.txt

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
cd /var/tmp/configuration/playbooks && sudo ansible-playbook -c local ./edx_sandbox.yml -i "localhost," $EXTRA_VARS
