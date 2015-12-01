#Lab: Prepare to Deploy OpenShift
#####################################################################################
#####################################################################################
#####################################################################################
# THIS NEEDS TO RUN ON master HOST
#####################################################################################
#####################################################################################
#####################################################################################

hostname | grep master
if [ $? -ne 0 ]
then
echo "Not on Master, Quiting"
exit;
fi

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
echo Configure `/etc/ssh/ssh_conf` to disable `StrictHostKeyChecking` on the master host:

echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ssh root@oselab-$GUID.oslab.opentlc.com "bash /root/oselab.dns.installer.sh"

echo "=== Configure SSH Keys:"
##The OpenShift installer uses SSH to configure hosts.  In this lab we create and install an SSH key pair on the master host and add the public key to the `authorized_hosts` file.
#. SSH to the master host from the admin host and create an SSH key pair for the `root` user.

#rm -rf /root/.ssh/*
#ssh-keygen -f /root/.ssh/id_rsa -N ''
#/usr/bin/cp -f /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


#echo Copy the SSH key to the rest of the nodes in the environment
#echo "for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh-copy-id root@$node ; done"
#for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh-copy-id root@$node ; done

echo "=== Configure the Repositories on the Master Host"
echo " On the master host set up the yum repository configuration file /etc/yum.repos.d/open.repo"
cat << EOF > /etc/yum.repos.d/open.repo
[rhel-x86_64-server-7]
name=Red Hat Enterprise Linux 7
baseurl=http://www.opentlc.com/repos/rhel-7-server-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-extras-7]
name=Red Hat Enterprise Linux 7 Extras
baseurl=http://www.opentlc.com/repos/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-optional-7]
name=Red Hat Enterprise Linux 7 Optional
baseurl=http://www.opentlc.com/repos/rhel-7-server-optional-rpms
enabled=1
gpgcheck=0

# This repo is added for the OPENTLC environment not OSE
[rhel-x86_64-server-rh-common-7]
name=Red Hat Enterprise Linux 7 Common
baseurl=http://www.opentlc.com/repos/rhel-x86_64-server-rh-common-7
enabled=1
gpgcheck=0
EOF

#Add the OpenShift repository mirror to the master host:
cat << EOF >> /etc/yum.repos.d/open.repo
[rhel-7-server-ose-3.1-rpms]
name=Red Hat Enterprise Linux 7 OSE 3.1
baseurl=http://www.opentlc.com/repos/rhel-7-server-ose-3.1-rpms
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
yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv gcc bash-completion

echo "Run yum update on all the nodes"
ssh infranode00-$guid.oslab.opentlc.com "yum update -y > /dev/null" &
ssh node00-$guid.oslab.opentlc.com "yum update -y > /dev/null" &
ssh node01-$guid.oslab.opentlc.com "yum update -y > /dev/null" &

yum -y update

echo "=== Install Docker"

echo "Install the docker package on the master host"
yum -y install docker

echo "Do the same for the rest of the nodes"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y install docker"  ; done


echo "Configure the *Docker* registry on the *master*:"
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.16\/0'/" /etc/sysconfig/docker

echo "Do the same for the rest of the nodes"

for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do scp  /etc/sysconfig/docker $node:/etc/sysconfig/docker ; done

echo "=== Configure Docker Storage"

