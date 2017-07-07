#!/bin/bash

set -e

if [ "$0" != "./scripts/build-release.sh" ]; then
    echo "'build-release.sh' should be run from repository root"
    exit 1
fi

function usage(){
  >&2 echo "
 Usage:
    $0 [version]
 Ex:
    $0 0+dev.1
"
  exit 1
}

if [ "$1" == "-h" ] || [ "$1" == "--help"  ] || [ "$1" == "help"  ]; then
    usage
fi


if [ "$#" -gt 0 ]; then
    if [ -e "$1" ]; then
        export version=`cat $1`
    else
        export version=$1
    fi
fi

echo '################################################################################'
echo "Building artifactory-boshrelese ${version}"
echo '################################################################################'
echo ''

echo '################################################################################'
echo 'Cleaning up blobs'
echo '################################################################################'
echo ''

rm -rf .blobs/* blobs/*
echo "--- {} " > config/blobs.yml

echo '################################################################################'
echo 'Downloading binaries'
echo '################################################################################'
echo ''

if [ ! -d './tmp' ]; then
  mkdir -p ./tmp/completed
fi

cd ./tmp

if [ -e './completed/httpd-2.4.26.tar.gz' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file httpd-2.4.26.tar.gz'
  curl -O http://apache.mirror.iweb.ca//httpd/httpd-2.4.26.tar.gz
  mv httpd-2.4.26.tar.gz completed/
fi

if [ -e './completed/apr-1.6.2.tar.gz' ]; then
  echo 'apr package already exists, skipping'
else
  echo 'Downloading file apr-1.6.2.tar.gz'
  curl -O http://apache.mirror.iweb.ca//apr/apr-1.6.2.tar.gz
  mv apr-1.6.2.tar.gz completed/
fi

if [ -e './completed/apr-util-1.6.0.tar.gz' ]; then
  echo 'apr-util package already exists, skipping'
else
  echo 'Downloading file apr-util-1.6.0.tar.gz'
  curl -O http://apache.mirror.iweb.ca//apr/apr-util-1.6.0.tar.gz
  mv apr-util-1.6.0.tar.gz completed/
fi

if [ -e './completed/expat-2.2.1.tar.bz2' ]; then
  echo 'expat package already exists, skipping'
else
  echo 'Downloading file expat-2.2.1.tar.bz2'
  curl -o expat-2.2.1.tar.bz2 -k -L https://sourceforge.net/projects/expat/files/expat/2.2.1/expat-2.2.1.tar.bz2/download
  mv expat-2.2.1.tar.bz2 completed/
fi

if [ -e './completed/jfrog-artifactory-pro-5.3.2.zip' ]; then
  echo 'jfrog-artifactory-pro package already exists, skipping'
else
  echo 'Downloading file jfrog-artifactory-pro-5.3.2.zip'
  curl -o jfrog-artifactory-pro-5.3.2.zip -L -O https://bintray.com/jfrog/artifactory-pro/download_file?file_path=org%2Fartifactory%2Fpro%2Fjfrog-artifactory-pro%2F5.3.2%2Fjfrog-artifactory-pro-5.3.2.zip
  mv jfrog-artifactory-pro-5.3.2.zip completed/
fi

if [ -e './completed/jre-8u131-linux-x64.tar.gz' ]; then
  echo 'jre-8 package already exists, skipping'
else
  echo 'Downloading file jre-8u131-linux-x64.tar.gz'
  curl -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz > jre-8u131-linux-x64.tar.gz
  mv jre-8u131-linux-x64.tar.gz completed/
fi

if [ -e './completed/pcre-8.40.tar.gz' ]; then
  echo 'pcre package already exists, skipping'
else
  echo 'Downloading file pcre-8.40.tar.gz'
  curl -O https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz
  mv pcre-8.40.tar.gz completed/
fi

if [ -e './completed/postgresql-42.1.1.jar' ]; then
  echo 'postgresql package already exists, skipping'
else
  echo 'Downloading file postgresql-42.1.1.jar'
  curl -O https://jdbc.postgresql.org/download/postgresql-42.1.1.jar
  mv postgresql-42.1.1.jar completed/
fi

cd -

echo ''
echo '################################################################################'
echo 'Adding blobs'
echo '################################################################################'
echo ''

echo 'Adding blob apache2/httpd-2.4.26.tar.gz'
bosh add blob ./tmp/completed/httpd-2.4.26.tar.gz apache2

echo 'Adding blob apr/apr-1.6.2.tar.gz'
bosh add blob ./tmp/completed/apr-1.6.2.tar.gz apr

echo 'Adding blob apr-util/apr-util-1.6.0.tar.gz'
bosh add blob ./tmp/completed/apr-util-1.6.0.tar.gz apr-util

echo 'Adding blob expat/expat-2.2.1.tar.bz2'
bosh add blob ./tmp/completed/expat-2.2.1.tar.bz2 expat

echo 'Adding blob jfrog-artifactory-pro/jfrog-artifactory-pro-5.3.2.zip'
bosh add blob ./tmp/completed/jfrog-artifactory-pro-5.3.2.zip jfrog-artifactory-pro

echo 'Adding blob jre-8/jre-8u131-linux-x64.tar.gz'
bosh add blob ./tmp/completed/jre-8u131-linux-x64.tar.gz jre-8

echo 'Adding blob pcre/pcre-8.40.tar.gz'
bosh add blob ./tmp/completed/pcre-8.40.tar.gz pcre

echo 'Adding blob postgres-jdbc-driver/postgresql-42.1.1.jar'
bosh add blob ./tmp/completed/postgresql-42.1.1.jar postgres-jdbc-driver

echo ''
echo '################################################################################'
echo 'Creating release'
echo '################################################################################'
echo ''

echo "Creating release"
create_cmd="bosh create release --name artifactory --with-tarball --force"
if [ "$version" != "" ]; then
    create_cmd+=" --version "${version}""
fi

eval ${create_cmd}
