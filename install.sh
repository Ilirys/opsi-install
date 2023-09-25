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
echo "deb [signed-by=${REPO_KEY}] ${REPO_URL}/ /" > /etc/apt/sources.list.d/opsi.list
curl -fsSL ${REPO_URL}/Release.key | gpg --dearmor | sudo tee ${REPO_KEY} > /dev/null

cd ~
mkdir opsi
cd opsi

# Install Opsi
wget https://download.uib.de/opsi4.2/stable/quickinstall/opsi-quick-install.zip
unzip opsi-quick-install.zip
sudo opsi-quickinstall/nogui/opsi_quick_install_project -n

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

sudo opsi-admin -d task setPcpatchPassword

# Users and Groups
useradd -m -s /bin/bash adminuser
passwd adminuser
smbpasswd -a adminuser

sudo usermod -aG opsiadmin adminuser
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

# Install Opsi (maybe, we need to gain access to the repository) in root
sudo opsi-package-manager --install /var/lib/opsi/repository/*.opsi


wget https://download.uib.de/opsi4.2/boot-cd/opsi4.2.0-client-boot-cd_20230913.iso

sudo opsi-package-updater -v install opsi-winpe

# Add add-on in Addons pannel in website
wget https://download.uib.de/4.2/experimental/opsiconfd-addons/opsi-webgui_4.2.23.zip

# Install a DHCP if none are present in the network
apt install isc-dhcp-server
opsi-setup --auto-configure-dhcpd
opsi-setup --patch-sudoers-file

# Add a DNS zone if none are present in the network
