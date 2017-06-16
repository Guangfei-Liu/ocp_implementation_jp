#!/bin/bash
set -x          # show commands
set -e          # stop at errors
set -o pipefail # do not ignore error on pipe
set -u          # error when an empty var is used

# ensure root@bastion
hostname | grep bastion
[ "$(whoami)" == "root" ]

export guid=`hostname|cut -f2 -d-|cut -f1 -d.`
export GUID=$guid

echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

export OWN_REPO_PATH=https://admin.shared.example.opentlc.com/repos/ocp/3.5
cat << EOF > /etc/yum.repos.d/open.repo
[rhel-7-server-rpms]
name=Red Hat Enterprise Linux 7
baseurl=${OWN_REPO_PATH}/rhel-7-server-rpms
enabled=1
gpgcheck=0

[rhel-7-server-rh-common-rpms]
name=Red Hat Enterprise Linux 7 Common
baseurl=${OWN_REPO_PATH}/rhel-7-server-rh-common-rpms
enabled=1
gpgcheck=0

[rhel-7-server-extras-rpms]
name=Red Hat Enterprise Linux 7 Extras
baseurl=${OWN_REPO_PATH}/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0

[rhel-7-server-optional-rpms]
name=Red Hat Enterprise Linux 7 Optional
baseurl=${OWN_REPO_PATH}/rhel-7-server-optional-rpms
enabled=1
gpgcheck=0

[rhel-7-fast-datapath-rpms]
name=Red Hat Enterprise Linux 7 Fast Datapath
baseurl=${OWN_REPO_PATH}/rhel-7-fast-datapath-rpms
enabled=1
gpgcheck=0

[rhel-7-server-ose-3.5-rpms]
name=Red Hat Enterprise Linux 7 OSE 3.5
baseurl=${OWN_REPO_PATH}/rhel-7-server-ose-3.5-rpms
enabled=1
gpgcheck=0
EOF

yum clean all
yum repolist

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    scp /etc/yum.repos.d/open.repo ${node}:/etc/yum.repos.d/open.repo
    ssh ${node} yum clean all
    ssh ${node} yum repolist
done

bash $(dirname $0)/bastion.dns.installer.sh

host test.cloudapps-$GUID.oslab.opentlc.com 127.0.0.1

yum -y install ansible

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    ssh $node "yum -y install NetworkManager"
done

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion
ssh master1.example.com yum -y install bash-completion

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    echo Running yum update on $node
    ssh $node "yum -y update "
done

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    echo Installing docker on $node
    ssh $node "yum -y install docker"
done

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    echo Cleaning up Docker on $node
    ssh $node "systemctl stop docker ; rm -rf /var/lib/docker/*"
done

cat <<EOF > /tmp/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
        echo Configuring Docker Storage and rebooting $node
        scp /tmp/docker-storage-setup ${node}:/etc/sysconfig/docker-storage-setup
        ssh $node "docker-storage-setup
                   systemctl enable docker
                   systemctl start docker"
done

rm /tmp/docker-storage-setup

for node in master1.example.com \
            infranode1.example.com \
            node1.example.com \
            node2.example.com; do
    echo Checking docker status on $node
    ssh $node "systemctl status docker | grep Active"
done

REGISTRY="registry.access.redhat.com";PTH="openshift3"
OSE_VERSION=$(yum info atomic-openshift | grep Version | awk '{print $3}')
for node in node1.example.com \
            node2.example.com; do
        ssh $node "docker pull $REGISTRY/$PTH/ose-deployer:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ose-sti-builder:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ose-pod:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ose-keepalived-ipfailover:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ruby-20-rhel7 ; \
docker pull $REGISTRY/$PTH/mysql-55-rhel7 ; \
docker pull openshift/hello-openshift:v1.2.1"
done

node=infranode1.example.com
ssh $node "docker pull $REGISTRY/$PTH/ose-haproxy-router:v$OSE_VERSION  ; \
docker pull $REGISTRY/$PTH/ose-deployer:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ose-pod:v$OSE_VERSION ; \
docker pull $REGISTRY/$PTH/ose-docker-registry:v$OSE_VERSION"


yum -y install atomic-openshift-utils
# use short version
OSE_VERSION=3.5
cat << EOF > /etc/ansible/hosts
[OSEv3:children]
masters
nodes
nfs

