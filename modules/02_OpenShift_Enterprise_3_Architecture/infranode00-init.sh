###############################################################################
#### COMMON Tasks
#1.0 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo
#1.1 COMMON - Tools Install
#2.0 COMMON -  Docker Install

#### InfraNode00 Only

#vars
###############################################################################
export LOGFILE="/root/.infranode00.log"
###############################################################################

echo "Hostname is `cat /etc/hostname`" >> $LOGFILE




export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################
###############################################################################
###############################################################################
Environment Deployment In Progress : ${DATE}
DO NOT USE THIS ENVIRONMENT AT THIS POINT
DISCONNECT AND TRY AGAIN 20 MINUTES FROM THE TIME ABOVE
Is this clear enough?
###############################################################################
###############################################################################
###############################################################################

EOF

####1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo
echo "----1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo" | tee -a $LOGFILE
echo "---- Adding OSE3 Repository to  /etc/yum.repos.d/open.repo" | tee -a $LOGFILE
# added the Repo to enable the Ravello Fix packages.
cat << EOF > /etc/yum.repos.d/open.repo
[rhel-x86_64-server-7]
name=Red Hat Enterprise Linux 7
baseurl=http://www.opentlc.com/repos/ose_fastrax/3.0/rhel-7-server-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-rh-common-7]
name=Red Hat Enterprise Linux 7 Common
baseurl=http://www.opentlc.com/repos/ose_fastrax/3.0/rhel-7-server-rh-common-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-extras-7]
name=Red Hat Enterprise Linux 7 Extras
baseurl=http://www.opentlc.com/repos/ose_fastrax/3.0/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-optional-7]
name=Red Hat Enterprise Linux 7 Optional
baseurl=http://www.opentlc.com/repos/ose_fastrax/3.0/rhel-7-server-optional-rpms
enabled=1
gpgcheck=0

[rhel-7-server-ose-3.0-rpms]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/ose_fastrax/3.0/rhel-7-server-ose-3.0-rpms
enabled=1
gpgcheck=0

EOF


#1.1 COMMON - Tools Install and misc
yum -y install wget git net-tools bind-utils iptables-services bridge-utils gcc  | tee -a $LOGFILE
yum remove NetworkManager*  | tee -a $LOGFILE
echo  DEVICE=eth0 >> /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network   | tee -a $LOGFILE
yum update -y  | tee -a $LOGFILE
echo StrictHostKeyChecking no >> /etc/ssh/ssh_config

#2.0 COMMON -  Docker Install

yum install -y docker  | tee -a $LOGFILE
rm -rf /var/lib/docker/*
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 0.0.0.0\/0'/" /etc/sysconfig/docker
pvcreate /dev/vdb | tee -a $LOGFILE
vgextend `vgs | grep rhel | awk '{print $1}'` /dev/vdb | tee -a $LOGFILE
docker-storage-setup | tee -a $LOGFILE
systemctl enable docker | tee -a $LOGFILE

#systemctl restart docker | tee -a $LOGFILE
sleep 5

#docker pull registry.access.redhat.com/openshift3/ose-pod:v3.0.0.0           		| tee -a $LOGFILE
#docker pull registry.access.redhat.com/openshift3/ose-sti-builder:v3.0.0.0   		| tee -a $LOGFILE
#docker pull registry.access.redhat.com/openshift3/ose-deployer:v3.0.0.0      		| tee -a $LOGFILE



###############################################################################
########################END Common Section ####################################
###############################################################################



#docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.0  	| tee -a $LOGFILE
#docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.0		| tee -a $LOGFILE




export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################
###############################################################################
###############################################################################
Environment Deployment Is Completed : ${DATE}
The environment is ready Post Deployment Script.
(If you already ran that, don't do it again)
###############################################################################
###############################################################################
###############################################################################

EOF


cat /etc/motd >> $LOGFILE
echo this took aprox $TOOK | tee -a $LOGFILE
reboot
