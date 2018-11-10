#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master/vds
POSTGRESQL_VERSION=11

function download_from_host() {
    wget -O $1 $HOST/$1
    mv $1 $2
}

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y

color_echo 'Installing russian locale...'
apt install -y language-pack-ru
update-locale LANG=ru_RU.UTF-8

color_echo 'Installing common packages...'
apt install -y openjdk-8-jdk openjfx wget
apt install -y software-properties-common # contains add-apt-repository
apt install -y curl ca-certificates # for postgresql apt
apt install -y sed # for postgresql setup

color_echo 'Adding repositories...'
# jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo 'deb http://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
# postgresql
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# git
add-apt-repository -y ppa:git-core/ppa

color_echo 'Installing git...'
apt install -y git

color_echo 'Installing Jenkins...'
apt install -y jenkins
download_from_host jenkins /etc/default/jenkins
/etc/init.d/jenkins restart

color_echo 'Installing PostgreSQL...'
apt install -y postgresql
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'\t/g" /etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf
echo 'host     all             all             0.0.0.0/0               md5' >> /etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf
echo 'host     all             all             ::/0                    md5' >> /etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf
sudo -u postgres psql --command '\password'
/etc/init.d/postgresql restart

color_echo 'Installing Apache...'
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
# jenkins site
download_from_host jenkins.conf /etc/apache2/sites-available/jenkins.conf
a2ensite jenkins
apache2ctl restart