rm -rf /var/lib/docker/*
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF
docker-storage-setup

echo "Do the same for the rest of the nodes"

for node in infranode00-$guid.oslab.opentlc.com \
 node00-$guid.oslab.opentlc.com \
 node01-$guid.oslab.opentlc.com; \
 do
   echo Configuring Docker Storage and rebooting $node
   scp /etc/sysconfig/docker-storage-setup ${node}:/etc/sysconfig/docker-storage-setup
   ssh $node "
         docker-storage-setup ;
         systemctl enable docker;
         reboot"
 done

systemctl enable docker

#reboot
echo "Sleep 60 to wait for the nodes to come up"
sleep 120
echo "=== Populate local Docker registry"
for node in   master00-$guid.oslab.opentlc.com \
 infranode00-$guid.oslab.opentlc.com \
 node00-$guid.oslab.opentlc.com \
 node01-$guid.oslab.opentlc.com; \
 do
   echo Checking docker status on $node
   ssh $node "
         systemctl status docker | grep Active"
 done

REGISTRY="registry.access.redhat.com";PTH="openshift3"
for node in  node00-$guid.oslab.opentlc.com \
node01-$guid.oslab.opentlc.com; \
do
ssh $node "
docker pull $REGISTRY/$PTH/ose-deployer:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-sti-builder:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-sti-image-builder:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-docker-builder:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-pod:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-keepalived-ipfailover:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ruby-20-rhel7 ; \
docker pull $REGISTRY/$PTH/mysql-55-rhel7 ; \
docker pull openshift/hello-openshift:v1.0.6
"
done

REGISTRY="registry.access.redhat.com";PTH="openshift3"
ssh infranode00-$guid.oslab.opentlc.com "
docker pull $REGISTRY/$PTH/ose-haproxy-router:v3.1.0.4  ; \
docker pull $REGISTRY/$PTH/ose-deployer:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-pod:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-docker-registry:v3.1.0.4 ;"

echo "=== Download the Installer"
 yum -y install atomic-openshift-utils

cat << EOF >> /root/.config/openshift/installer.cfg.yml
 ansible_config: /usr/share/atomic-openshift-utils/ansible.cfg
 ansible_log_path: /tmp/ansible.log
 ansible_ssh_user: root
 hosts:
 - connect_to: master00-GUID.oslab.opentlc.com
   hostname: master00-GUID.oslab.opentlc.com
   ip: 192.168.0.100
   master: true
   node: true
   public_hostname: master00-GUID.oslab.opentlc.com
   public_ip: 192.168.0.100
 - connect_to: infranode00-GUID.oslab.opentlc.com
   hostname: infranode00-GUID.oslab.opentlc.com
   ip: 192.168.0.101
   node: true
   public_hostname: infranode00-GUID.oslab.opentlc.com
   public_ip: 192.168.0.101
 - connect_to: node00-GUID.oslab.opentlc.com
   hostname: node00-GUID.oslab.opentlc.com
   ip: 192.168.0.200
   node: true
   public_hostname: node00-GUID.oslab.opentlc.com
   public_ip: 192.168.0.200
 - connect_to: node01-GUID.oslab.opentlc.com
   hostname: node01-GUID.oslab.opentlc.com
   ip: 192.168.0.201
   node: true
   public_hostname: node01-GUID.oslab.opentlc.com
   public_ip: 192.168.0.201
 variant: openshift-enterprise
 variant_version: '3.1'
 version: v1
EOF

sed -i s/GUID/${GUID}/g /root/.config/openshift/installer.cfg.yml


echo "== Lab: OpenShift Configuration and Setup"

echo "=== Set Regions and Zones"

oc label node infranode00-$guid.oslab.opentlc.com region="infra" zone="infranodes"
oc label node node00-$guid.oslab.opentlc.com region="primary" zone="east"
oc label node node01-$guid.oslab.opentlc.com region="primary" zone="west"

oc get nodes

oadm manage-node master00-$guid.oslab.opentlc.com  --schedulable=false

echo "SKIPPING create a default NodeSelector in master-config"
#sed -i 's/defaultNodeSelector: ""/defaultNodeSelector: "region=primary"' /etc/openshift/master/master-config.yaml
#systemctl restart openshift-master


echo "Deploy the Registry"

oadm registry  --credentials=/etc/openshift/master/openshift-registry.kubeconfig  --images='registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.1' --selector='region=infra'

echo "Deploy the Router"
oadm router trainingrouter --stats-password='r3dh@t1!' --replicas=1 \
--config=/etc/openshift/master/admin.kubeconfig  \
--credentials='/etc/openshift/master/openshift-router.kubeconfig' \
--images='registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1' \
--selector='region=infra'


echo "SKIPPING, Already populatedPopulating OpenShift"

 #oc create -f /usr/share/openshift/examples/image-streams/image-streams-rhel7.json -n openshift
 #oc create -f /usr/share/openshift/examples/db-templates -n openshift
 #oc create -f /usr/share/openshift/examples/quickstart-templates -n openshift


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

#5.1. Export an NFS Volume for Persistent Storage
echo "Export an NFS Volume for Persistent Storage"

echo "As root on the master host ensure that nfs-utils is installed on the nodes:"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y install nfs-utils" ; done

ssh root@192.168.0.254 "
mkdir -p /var/export/registry-storage
chown -R nfsnobody:nfsnobody /var/export/registry-storage
chmod -R 700 /var/export/registry-storage
echo '/var/export/registry-storage *(rw,sync,all_squash)' >> /etc/exports
systemctl enable rpcbind nfs-server
systemctl restart rpcbind nfs-server nfs-lock nfs-idmap
systemctl stop firewalld
systemctl disable firewalld
"

echo "Allow NFS Access in SELinux Policy on all nodes"
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do setsebool -P virt_use_nfs=true ; done

echo "Create a Persistent Volume for the Registry"

cat << EOF > registry-volume.json
    {
      "apiVersion": "v1",
      "kind": "PersistentVolume",
      "metadata": {
        "name": "registry-storage"
      },
      "spec": {
        "capacity": {
            "storage": "15Gi"
            },
        "accessModes": [ "ReadWriteMany" ],
        "nfs": {
            "path": "/var/export/registry-storage",
            "server": "oselab-${GUID}.oslab.opentlc.com"
        }
      }
    }

EOF

echo "Create your registry-volume"
 oc create -f registry-volume.json
oc get pv


echo "Create a claim definition file to claim your volume"

 cat << EOF > registry-volume-claim.json
    {
      "apiVersion": "v1",
      "kind": "PersistentVolumeClaim",
      "metadata": {
        "name": "registry-claim"
      },
      "spec": {
        "accessModes": [ "ReadWriteMany" ],
        "resources": {
          "requests": {
            "storage": "15Gi"
          }
        }
      }
    }

EOF

 oc create -f registry-volume-claim.json
oc get pv
oc get pvc


echo "Attach the Persistent Volume to the Registry"
oc volume dc/docker-registry --add --overwrite -t persistentVolumeClaim \
--claim-name=registry-claim --name=registry-storage

#oc get dc docker-registry -o json > docker-registry.json
#sed -i  '/emptyDir/c\"persistentVolumeClaim": { "claimName": "registry-claim" }' docker-registry.json
#sed -i  's/"privileged": false/"privileged": true/g' docker-registry.json
#oc update -f docker-registry.json
