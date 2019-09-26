#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master/vds

function download_from_host() {
    wget -O $1 $HOST/$1
    mv $1 $2
}

function setup_site() {
    download_from_host $1.conf /etc/apache2/sites-available/
    a2ensite $1
}

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y

color_echo 'Creating swap file...'
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

color_echo 'Installing russian locale...'
apt install -y language-pack-ru
update-locale LANG=ru_RU.UTF-8

color_echo 'Installing common packages...'
apt install -y wget fail2ban
apt install -y software-properties-common # contains add-apt-repository

color_echo 'Adding repositories...'
# jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo 'deb http://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
# git
add-apt-repository -y ppa:git-core/ppa
# openjdk
add-apt-repository -y ppa:openjdk-r/ppa

color_echo 'Installing OpenJDK...'
apt install -y openjdk-12-jdk
apt install -y openjdk-8-jdk # Jenkins doesn't support Java 12, 8 will be set as default

color_echo 'Installing Git...'
apt install -y git

color_echo 'Installing Jenkins...'
apt install -y jenkins
download_from_host jenkins /etc/default/
/etc/init.d/jenkins restart

color_echo 'Installing Apache...'
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
setup_site jenkins
apache2ctl restart

color_echo 'Post installation interaction...'

color_echo 'initialAdminPassword for Jenkins:'
cat /var/lib/jenkins/secrets/initialAdminPassword

adduser erdenian
adduser erdenian sudo
cat <<EOT >> /etc/ssh/sshd_config
DenyUsers root
PermitEmptyPasswords no
EOT
