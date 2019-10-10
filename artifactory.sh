#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOSTNAME=artifactory.geniepay.io

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo 'Setting hostname...'
echo $HOSTNAME > /etc/hostname

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
apt install -y fail2ban wget curl unzip
apt install -y software-properties-common # contains add-apt-repository

color_echo 'Installing OpenJDK...'
add-apt-repository -y ppa:openjdk-r/ppa
apt install -y openjdk-11-jdk

color_echo 'Installing Artifactory OSS...'
echo 'deb https://jfrog.bintray.com/artifactory-debs bionic main' > /etc/apt/sources.list
curl https://bintray.com/user/downloadSubjectPublicKey?username=jfrog | apt-key add -
apt update
apt install jfrog-artifactory-oss

color_echo 'Post installation interaction...'
adduser erdenian
adduser erdenian sudo
cat <<EOT >> /etc/ssh/sshd_config
DenyUsers root
PermitEmptyPasswords no
EOT
