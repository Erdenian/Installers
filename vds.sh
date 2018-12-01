#!/bin/bash
set -o errexit

if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root' 1>&2
   exit 1
fi

HOST=https://raw.githubusercontent.com/Erdenian/Installers/master/vds
POSTGRESQL_VERSION=11
PYTHON_VERSION=3.6
PGADMIN_LINK=https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v3.6/pip/pgadmin4-3.6-py2.py3-none-any.whl

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
apt install -y openjdk-8-jdk openjfx wget fail2ban
apt install -y software-properties-common # contains add-apt-repository
apt install -y ca-certificates # for postgresql apt
apt install -y sed # for postgresql setup

color_echo 'Adding repositories...'
# jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo 'deb http://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
# postgresql
wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# git
add-apt-repository -y ppa:git-core/ppa
# openjdk
add-apt-repository -y ppa:openjdk-r/ppa

color_echo 'Installing OpenJDK...
apt install -y openjdk-11-jdk openjfx
apt install -y openjdk-8-jdk # Jenkins doesn's support Java 11, 8 will be set as default

color_echo 'Installing Git...'
apt install -y git

color_echo 'Installing Jenkins...'
apt install -y jenkins
download_from_host jenkins /etc/default/
/etc/init.d/jenkins restart

color_echo 'Installing PostgreSQL...'
apt install -y postgresql
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'\t/g" /etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf
cat <<EOT >> /etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf
# Allow all connections
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
EOT
/etc/init.d/postgresql restart

color_echo 'Installing pgAdmin4...'
apt install -y python3-dev python3-venv python3-pip libpq-dev
rm -rf /opt/pgadmin4
python$PYTHON_VERSION -m venv /opt/pgadmin4
cd /opt/pgadmin4/
source bin/activate
pip3 install wheel flask
wget $PGADMIN_LINK
pip3 install pgadmin4*.whl
deactivate
cd -
download_from_host config_local.py /opt/pgadmin4/lib/python$PYTHON_VERSION/site-packages/pgadmin4/
download_from_host pgadmin4.service /etc/systemd/system/
adduser pgadmin --disabled-password --gecos '' || True
chown -R pgadmin /opt/pgadmin4

color_echo 'Installing Apache...'
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
setup_site jenkins
setup_site pgadmin
apache2ctl restart

color_echo 'Post installation interaction...'
color_echo 'Enter new posrgres user password'
sudo -u postgres psql --command '\password' || color_echo 'Set correct password later'

color_echo 'initialAdminPassword for Jenkins:'
cat /var/lib/jenkins/secrets/initialAdminPassword

adduser erdenian
adduser erdenian sudo
cat <<EOT >> /etc/ssh/sshd_config
DenyUsers root
PermitEmptyPasswords no
EOT

color_echo 'pgAdmin4 initial setup...'
color_echo "Cancel execution after email and password setup and run 'systemctl enable pgadmin4'"
sudo -u pgadmin -s -- <<EOF
PATH=/opt/pgadmin4/bin
/opt/pgadmin4/bin/python3 /opt/pgadmin4/lib/python$PYTHON_VERSION/site-packages/pgadmin4/pgAdmin4.py
EOF
