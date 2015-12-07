#this is the basic Image Creation Script (ICS) for RHEL7 images
#1. sed out mac address and uuid from ifcfg-eth0.
#2. Root Password Change
#3. insert open.repo with the latest RHEL7 repos
#4. install cloud init, tools and yum update
#5. remove the repos so our students can add them.
#6. Add the open-init.sh file
#7. configure ssh-keygen and ssh-copy-id
#8. Add GUID to /etc/profile - this saves some work later
#9. General Template cleanup


#### Variables
export course="ose_implementation"
export version="3.1"

${version}
#1. sed out mac address and uuid from ifcfg-eth0
sed -i '/^HW/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
echo  DEVICE=eth0 >> /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network.service

#2. Root Password Change
echo 'root:r3dh4t1!' | chpasswd
sed -i 's/disable_root:.*1$/disable_root: 0/' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:.*0$/ssh_pwauth: 1/' /etc/cloud/cloud.cfg

#3. insert open.repo
cat << EOF > /etc/yum.repos.d/open.repo
[rhel-x86_64-server-7]
name=Red Hat Enterprise Linux 7
baseurl=http://www.opentlc.com/repos/ose/${version}/rhel-7-server-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-extras-7]
name=Red Hat Enterprise Linux 7 Extras
baseurl=http://www.opentlc.com/repos/ose/${version}/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-optional-7]
name=Red Hat Enterprise Linux 7 Optional
baseurl=http://www.opentlc.com/repos/ose/${version}/rhel-7-server-optional-rpms
enabled=1
gpgcheck=0

# This repo is added for the OPENTLC environment not OSE
[rhel-x86_64-server-rh-common-7]
name=Red Hat Enterprise Linux 7 Common
baseurl=http://www.opentlc.com/repos/ose/${version}/rhel-7-server-rh-common-rpms
enabled=1
gpgcheck=0

[rhel-7-server-ose-3.1-rpms]
name=Red Hat Enterprise Linux 7 OSE 3.1
baseurl=http://www.opentlc.com/repos/ose/${version}/rhel-7-server-ose-3.1-rpms
enabled=1
gpgcheck=0


EOF

sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf


#4. install cloud init, tools and yum update
yum clean all
yum install cloud-init curl -y
yum -y install deltarpm
yum -y install wget vim-enhanced net-tools bind-utils tmux git
yum update -y
yum clean all

#5. remove the repos so our students can add them.
#rm /etc/yum.repos.d/open.repo


#6. Add the open-init.sh file

echo curl --connect-timeout 120 -s http://www.opentlc.com/download/${course}/open-init.sh
curl --connect-timeout 120 -s http://www.opentlc.com/download/${course}/open-init.sh > /usr/local/bin/open-init.sh;
chmod +x  /usr/local/bin/open-init.sh

#7. configure ssh-keygen and ssh-copy-id
ssh-keygen -f /root/.ssh/id_rsa -N ''
/usr/bin/cp -f /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
rm -f .ssh/known_hosts

#8. Add GUID to /etc/profile - th --max-time=180is saves some work later
echo '
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`
export guid=`hostname|cut -f2 -d-|cut -f1 -d.`
' >> /etc/profile

#9. General Template cleanup
rm -f /etc/ssh/ssh_host_*
#echo > /etc/machine-id
echo localhost.localdomain > /etc/hostname
hostname localhost.localdomain
sed -i 's/timeout=5/timeout=1/' /etc/grub2.cfg
dracut --no-hostonly --force
/bin/rm -f ~root/anaconda-ks.cfg
/bin/rm -f ~root/.bash_history
unset HISTFILE
poweroff



### 1MASTER00
### master00-REPL.oslab.opentlc.com
### Add one 10GB Virtio Disk
### 8443,22
### 192.168.0.100
###
### 2INFRANODE
### infranode00-REPL.oslab.opentlc.com
### 80,443,1936 (Do I need ports 8443 and 8444 on infranode?)
### Add one 25GB Virtio Disk
### 192.168.0.101
###
### 3NODE00
### node00-REPL.oslab.opentlc.com
### No ports open to public network.
### Add one 25GB Virtio Disk
### 192.168.0.200
###
### 4NODE01
### node01-REPL.oslab.opentlc.com
### No ports open to public network.
### Add one 25GB Virtio Disk
### 192.168.0.201
###


### 0OSELAB
### oselab-REPL.oslab.opentlc.com
### 80,443
### 192.168.0.254
###
