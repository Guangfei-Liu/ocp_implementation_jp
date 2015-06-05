#this is the basic Image Creation Script (ICS) for RHEL7 images 
#1. sed out mac address and uuid from ifcfg-eth0.
#2. insert open.repo with the latest RHEL7 repos 
#3. install cloud init  
#4. Root Password Change
#5. yum update to latest version 
#6. Add the open-init.sh file
#7. configure ssh-keygen and ssh-copy-id
#8. Docker set up
#9. General Template cleanup
 

#X. Create Snapshop - Do we want this? 
## Updates 28/4
# Changed The /etc/sysconfig docker sed line
# Changed the docker images pulled


#### Variables



#1. sed out mac address and uuid from ifcfg-eth0
sed -i '/^HW/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network.service


#2. insert open.repo
#### sborenst: I would prefer to curl/wget this file from www.opentlc.com/repos/open7.repo
#### Patrick, what do you think?
cat << EOF >> /etc/yum.repos.d/open.repo
[rhel-x86_64-server-7]
name=Red Hat Enterprise Linux 7
baseurl=http://www.opentlc.com/repos/rhel-x86_64-server-7
enabled=1
gpgcheck=0

[rhel-x86_64-server-rh-common-7]
name=Red Hat Enterprise Linux 7 Common
baseurl=http://www.opentlc.com/repos/rhel-x86_64-server-rh-common-7
enabled=1
gpgcheck=0

[rhel-x86_64-server-extras-7]
name=Red Hat Enterprise Linux 7 Extras
baseurl=http://www.opentlc.com/repos/rhel-x86_64-server-extras-7
enabled=1
gpgcheck=0

[rhel-x86_64-server-optional-7]
name=Red Hat Enterprise Linux 7 Optional
baseurl=http://www.opentlc.com/repos/rhel-x86_64-server-optional-7
enabled=1
gpgcheck=0
EOF

#2.1 we also change subscription management plugin off 
sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf



#3. install cloud init  
yum install cloud-init curl -y


#4. Root Password Change
echo 'root:r3dh4t1!' | chpasswd
# This is hashed out because it doesn't matter if we do it, it gets overrun by CF later.
#sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
#systemctl restart sshd 


sed -i 's/disable_root:.*1$/disable_root: 0/' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:.*0$/ssh_pwauth: 1/' /etc/cloud/cloud.cfg


#5. yum update to latest version 
yum clean all
yum update -y 
yum clean all

 

#6. Add the open-init.sh file
export course="ose_fastrax";
curl http://www.opentlc.com/download/${course}/${course}.open-init.sh > /usr/local/bin/open-init.sh
chmod +x  /usr/local/bin/open-init.sh

#7. configure ssh-keygen and ssh-copy-id

ssh-keygen -f /root/.ssh/id_rsa -N ''
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 
#ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub 127.0.0.1

rm -f .ssh/known_hosts


#8. Docker set up 

yum -y install deltarpm

yum -y remove NetworkManager*
# This is a fix that will eventually make it into the image, as its an issue for all RHEL7.x images
echo  DEVICE=eth0 >> /etc/sysconfig/network-scripts/ifcfg-eth0 

### Tool install 
yum -y install wget vim-enhanced net-tools bind-utils tmux git


### Docker Install

cat << EOF >> /etc/yum.repos.d/open.repo
[ose3]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/ose3
enabled=1
gpgcheck=0
EOF
#Make sure that you are running at least docker-1.6.0-6.el7.x86_64.
yum -y install docker ; systemctl enable docker

### Update all packages 
yum clean all;yum -y update
 
### Configure Docker's Registry settings. 
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 0.0.0.0\/0'/" /etc/sysconfig/docker
systemctl restart docker
  
### Download All the images needed for training
### For fastrax, we might need less images - but for now it all stays 
docker pull registry.access.redhat.com/openshift3_beta/ose-haproxy-router:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/ose-deployer:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/ose-sti-builder:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/ose-docker-builder:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/ose-pod:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/ose-docker-registry:v0.4.3.2
docker pull registry.access.redhat.com/openshift3_beta/sti-basicauthurl:latest

docker pull registry.access.redhat.com/openshift3_beta/ruby-20-rhel7
docker pull registry.access.redhat.com/openshift3_beta/mysql-55-rhel7
docker pull openshift/hello-openshift

systemctl restart docker

############ POWER OFF

#9. General Template cleanup
rm -f /etc/ssh/ssh_host_*

#echo > /etc/machine-id
echo localhost.localdomain > /etc/hostname
hostname localhost.localdomain
# /etc/sysconfig/rhn/systemid

sed -i 's/timeout=5/timeout=1/' /etc/grub2.cfg

dracut --no-hostonly --force


#/bin/rm -rf ~root/.ssh/
/bin/rm -f ~root/anaconda-ks.cfg
#cp ~root/.bash_history ~root/.config_history
/bin/rm -f ~root/.bash_history
unset HISTFILE
poweroff



### 1MASTER00
### master00-REPL.oslab.opentlc.com
### 80,443,8443,8444,
### 192.168.0.100
###
### 2MASTER01
### master01-REPL.oslab.opentlc.com
### 80,443,8443,8444
### 192.168.0.101
###
### 3NODE00
### node00-REPL.oslab.opentlc.com	
### 80,443
### 192.168.0.200
###
### 4NODE01
### node01-REPL.oslab.opentlc.com	
### 80,443
### 192.168.0.201
###


### 0OSELAB
### oselab-REPL.oslab.opentlc.com	
### 80,443
### 192.168.0.254
###
