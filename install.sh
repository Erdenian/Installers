#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt update
apt full-upgrade -y

# russian locale
apt install -y language-pack-ru
update-locale LANG=ru_RU.UTF-8

apt install -y openjdk-8-jdk openjfx wget

# git
apt install -y software-properties-common
add-apt-repository -y ppa:git-core/ppa
apt update
apt install -y git

# jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt update
apt install -y jenkins
wget https://raw.githubusercontent.com/Erdenian/Ubuntu-VDS-installer/master/jenkins
mv jenkins /etc/default/jenkins
/etc/init.d/jenkins restart

# apache2
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
wget https://raw.githubusercontent.com/Erdenian/Ubuntu-VDS-installer/master/jenkins.conf
mv jenkins.conf /etc/apache2/sites-available/jenkins.conf
a2ensite jenkins
apache2ctl restart