[OSEv3:vars]
ansible_user=root

# enable ntp on masters to ensure proper failover
openshift_clock_enabled=true

deployment_type=openshift-enterprise
openshift_release=v$OSE_VERSION

openshift_master_cluster_method=native
openshift_master_cluster_hostname=master1.example.com
openshift_master_cluster_public_hostname=master1-${GUID}.oslab.opentlc.com

os_sdn_network_plugin_name='redhat/openshift-ovs-multitenant'

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]
#openshift_master_htpasswd_users={'andrew': '$apr1$cHkRDw5u$eU/ENgeCdo/ADmHF7SZhP/', 'marina': '$apr1$cHkRDw5u$eU/ENgeCdo/ADmHF7SZhP/'

# default project node selector
osm_default_node_selector='region=primary'
openshift_hosted_router_selector='region=infra'
openshift_hosted_router_replicas=1
#openshift_hosted_router_certificate={"certfile": "/path/to/router.crt", "keyfile": "/path/to/router.key", "cafile": "/path/to/router-ca.crt"}
openshift_hosted_registry_selector='region=infra'
openshift_hosted_registry_replicas=1

openshift_master_default_subdomain=cloudapps-${GUID}.oslab.opentlc.com

#openshift_use_dnsmasq=False
#openshift_node_dnsmasq_additional_config_file=/home/bob/ose-dnsmasq.conf

openshift_hosted_registry_storage_kind=nfs
openshift_hosted_registry_storage_access_modes=['ReadWriteMany']
openshift_hosted_registry_storage_host=bastion.example.com
openshift_hosted_registry_storage_nfs_directory=/exports
openshift_hosted_registry_storage_volume_name=registry
openshift_hosted_registry_storage_volume_size=5Gi

[nfs]
bastion.example.com

[masters]
master1.example.com openshift_hostname=master1.example.com openshift_public_hostname=master1-${GUID}.oslab.opentlc.com

[nodes]
master1.example.com openshift_hostname=master1.example.com openshift_public_hostname=master1-${GUID}.oslab.opentlc.com openshift_node_labels="{'region': 'infra'}"
infranode1.example.com openshift_hostname=infranode1.example.com openshift_public_hostname=infranode1-${GUID}.oslab.opentlc.com openshift_node_labels="{'region': 'infra', 'zone': 'infranodes'}"
node1.example.com openshift_hostname=node1.example.com openshift_public_hostname=node1-${GUID}.oslab.opentlc.com openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
node2.example.com openshift_hostname=node2.example.com openshift_public_hostname=node2-${GUID}.oslab.opentlc.com openshift_node_labels="{'region': 'primary', 'zone': 'west'}"
EOF

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml

ssh master1.example.com oc get nodes

ssh master1.example.com "useradd -p '$(openssl passwd -1 'r3dh4t1\!')' andrew"
ssh master1.example.com "useradd -p '$(openssl passwd -1 'r3dh4t1\!')' marina"

ssh master1.example.com "oc delete dc/router svc/router"
CA=/etc/origin/master
ssh master1.example.com "oadm ca create-server-cert --signer-cert=$CA/ca.crt \
     --signer-key=${CA}/ca.key --signer-serial=${CA}/ca.serial.txt \
     --hostnames='*.cloudapps-${guid}.oslab.opentlc.com' \
     --cert=cloudapps.crt --key=cloudapps.key"

ssh master1.example.com "cat cloudapps.crt cloudapps.key ${CA}/ca.crt > /etc/origin/master/cloudapps.router.pem"

ssh master1.example.com "oadm router trainingrouter --replicas=1 \
                --default-cert=${CA}/cloudapps.router.pem \
                --service-account=router --stats-password='r3dh@t1\!'"

# wait for trainingrouter
ssh master1.example.com oc rollout status --request-timeout=0 dc/trainingrouter

while ! ssh master1.example.com "oc get pods|grep trainingrouter"|awk '$2 == "1/1" && $3 == "Running" {print "OK"}'|grep OK; do
    sleep 2
done

# wait for docker registry
while ! ssh master1.example.com 'curl https://$(oc get service docker-registry --template "{{.spec.clusterIP}}:{{index .spec.ports 0 \"port\"}}/healthz")'; do
    sleep 5
done
echo "LAB 01 MODULE 03 FINISHED"
