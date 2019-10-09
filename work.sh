#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y

color_echo 'Installing common packages...'
apt install -y software-properties-common # contains add-apt-repository

color_echo 'Installing Google Chrome...'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
apt update
apt install -y google-chrome-stable
apt purge -y firefox*

color_echo 'Installing OpenJDK...'
add-apt-repository -y ppa:openjdk-r/ppa
apt install -y openjdk-8-jdk

color_echo 'Installing Git...'
add-apt-repository -y ppa:git-core/ppa
apt install -y git

color_echo 'Installing Snap...'
apt install -y snapd
snap install telegram-desktop
snap install slack --classic
snap install postman
snap install code --classic
snap install android-studio --classic
snap install intellij-idea-community --classic
