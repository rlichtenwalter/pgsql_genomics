#! /bin/bash

# TO BE RUN AS root ON FRESH CENTOS 7 MINIMAL INSTALL

yum -y update
yum -y install wget unzip gcc perl dos2unix
yum -y install epel-release
yum -y install https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-3.noarch.rpm
yum -y install postgresql94 postgresql94-server postgresql94-contrib postgresql94-libs postgresql94-devel
export PATH=/usr/pgsql-9.4/bin:$PATH
postgresql94-setup initdb
systemctl enable postgresql-9.4.service
systemctl start postgresql-9.4.service
chkconfig postgresql-9.4 on
wget https://github.com/rlichtenwalter/pgsql_genomics/archive/master.zip
unzip master.zip
cd pgsql_genomics-master
./setup.sh
