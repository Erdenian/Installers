#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master/artifactory
HOSTNAME=artifactory.geniepay.io

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

function download_from_host() {
    wget -O $1 $HOST/$1
    mv $1 $2
}

function setup_site() {
    download_from_host $1.conf /etc/apache2/sites-available/
    a2ensite $1
}

color_echo 'Setting hostname...'
echo $HOSTNAME > /etc/hostname

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y

color_echo 'Creating swap file...'
swapoff /swapfile
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

color_echo 'Installing russian locale...'
apt install -y language-pack-ru
update-locale LANG=ru_RU.UTF-8

color_echo 'Installing common packages...'
apt install -y fail2ban wget curl unzip
apt install -y software-properties-common # contains add-apt-repository

color_echo 'Installing OpenJDK...'
add-apt-repository -y ppa:openjdk-r/ppa
apt update
apt install -y openjdk-11-jdk

color_echo 'Installing Artifactory OSS...'
wget -qO - https://api.bintray.com/orgs/jfrog/keys/gpg/public.key | apt-key add -
echo "deb https://jfrog.bintray.com/artifactory-debs bionic main" | tee -a /etc/apt/sources.list
apt update
apt install -y jfrog-artifactory-oss
service artifactory start

color_echo 'Installing Apache...'
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
setup_site artifactory
apache2ctl restart

color_echo 'Post installation interaction...'
adduser erdenian
adduser erdenian sudo
cat <<EOT >> /etc/ssh/sshd_config
DenyUsers root
PermitEmptyPasswords no
EOT
