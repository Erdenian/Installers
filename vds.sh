#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master

function download_from_host() {
    wget -O $1 $HOST/$1
    mv $1 $2
}

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo "Ugrading pachages"
apt update
apt full-upgrade -y

color_echo "Installing russian locale"
apt install -y language-pack-ru
update-locale LANG=ru_RU.UTF-8

apt install -y openjdk-8-jdk openjfx wget

color_echo "Installing git"
apt install -y software-properties-common
add-apt-repository -y ppa:git-core/ppa
apt update
apt install -y git

color_echo "Installing Jenkins"
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
apt update
apt install -y jenkins
download_from_host jenkins /etc/default/jenkins
/etc/init.d/jenkins restart

color_echo "Installing Apache"
apt install -y apache2
a2enmod proxy
a2enmod proxy_http

a2dissite jenkins || true
download_from_host jenkins.conf /etc/apache2/sites-available/jenkins.conf
a2ensite jenkins

apache2ctl restart

