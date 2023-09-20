# Update Packages
sudo apt update
sudo apt upgrade

# Install tools
sudo apt install vim

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
sudo echo "deb [signed-by=${REPO_KEY}] ${REPO_URL}/ /" > /etc/apt/sources.list.d/opsi.list
sudo curl -fsSL ${REPO_URL}/Release.key | gpg --dearmor | sudo tee ${REPO_KEY} > /dev/null

cd ~
mkdir opsi
cd opsi

# Install using the GUI (because but we could try with CLI)

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
