
#version=DEVEL
install
cdrom
text
lang en_US.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp --noipv6
rootpw --plaintext vagrant
firewall --service=ssh
authconfig --enableshadow --passalgo=sha512
selinux --disabled
timezone --utc Europe/Rome
bootloader --location=mbr --driveorder=sda --append="crashkernel=auto rhgb quiet"

# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work

# Clean out the old disk config
zerombr

# Clean out old partitions
clearpart --all --drives=sda

# Make a new partition for the volgroup
part pv.008002 --size=39000 --ondisk=sda

# Make the volgroup
volgroup VolGroup --pesize=4096 pv.008002

# Make / on the volgroup
logvol / --fstype=ext4 --name=lv_root --vgname=VolGroup --grow --size=1024 --maxsize=37000

# Setup swap on the volgroup
logvol swap --name=lv_swap --vgname=VolGroup --grow --size=2016 --maxsize=2016

# Setup the boot partition on the volgroup
part /boot --fstype=ext4 --size=500

# Location of the package data
url --url http://mi.mirror.garr.it/mirrors/CentOS/6/os/x86_64/
repo --name=epel --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=x86_64
repo --name=updates --mirrorlist=http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=updates

%packages --nobase
	@core

	# For the virtualbox additions
	kernel-devel
	kernel-headers  
	make 
	dkms
	bzip2
	openssh-clients
	nano
	htop
	wget
	gcc
	perl
	sed
	yum-utils
%end

%post

	# Change to a vt to see progress

	exec < /dev/tty3 > /dev/tty3
	chvt 3

	# redirect output to ks-post.log including stdout and stderr
	(
		#######################################################
		# Turn off un-needed services
		#######################################################
		chkconfig sendmail off
		chkconfig vbox-add-x11 off
		chkconfig smartd off
		chkconfig ntpd off
		chkconfig cupsd off

		#######################################################
		# Setup for Vagrant
		#######################################################
		groupadd admin
		useradd -g admin vagrant
		echo 'Defaults env_keep="SSH_AUTH_SOCK"' >> /etc/sudoers
		echo '%admin    ALL=NOPASSWD: ALL' >> /etc/sudoers

		# Add vagrant insecure private key for key auth
		# Make your own if this is private.
		# See http://vagrantup.com/docs/base_boxes.html
		mkdir /home/vagrant/.ssh
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /home/vagrant/.ssh/authorized_keys

		########################################################
		# Cleanup for compression
		#######################################################
		# Remove ruby build libs
		yum -y remove zlib-devel openssl-devel readline-devel
		
		# Cleanup other files we do not need
		yum -y groupremove "Dialup Networking Support" Editors "Printing Support" "Additional Development" "E-mail server"

		# this is required to control the VM from vagrant
                sed -i.bak "s/^Defaults\s\+requiretty/Defaults     !requiretty/g" /etc/sudoers

		#######################################################
		# The system can now be packaged with 
		# `vagrant package VMNAME`
		#######################################################
		echo 'You can now package this box with `vagrant package VMNAME`'

	) 2>&1 | /usr/bin/tee /root/ks-post.log

	# switch back to gui
	chvt 7

%end

reboot
