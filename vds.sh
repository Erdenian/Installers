#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master/vds
HOSTNAME=vds.erdenian.ru
ANDROID_SDK_TOOLS_LINK=https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
ANDROID_SDK_HOME=/opt/android
ANDROID_SDK_ROOT=$ANDROID_SDK_HOME/sdk

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

color_echo 'Setting hostname...'
echo $HOSTNAME > /etc/hostname

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y

color_echo 'Creating swap file...'
fallocate -l 8G /swapfile
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
apt install -y openjdk-8-jdk # Jenkins doesn't support Java 13, 8 will be set as default
apt install -y openjdk-13-jdk
update-java-alternatives --set java-1.8.0-openjdk-amd64

color_echo 'Installing Git...'
add-apt-repository -y ppa:git-core/ppa
apt install -y git

color_echo 'Installing Jenkins...'
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo 'deb http://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
apt update
apt install -y jenkins
download_from_host jenkins /etc/default/
/etc/init.d/jenkins restart

color_echo 'Installing Gitlab Runner...'
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash
apt install gitlab-runner

color_echo 'Installing Apache...'
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
setup_site jenkins
apache2ctl restart

color_echo 'Installing Android SDK...'
wget -O android-sdk-tools.zip $ANDROID_SDK_TOOLS_LINK
mkdir -p $ANDROID_SDK_ROOT
unzip android-sdk-tools.zip -d $ANDROID_SDK_ROOT
chmod -R 777 $ANDROID_SDK_HOME
rm android-sdk-tools.zip
set +o pipefail
yes | $ANDROID_SDK_ROOT/tools/bin/sdkmanager --licenses > /dev/null
set -o pipefail
echo "ANDROID_SDK_HOME=$ANDROID_SDK_HOME" >> /etc/environment
echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> /etc/environment

color_echo 'Post installation interaction...'

color_echo 'initialAdminPassword for Jenkins:'
cat /var/lib/jenkins/secrets/initialAdminPassword

adduser erdenian
adduser erdenian sudo
cat <<EOT >> /etc/ssh/sshd_config
DenyUsers root
PermitEmptyPasswords no
EOT
