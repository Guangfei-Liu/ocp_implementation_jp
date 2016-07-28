#Lab: Prepare to Deploy OpenShift
#####################################################################################
#####################################################################################
#####################################################################################
# THIS NEEDS TO RUN ON master HOST
#####################################################################################
#####################################################################################
#####################################################################################
export HOST=oselab
export VERSION="3.1"
hostname | grep $HOST
if [ $? -ne 0 ]
then
echo "Not on $HOST, Quiting"
exit;
fi

export guid=`hostname|cut -f2 -d-|cut -f1 -d.`
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`

echo Configure `/etc/ssh/ssh_conf` to disable `StrictHostKeyChecking` on the master host:

echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ssh root@oselab-$GUID.oslab.opentlc.com "bash /root/oselab.dns.installer.sh"

echo "=== Configure the Repositories on the Master Host"
echo " On the master host set up the yum repository configuration file /etc/yum.repos.d/open.repo"
cat << EOF > /etc/yum.repos.d/open.repo
[rhel-x86_64-server-7]
name=Red Hat Enterprise Linux 7
baseurl=http://www.opentlc.com/repos/ose/${VERSION}/rhel-7-server-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-extras-7]
name=Red Hat Enterprise Linux 7 Extras
baseurl=http://www.opentlc.com/repos/ose/${VERSION}/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0

[rhel-x86_64-server-optional-7]
name=Red Hat Enterprise Linux 7 Optional
baseurl=http://www.opentlc.com/repos/ose/${VERSION}/rhel-7-server-optional-rpms
enabled=1
gpgcheck=0

# This repo is added for the OPENTLC environment not OSE
[rhel-x86_64-server-rh-common-7]
name=Red Hat Enterprise Linux 7 Common
baseurl=http://www.opentlc.com/repos/ose/${VERSION}/rhel-7-server-rh-common-rpms
enabled=1
gpgcheck=0
EOF


#Add the OpenShift repository mirror to the master host:
cat << EOF >> /etc/yum.repos.d/open.repo
[rhel-7-server-ose-${VERSION}-rpms]
name=Red Hat Enterprise Linux 7 OSE ${VERSION}
baseurl=http://www.opentlc.com/repos/ose/${VERSION}/rhel-7-server-ose-${VERSION}-rpms
enabled=1
gpgcheck=0
EOF

echo "List the available repositories on the $HOST host:"

yum repolist

#The Nodes require to be configures as well, for the sake of simplicity we will copy the repo file to all the nodes directly from the the master

for node in master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                      echo Copying open.repo to $node ; \
                                      scp /etc/yum.repos.d/open.repo ${node}:/etc/yum.repos.d/open.repo ;
                                      yum repolist
                                   done
echo "Remove NetworkManager:"
for node in   master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                    echo removing NetworkManager on $node ; \
                                      ssh $node "yum -y  remove NetworkManager*"
                                   done
echo "yum update all hosts"
for node in   master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                    echo removing NetworkManager on $node ; \
                                      ssh $node "yum update -y"
                                   done

echo Installing packages on master
ssh master1-$guid "yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv gcc  bash-completion"


echo "=== Install Docker"

echo "Install the docker package on the master host"
echo "Do the same for the rest of the nodes"
for node in   master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                    echo removing NetworkManager on $node ; \
                                      ssh $node "yum -y install docker"
                                   done

echo "Configure the *Docker* registry on the *master*:"
scp master1.example.com:/etc/sysconfig/docker /tmp
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /tmp/docker

echo "Do the same for the rest of the nodes"

for node in    master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                    echo Overwriting docker configuration file on $node ; \
                                    scp  /tmp/docker $node:/etc/sysconfig/docker ;
                                    done
echo "=== Configure Docker Storage"

cat <<EOF > /tmp/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF

echo "Do the same for the rest of the nodes"

for node in  master1.example.com \
                  infranode1.example.com \
                  node1.example.com \
                  node2.example.com; \
 do
   echo Configuring Docker Storage and rebooting $node
   scp /tmp/docker-storage-setup ${node}:/etc/sysconfig/docker-storage-setup
   ssh $node "
      rm -rf /var/lib/docker/*
       docker-storage-setup ;
       systemctl enable docker;
       reboot"
 done



#reboot
echo "Sleep 60 to wait for the nodes to come up"
sleep 120
echo "=== Populate local Docker registry"
for node in   master1.example.com \
 infranode1.example.com \
 node1.example.com \
 node2.example.com; \
 do
   echo Checking docker status on $node
   ssh $node "
         systemctl status docker | grep Active"
         lvs
 done

REGISTRY="registry.access.redhat.com";PTH="openshift3"
for node in  node1.example.com \
node2.example.com; \
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
ssh infranode1.example.com "
docker pull $REGISTRY/$PTH/ose-haproxy-router:v3.1.0.4  ; \
docker pull $REGISTRY/$PTH/ose-deployer:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-pod:v3.1.0.4 ; \
docker pull $REGISTRY/$PTH/ose-docker-registry:v3.1.0.4 ;"

echo "=== Download the Installer"

for node in   master1.example.com \
                                    infranode1.example.com \
                                    node1.example.com \
                                    node2.example.com; \
                                    do \
                                    echo removing NetworkManager on $node ; \

                                      ssh $node "
                                      yum clean all;
                                      yum update -y;
                                      "
                                   done

yum -y install atomic-openshift-utils

mkdir -p /root/.config/openshift
cat << EOF > /root/.config/openshift/installer.cfg.yml
 ansible_config: /usr/share/atomic-openshift-utils/ansible.cfg
 ansible_log_path: /tmp/ansible.log
 ansible_ssh_user: root
 hosts:
 - connect_to: master1.example.com
   hostname: master1.example.com
   ip: 192.168.0.101
   master: true
   node: true
   public_hostname: master1.example.com
   public_ip: 192.168.0.101
 - connect_to: infranode1.example.com
   hostname: infranode1.example.com
   ip: 192.168.0.251
   node: true
   public_hostname: infranode1.example.com
   public_ip: 192.168.0.251
 - connect_to: node1.example.com
   hostname: node1.example.com
   ip: 192.168.0.201
   node: true
   public_hostname: node1.example.com
   public_ip: 192.168.0.201
 - connect_to: node2.example.com
   hostname: node2.example.com
   ip: 192.168.0.202
   node: true
   public_hostname: node2.example.com
   public_ip: 192.168.0.202
 variant: openshift-enterprise
 variant_version: '3.1'
 version: v1
EOF

sed -i s/GUID/${GUID}/g /root/.config/openshift/installer.cfg.yml


atomic-openshift-installer -u install
echo "== Lab: OpenShift Configuration and Setup"

echo "=== Set Regions and Zones"

oc label node infranode1.example.com region="infra" zone="infranodes"
oc label node node1.example.com region="primary" zone="east"
oc label node node2.example.com region="primary" zone="west"

oc get nodes

oadm manage-node master1.example.com  --schedulable=false

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
for node in infranode1.example.com node1.example.com node2.example.com; do ssh $node "yum -y install nfs-utils" ; done

ssh root@192.168.0.3 "
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
for node in infranode1.example.com node1.example.com node2.example.com; do setsebool -P virt_use_nfs=true ; done

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
            "server": "oselab.example.com"
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
