#####################################################################################
#####################################################################################
#####################################################################################
# THIS NEEDS TO RUN ON master HOST
#####################################################################################
#####################################################################################
#####################################################################################

hostname | grep master 
if [ $? -eq 0 ]
then

#Verify that /etc/yum.repos.d/open.repo is set up with the following repositories (We are using local repositories in our lab environment)
#Red Hat Enterprise Linux 7
#Red Hat Enterprise Linux 7 Common
#Red Hat Enterprise Linux 7 Extras
#Red Hat Enterprise Linux 7 Optional 

cat << EOF > /etc/yum.repos.d/open.repo
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
#Add the OpenShift Beta3 Repository
#NOTE: We have the second repository to fix a Ravello specific issue that was not available during beta3.
cat << EOF >> /etc/yum.repos.d/open.repo
[ose3]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/ose3
enabled=1
gpgcheck=0

[ose3_fix]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/ose3_ravellofix
enabled=1
gpgcheck=0
EOF

 

#Check the Yum repositories 

yum repolist 
#Verify Network Configuration
yum -y remove NetworkManager*

#Install Docker on our host 
yum -y install docker ; 
systemctl enable docker

# Configure Docker Registry
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 0.0.0.0\/0'/" /etc/sysconfig/docker
systemctl restart docker

#In order to save time later, we will "pull" some docker images locally. (We already downloaded these locally to your host so it will go faster)
echo "Pulling  a bunch of Docker images, this might take a while" 
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
----

#Configure SSH Keys
ssh-keygen -f /root/.ssh/id_rsa -N '' 

#Add ssh key to *authorised_keys* of all the hosts in the environment (Currently only our Master host).
cp -f /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 
#ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub 127.0.0.1

----

#Configure */etc/ssh/ssh_conf* to disable *StrictHostKeyChecking*
echo StrictHostKeyChecking no >> /etc/ssh/ssh_config

#Install Ansible Installer 
#Add *epel* Repository, and disable it. 
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo   
#Install Ansible
yum -y --enablerepo=epel install ansible

#Configure and Install OpenShift Enterprise

#Download the Ansible "playbook"  
git clone https://github.com/detiber/openshift-ansible.git -b v3-beta3 

#Configure */etc/ansible/hosts* 
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`
cat << EOF >> /etc/ansible/hosts
[OSEv3:children]
masters
nodes
[OSEv3:vars]
deployment_type=enterprise
ansible_ssh_user=root

# host group for masters
[masters]
master00-$GUID.oslab.opentlc.com

# host group for nodes
[nodes]
master00-$GUID.oslab.opentlc.com

EOF

#Run Ansible Installer
ansible-playbook -vvv /root/openshift-ansible/playbooks/byo/config.yml
systemctl start openshift-master

#####################################################################################
######End of Master section 
#####################################################################################




#####################################################################################
#####################################################################################
#####################################################################################
# THIS NEEDS TO RUN ON oselab HOST
#####################################################################################
#####################################################################################
#####################################################################################

# Verify we are on the oselab host
hostname | grep oselab 
if [ $? -eq 0 ]
then
#Collect and define our environment's information.
guid=`hostname|cut -f2 -d-|cut -f1 -d.`
masterIP=`host master00-$guid.oslab.opentlc.com ipa.opentlc.com  | grep $guid | awk '{ print $4 }'`
domain="cloudapps-$guid.oslab.opentlc.com"

#Install bind on the oselab host
yum -y install bind bind-utils
systemctl enable named
systemctl stop named


#Create the zone file for our DNS server
mkdir /var/named/zones
echo "\$ORIGIN  .
\$TTL 1  ;  1 seconds (for testing only)
${domain} IN SOA master.${domain}.  root.${domain}.  (
  2011112904  ;  serial
  60  ;  refresh (1 minute)
  15  ;  retry (15 seconds)
  1800  ;  expire (30 minutes)
  10  ; minimum (10 seconds)
)
  NS master.${domain}.
\$ORIGIN ${domain}.
test A ${masterIP}
* A ${masterIP}"  >  /var/named/zones/${domain}.db
#Configure named.conf
echo "// named.conf
options {
  listen-on port 53 { any; };
  directory \"/var/named\";
  dump-file \"/var/named/data/cache_dump.db\";
  statistics-file \"/var/named/data/named_stats.txt\";
  memstatistics-file \"/var/named/data/named_mem_stats.txt\";
  allow-query { any; };
  recursion yes;
  /* Path to ISC DLV key */
  bindkeys-file \"/etc/named.iscdlv.key\";
};
logging {
  channel default_debug {
    file \"data/named.run\";
    severity dynamic;
  }; 
};
zone \"${domain}\" IN {
  type master;
  file \"zones/${domain}.db\";
  allow-update { key ${domain} ; } ;
};" > /etc/named.conf

#Correct file permissions and start our DNS server. 
chgrp named -R /var/named
chown named -R /var/named/zones
restorecon -R /var/named
chown root:named /etc/named.conf
restorecon /etc/named.conf
systemctl start named



#Verify DNS configuration 
dig @127.0.0.1 test.cloudapps-$guid.oslab.opentlc.com
if [ $? = 0 ]
then
  echo 'DNS Setup was successful'
else
  echo "DNS Setup failed"
fi

fi 

#####################################################################################
######End of oselab section 
#####################################################################################