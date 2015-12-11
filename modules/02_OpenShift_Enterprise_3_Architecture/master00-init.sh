###############################################################################
#### COMMON Tasks
#1.0 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo
#1.1 COMMON - Tools Install
#2.0 COMMON -  Docker Install

#### master 00 ONLY
#2.2 Ansible Configuration
#2.3 Run Ansible Installer
#2.4 Configure Web Console
#2.5 Deployment workaround, download post deployment script
###############################################################################
####
## Notes
## Maybe I need to remove all repos other than open.repo at the beginning

#vars
###############################################################################
export LOGFILE="/root/.master00.log"
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
#For your enjoyment feel free to follow /root/.master00.log ###################
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


###############################################################################
########################END Common Section ####################################
###############################################################################
####2.5 Deployment workaround, download post deployment script
curl -s  --retry 3 http://www.opentlc.com/download/ose_fastrax/Post_Deployment_Script.sh > /root/Post_Deployment_Script.sh
curl -s  --retry 3 http://www.opentlc.com/download/ose_fastrax/Demo_Deployment_Script.sh > /root/Demo_Deployment_Script.sh
#curl -s  http://www.opentlc.com/download/ose_fastrax/Lab01.Solution.sh > /root/.Lab01.Solution.sh
#curl -s  http://www.opentlc.com/download/ose_fastrax/Lab02.Solution.sh > /root/.Lab02.Solution.sh



# just a bit of cleanup
chmod +x ~/*.sh
mkdir /root/.Materials
mv  /root/\$HOME/ /root/openshift-ansible/ /root/training/ ~/.Materials



echo "XXXXCompleted Host Specific Script `date`"  | tee -a $LOGFILE



export DATE=`date`;
export TOOK=`uptime`;
cat << EOF > /etc/motd
###############################################################################
###############################################################################
###############################################################################
Basic Environment Deployment Is Completed : ${DATE}
POST CONFIGURATION IN PROGRESS
You should STILL WAIT before using this environment.
###############################################################################
# For your enjoyment feel free to follow:                                     #
# /root/.Post_Deployment_Script.rc.local.log                                  #
###############################################################################

EOF

echo '/root/Post_Deployment_Script.sh  &>> /root/.Post_Deployment_Script.rc.local.log &' >> /etc/rc.d/rc.local
#echo '/root/Post_Deployment_Script.sh 2>&1 >> /root/.Post_Deployment_Script1.log ' >> /etc/rc.local
chmod +x /etc/rc.d/rc.local


cat /etc/motd | tee -a $LOGFILE
echo this took aprox $TOOK | tee -a $LOGFILE

reboot
