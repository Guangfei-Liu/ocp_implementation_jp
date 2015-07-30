install
text
keyboard us
lang en_US.UTF-8
skipx
firstboot --disable
network --device eth0 --bootproto dhcp
rootpw %ROOTPW%
auth --enableshadow --passalgo=sha512
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr

zerombr
clearpart --all --initlabel
part /boot --fstype=xfs --size=512
part pv.01 --size=1 --grow
volgroup rhel pv.01
logvol / --vgname=rhel --name=root --size=1 --grow
logvol swap --vgname=rhel --name=swap --size=2048

reboot

%packages
@core

%end

%post
exec < /dev/tty3 > /dev/tty3
chvt 3
echo "Loading and executing image configuration script..."
(
curl -s http://www.opentlc.com/download/ose_implementation/Basic_Image_Setup.sh | bash -x
) 2>&1 | /usr/bin/tee /var/log/post_install.log
chvt 1
echo "Done"

%end
