#Lab: Prepare to Deploy OpenShift
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
export guid=`hostname|cut -f2 -d-|cut -f1 -d.`
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`

#In this lab we will Deploy OpenShift Enterprise on a single host (in later labs we will add more nodes).
##* Configure a DNS on our *oselab* server to serve our OpenShift environment.
##* Configure SSH Keys
##* Configure Repositories
##* Configure Network Settings
##* Install Docker on our host
##* Configure and Install OpenShift Enterprise
##* Test deployment.

##=== Lab Environment Architecture and Important Information

##The lab environment consists of 4 VMs:

##* `oselab-GUID.oslab.opentlc.com` (administration host)

##* `master00-GUID.oslab.opentlc.com` (master host, contains Etcd and the management console)

##* `infranode00-GUID.oslab.opentlc.com` (infranode host, Will run our infrastructure containers: Registry and Router)

##* `node00-GUID.oslab.opentlc.com` (node host, Region: Primary, Zone: East. )

##* `node01-GUID.oslab.opentlc.com` (node host, Region: Primary, Zone: West. )

##As a reminder you will only be allowed to SSH to the administration host from the outside of the lab environment, all other hosts have external SSH blocked.  Once on the administration host, you can SSH to the other hosts internally.  As described earlier, you will have to use your private SSH key and OPENTLC login to access the system (not root!).
##Each student lab is assigned a global unique identifier (GUID) that consists of 4 characters.  This GUID is provided to you in the provisioning email that will be sent to you when you provision your lab environment.  *Anywhere you see GUID from this point on, you will replace it with your lab's GUID.*



#=== Configure Wildcard DNS to Service the OpenShift Environment.

#OpenShift requires a wildcard DNS A record.  The wildcard A record should point to the publicly available (external) IP address of the OpenShift router.  For this training, we will ensure that the router will end up on the OpenShift server that is running the master.  It is advisable to use a low TTL for this record in order for DNS client caches to expire quicker so that changes become available quicker.  The DNS server runs on the administration host.

#. Connect to your administration host `oselab-GUID.oslab.opentlc.com` (your private key location may vary):

#
ssh root@oselab-$GUID.oslab.opentlc.com "bash /root/oselab.dns.installer.sh"

echo "=== Configure SSH Keys:"
##The OpenShift installer uses SSH to configure hosts.  In this lab we create and install an SSH key pair on the master host and add the public key to the `authorized_hosts` file.
#. SSH to the master host from the admin host and create an SSH key pair for the `root` user.
rm -rf /root/.ssh/*
ssh-keygen -f /root/.ssh/id_rsa -N ''
/usr/bin/cp -f /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

echo Configure `/etc/ssh/ssh_conf` to disable `StrictHostKeyChecking` on the master host:
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

echo Copy the SSH key to the rest of the nodes in the environment
echo "for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh-copy-id root@$node ; done"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh-copy-id root@$node ; done

echo "=== Configure the Repositories on the Master Host"
echo " On the master host set up the yum repository configuration file /etc/yum.repos.d/open.repo"
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

#Add the OpenShift repository mirror to the master host:
cat << EOF >> /etc/yum.repos.d/open.repo
[rhel-7-server-ose-3.0-rpms]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/rhel-7-server-ose-3.0-rpms
enabled=1
gpgcheck=0

EOF

echo "List the available repositories on the master host:"

yum repolist

#The Nodes require to be configures as well, for the sake of simplicity we will copy the repo file to all the nodes directly from the the master
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do scp /etc/yum.repos.d/open.repo ${node}:/etc/yum.repos.d/open.repo ; done

echo "Remove NetworkManager:"
yum -y remove NetworkManager*
echo "Do the same for the rest of the nodes"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y  remove NetworkManager*"  ; done
echo "Install Misc tools and utilities on the master"
yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv gcc


echo "=== Install Docker"

echo "Install the docker package on the master host"
yum -y install docker

echo "Do the same for the rest of the nodes"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y install docker"  ; done


echo "Configure the *Docker* registry on the *master*:"
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/0'/" /etc/sysconfig/docker

echo "Do the same for the rest of the nodes"

for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do scp  /etc/sysconfig/docker $node:/etc/sysconfig/docker ; done

echo "=== Configure Docker Storage"

rm -rf /var/lib/docker/*

echo "Do the same for the rest of the nodes"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "rm -rf /var/lib/docker/*"  ; done
pvcreate /dev/vdb
vgextend `vgs | grep rhel | awk '{print $1}'` /dev/vdb
docker-storage-setup

echo "Do the same for the rest of the nodes"

for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com
do
  ssh $node "pvcreate /dev/vdb ; vgextend `vgs | grep rhel | awk '{print $1}'` /dev/vdb; docker-storage-setup ; "
  ssh $node "systemctl enable docker; reboot "
done


systemctl enable docker

#reboot
echo "Sleep 60 to wait for the nodes to come up"
sleep 60
echo "=== Populate local Docker registry"


for node in node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com
do
ssh $node "docker pull registry.access.redhat.com/openshift3/ose-deployer:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-sti-builder:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-sti-image-builder:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-docker-builder:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-pod:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-keepalived-ipfailover:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ruby-20-rhel7 ; \
docker pull registry.access.redhat.com/openshift3/mysql-55-rhel7 ; \
docker pull openshift/hello-openshift:v0.4.3"

done


echo On the *Infranode00*, Installer pull the *Registry* and *Router* images.
ssh infranode00-$guid.oslab.opentlc.com "docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-deployer:v3.0.0.1 ; \
docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.1 ;"

echo "=== Download the Installer"
curl -o oo-install-ose.tgz http://www.opentlc.com/download/ose_implementation/oo-install-ose.tgz

tar -zxf oo-install-ose.tgz

for node in master00-$guid.oslab.opentlc.com infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do echo $node ; done

mkdir -p  .config/openshift/
mkdir -p /tmp/oo-install-ose-20150710-0833/lib/python2.7/site-packages/ooinstall/

cat << EOF >> .config/openshift/installer.cfg.yml
Description: This is the configuration file for the OpenShift Ansible-Based Installer.
Name: OpenShift Ansible-Based Installer Configuration
Subscription: {type: none}
Vendor: OpenShift Community
Version: 0.0.1
ansible_config: /tmp/oo-install-ose-20150710-0833/lib/python2.7/site-packages/ooinstall/ansible.cfg
ansible_inventory_directory: /root/.config/openshift/.ansible
ansible_log_path: /tmp/oo-install-ose-20150710-0833.log
ansible_plugins_directory: /tmp/oo-install-ose-20150710-0833/lib/python2.7/site-packages/ooinstall/ansible_plugins
ansible_ssh_user: root
masters: [master00-${guid}.oslab.opentlc.com]
nodes: [master00-${guid}.oslab.opentlc.com, infranode00-${guid}.oslab.opentlc.com, node00-${guid}.oslab.opentlc.com,
  node01-${guid}.oslab.opentlc.com]
validated_facts:
  infranode00-${guid}.oslab.opentlc.com: {hostname: infranode00-${guid}.oslab.opentlc.com,
    ip: 192.168.0.101, public_hostname: infranode00-${guid}.oslab.opentlc.com, public_ip: 192.168.0.101}
  master00-${guid}.oslab.opentlc.com: {hostname: master00-${guid}.oslab.opentlc.com, ip: 192.168.0.100,
    public_hostname: master00-${guid}.oslab.opentlc.com, public_ip: 192.168.0.100}
  node00-${guid}.oslab.opentlc.com: {hostname: node00-${guid}.oslab.opentlc.com, ip: 192.168.0.200,
    public_hostname: node00-${guid}.oslab.opentlc.com, public_ip: 192.168.0.200}
  node01-${guid}.oslab.opentlc.com: {hostname: node01-${guid}.oslab.opentlc.com, ip: 192.168.0.201,
    public_hostname: node01-${guid}.oslab.opentlc.com, public_ip: 192.168.0.201}

EOF

echo "########################################################################"
echo "########################################################################"
echo "########################################################################"
echo "We will now start the installer, make sure you answer 'y' when the installer asks you to."
echo "#You will see:
Preparing to install.  This can take a minute or two..."
echo "#Question 1, Answer 'y':
Are you ready to continue?  y/Y to confirm, or n/N to abort [n]: y"
echo "#Question 2, Answer 'root' or press enter:
User for ssh access [root]:"
echo "#Question 3, Answer 'y':
Proceed? y/Y to confirm, or n/N to exit [y]: y"
echo "The installer takes a minute or so to start, dont press any key (other than 'y') after it starts otherwise it will abort"
echo "Now, to continue and start the installer, press any key (but just once)"
echo "This should be clear, right?"
echo "########################################################################"
echo "########################################################################"
echo "########################################################################"
read x;

./oo-install-ose

echo "Add the Default route to the OpenShift master configuration file"


echo "configuration:
  subdomain: cloudapps-$GUID.oslab.opentlc.com" >> /etc/openshift/master/master-config.yaml


echo "== Lab: OpenShift Configuration and Setup"

echo "=== Set Regions and Zones"

oc label node infranode00-$guid.oslab.opentlc.com region="infra" zone="infranodes"
oc label node node00-$guid.oslab.opentlc.com region="primary" zone="east"
oc label node node01-$guid.oslab.opentlc.com region="primary" zone="west"

oc get nodes

oadm manage-node master00-$guid.oslab.opentlc.com  --schedulable=false

echo "Deploy the Registry"


oadm registry  --credentials=/etc/openshift/master/openshift-registry.kubeconfig  --images='registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.1' --selector='region=infra'

echo "Deploy the Router"
oadm router trainingrouter --stats-password='r3dh@t1!' --replicas=1 \
--config=/etc/openshift/master/admin.kubeconfig  \
--credentials='/etc/openshift/master/openshift-router.kubeconfig' \
--images='registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1' \
--selector='region=infra'


echo "=== Populating OpenShift"

 oc create -f /usr/share/openshift/examples/image-streams/image-streams-rhel7.json -n openshift
 oc create -f /usr/share/openshift/examples/db-templates -n openshift
 oc create -f /usr/share/openshift/examples/quickstart-templates -n openshift


echo "== Lab: Configure Authentication"

echo "Create a copy of your master's config file"
cp /etc/openshift/master/master-config.yaml /etc/openshift/master/master-config.yaml.original

sed -i 's/name: deny_all/name: htpasswd_auth/g' /etc/openshift/master/master-config.yaml
sed -i 's/kind: DenyAllPasswordIdentityProvider$/kind: HTPasswdPasswordIdentityProvider/g' /etc/openshift/master/master-config.yaml
sed -i '/HTPasswdPasswordIdentityProvide/a \
      file: /etc/openshift/openshift-passwd \
'  /etc/openshift/master/master-config.yaml

echo "On the master host add two Linux accounts:"
useradd andrew
useradd marina

echo "Configuring htpasswd Authentication"
yum -y install httpd-tools
echo "Create a password for our users, Joe and Alice on the master host:"

touch /etc/openshift/openshift-passwd
htpasswd -b /etc/openshift/openshift-passwd andrew r3dh4t1!
htpasswd -b /etc/openshift/openshift-passwd marina r3dh4t1!

echo "Restart openshift-master for changes to take effect"
systemctl restart openshift-master
systemctl status openshift-master

fi
