# Update Packages
sudo apt update
sudo apt upgrade

# Install tools
sudo apt install vim host pigz apt-transport-https software-properties-common curl gpg samba samba-common smbclient cifs-utils

sudo mkdir -p /usr/local/share/keyrings

# Update Hostname
sudo hostnamectl set-hostname opsi-server
hostname

# Update FQDN
echo "$(hostname -I) opsi.insa-cvl.fr opsi-server" | sudo tee -a /etc/hosts
hostname --fqdn

# Check
getent hosts $(hostname -f)

# Update locales
sudo locale-gen en_GB.UTF-8
sudo update-locale LANG=en_GB.UTF-8

# Update Opensuse Registry
REPO_URL=https://download.opensuse.org/repositories/home:/uibmz:/opsi:/4.2:/stable/xUbuntu_22.04
REPO_KEY=/usr/local/share/keyrings/opsi.gpg
sudo echo "deb [signed-by=${REPO_KEY}] ${REPO_URL}/ /" > sudo /etc/apt/sources.list.d/opsi.list
sudo curl -fsSL ${REPO_URL}/Release.key | gpg --dearmor | sudo tee ${REPO_KEY} > /dev/null

cd ~
mkdir opsi
cd opsi

# Install using the GUI (because but we could try with CLI)
wget https://download.uib.de/opsi4.2/stable/quickinstall/opsi-quick-install.zip
unzip opsi-quick-install.zip


# Backend
# Password is linux123
sudo opsi-setup --configure-mysql

sudo opsi-setup --init-current-config
sudo opsi-set-rights
sudo systemctl restart opsiconfd.service
sudo systemctl restart opsipxeconfd.service

# Samba
sudo opsi-setup --auto-configure-samba

sudo systemctl restart smbd.service
sudo systemctl restart nmbd.service

opsi-admin -d task setPcpatchPassword

# Users and Groups
useradd -m -s /bin/bash adminuser
passwd adminuser
smbpasswd -a adminuser

usermod -aG opsiadmin adminuser
# Check
getent group opsiadmin

sudo usermod -aG opsifileadmins adminuser
sudo getent group opsifileadmins

sudo opsi-setup --patch-sudoers-file
sudo opsi-set-rights .

# Install Opsi Package (and it could be long)
sudo opsi-package-updater -v install
# Update Opsi Package
# sudo opsi-package-updater -v update

# Install Opsi (maybe, we need to gain access to the repository)
sudo opsi-package-manager --install /var/lib/opsi/repository/*.opsi


wget https://download.uib.de/opsi4.2/boot-cd/opsi4.2.0-client-boot-cd_20230913.iso

sudo opsi-package-updater -v install opsi-winpe

wget https://download.uib.de/4.2/experimental/opsiconfd-addons/opsi-webgui_4.2.23.zip
