#!/usr/bin/env bash

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh JOB_NAME OUTPUT_LABEL
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar nginx

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME=$1
output_label=${2:-${JOB_NAME}}

export JOB_DIR=/var/vcap/jobs/$JOB_NAME
chmod 755 $JOB_DIR # to access file via symlink

# Load some bosh deployment properties into env vars
# Try to put all ERb into data/properties.sh.erb
# incl $NAME, $JOB_INDEX, $WEBAPP_DIR
source $JOB_DIR/data/properties.sh

source $JOB_DIR/helpers/ctl_utils.sh
redirect_output ${output_label}

export HOME=${HOME:-/home/vcap}

# Setup the PATH
export PATH=/var/vcap/packages/jfrog-artifactory-pro/bin:$PATH

# Setup log, run and tmp folders

export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
export DATA_DIR=/var/vcap/data/$JOB_NAME
for dir in $RUN_DIR $LOG_DIR $TMP_DIR $STORE_DIR
do
  mkdir -p ${dir}
  chown vcap:vcap ${dir}
  chmod 775 ${dir}
done
export TMPDIR=$TMP_DIR

if [[ -d /var/vcap/packages/jre-8 ]]
then
  export JAVA_HOME="/var/vcap/packages/jre-8"
fi

export ARTIFACTORY_HOME=/var/vcap/packages/jfrog-artifactory-pro

if [[ ! -d $LOG_DIR/catalina ]]
then
  mkdir $LOG_DIR/catalina
  ln -s $LOG_DIR/catalina $ARTIFACTORY_HOME/tomcat/logs
fi

if [[ ! -f $LOG_DIR/artifactory.log ]]
then
  touch $LOG_DIR/artifactory.log
fi

if [[ ! -L $ARTIFACTORY_HOME/logs ]]
then
  rm -rf $ARTIFACTORY_HOME/logs
  ln -s $LOG_DIR $ARTIFACTORY_HOME/logs
fi

if [[ ! -L $ARTIFACTORY_HOME/run ]]
then
  ln -s $RUN_DIR $ARTIFACTORY_HOME/run  
fi

if [[ ! -f $ARTIFACTORY_HOME/etc/artifactory.lic ]]
then
  cp /var/vcap/jobs/artifactory/etc/artifactory.lic $ARTIFACTORY_HOME/etc/
fi

cp /var/vcap/jobs/artifactory/etc/db.properties $ARTIFACTORY_HOME/etc/db.properties

if [[ ! -L $ARTIFACTORY_HOME/tomcat/lib/postgresql-42.1.1.jar ]]
then
  ln -s /var/vcap/packages/postgres-jdbc-driver/postgresql-42.1.1.jar $ARTIFACTORY_HOME/tomcat/lib/postgresql-42.1.1.jar
fi

if ! grep -Fxq "artifactory.onboarding.skipWizard=true" $ARTIFACTORY_HOME/etc/artifactory.system.properties
then
  echo 'artifactory.onboarding.skipWizard=true' >> $ARTIFACTORY_HOME/etc/artifactory.system.properties
fi

cp /var/vcap/jobs/artifactory/bin/artifactory.default $ARTIFACTORY_HOME/bin/artifactory.default

chown -RL vcap:vcap $ARTIFACTORY_HOME/
chmod +x $ARTIFACTORY_HOME/tomcat/bin/*.sh

if [[ ! -d $STORE_DIR/data ]]
then
  mkdir $STORE_DIR/data
  chown vcap:vcap $STORE_DIR/data
  cp /var/vcap/jobs/artifactory/etc/binarystore.xml $ARTIFACTORY_HOME/etc/binarystore.xml
fi

if [[ ! -L $ARTIFACTORY_HOME/backup ]]
then
  mkdir -p $STORE_DIR/backup
  chown vcap:vcap $STORE_DIR/backup
  ln -s $STORE_DIR/backup $ARTIFACTORY_HOME/backup
fi

if [[ ! -d $STORE_DIR/access ]]
then
  mkdir -p $STORE_DIR/access
  chown vcap:vcap $STORE_DIR/access
  ln -s $STORE_DIR/access $ARTIFACTORY_HOME/access
fi

PIDFILE=$RUN_DIR/$output_label.pid

echo '$PATH' $PATH
