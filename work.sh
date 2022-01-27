#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

function color_echo() {
    echo -e "\e[32m$1\e[0m"
}

color_echo 'Applying settings...'
timedatectl set-local-rtc 1 --adjust-system-clock

color_echo 'Ugrading packages...'
apt update
apt full-upgrade -y
apt autoremove

color_echo 'Installing common packages...'
apt install -y software-properties-common # contains add-apt-repository

color_echo 'Installing Google Chrome...'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
apt update
apt install -y google-chrome-stable
apt purge -y firefox*
#snap remove firefox

color_echo 'Installing OpenJDK...'
add-apt-repository -y ppa:openjdk-r/ppa
apt install -y openjdk-17-jdk

color_echo 'Installing Git...'
add-apt-repository -y ppa:git-core/ppa
apt install -y git

color_echo 'Installing Guvcview...'
add-apt-repository -y ppa:pj-assis/ppa
apt install -y guvcview

color_echo 'Installing Solaar...'
add-apt-repository -y ppa:solaar-unifying/ppa
apt install -y solaar

color_echo 'Installing Charles Proxy...'
apt-key adv --keyserver pgp.mit.edu --recv-keys 1AD28806
sh -c 'echo deb https://www.charlesproxy.com/packages/apt/ charles-proxy main > /etc/apt/sources.list.d/charles.list'
apt update
apt install -y charles-proxy

color_echo 'Installing OpenConnect...'
apt install -y openconnect

color_echo 'Installing Microsoft Teams...'
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/ms-teams stable main" > /etc/apt/sources.list.d/teams.list'
apt update
apt install -y teams

color_echo 'Installing Snap...'
apt install -y snapd
snap install telegram-desktop
snap install code --classic
snap install android-studio --classic

