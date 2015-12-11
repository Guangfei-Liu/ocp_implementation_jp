###############################################################################
export LOGFILE="/root/.Post_Deployment_Script.log"
###############################################################################
touch .Post.Started
# clean up Post deployment from /etc/rc.local
sed -i '/Post_Deployment/d' /etc/rc.d/rc.local


sleep 60
####2.2 Ansible Configuration

echo "XXXX2.2 Ansible Configuration"  | tee -a $LOGFILE

# Install Ansible on the Master workaround
echo "XXXXInstall Ansible on the Master workaround"  | tee -a $LOGFILE

yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm   | tee -a $LOGFILE
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible

# Clone Ansible git repo
#echo "XXXXClone Ansible git repo: git clone https://github.com/openshift/openshift-ansible /root/openshift-ansible "  | tee -a $LOGFILE
#git clone https://github.com/openshift/openshift-ansible /root/openshift-ansible | tee -a $LOGFILE
#cd /root/openshift-ansible
#git checkout -b 3.x v3.0.0

curl --retry 3 --connect-timeout 120 -s http://www.opentlc.com/download/${course}/openshift-ansible.tar.gz -o /root/openshift-ansible.tar.gz
tar xzvf /root/openshift-ansible.tar.gz -C /root

# Set hosts for Ansible to install
echo "XXXXSetting /etc/ansible/hosts for install "  | tee -a $LOGFILE
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`

cat << EOF >  /etc/ansible/hosts
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_sudo must be set to true
#ansible_sudo=true

#### Stuff sborenst added from default install
deployment_type=enterprise
ServerAliveCountMax=180
ServerAliveInterval=80

# enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]

# host group for masters
[masters]
master00-$GUID.oslab.opentlc.com

# host group for nodes, includes region info
[nodes]
master00-$GUID.oslab.opentlc.com
infranode00-$GUID.oslab.opentlc.com openshift_node_labels="{'region': 'infra', 'zone': 'infranode'}"
node00-$GUID.oslab.opentlc.com openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
node01-$GUID.oslab.opentlc.com openshift_node_labels="{'region': 'primary', 'zone': 'west'}"

EOF

echo /etc/ansible/hosts looks like this:  | tee -a $LOGFILE
cat /etc/ansible/hosts  | tee -a $LOGFILE

####2.3 Run Ansible Installer
echo "XXXX2.3 Run Ansible Installer "  | tee -a $LOGFILE
echo "XXXXansible-playbook playbooks/byo/config.yml"  | tee -a $LOGFILE

until [ -e /root/openshift-ansible/playbooks/byo/config.yml ]; do
echo "Fetching git repo - AGAIN " | tee -a $LOGFILE
#git clone https://github.com/openshift/openshift-ansible /root/openshift-ansible | tee -a $LOGFILE
#cd /root/openshift-ansible
#git checkout -b 3.x v3.0.0
export course=ose_fastrax
curl --retry 3 --connect-timeout 120 -s http://www.opentlc.com/download/${course}/openshift-ansible.tar.gz -o /root/openshift-ansible.tar.gz
tar xzvf /root/openshift-ansible.tar.gz -C /root

done

ansible-playbook /root/openshift-ansible/playbooks/byo/config.yml| tee -a $LOGFILE.ansible

systemctl enable openshift-master  | tee -a $LOGFILE
systemctl restart openshift-master | tee -a $LOGFILE

echo "Sleep 60 - waiting for openshift-master to load." | tee -a $LOGFILE
sleep 60
echo "---label the nodes" | tee -a $LOGFILE
oc login -u system:admin  -n default --server="https://master00-$GUID.oslab.opentlc.com:8443" --insecure-skip-tls-verify

oc label node infranode00-$GUID.oslab.opentlc.com region="infra" zone="infranodes"  --config=/etc/openshift/master/openshift-master.kubeconfig | tee -a $LOGFILE
oc label node node00-$GUID.oslab.opentlc.com region="primary" zone="east" --config=/etc/openshift/master/openshift-master.kubeconfig | tee -a $LOGFILE
oc label node node01-$GUID.oslab.opentlc.com region="primary" zone="west" --config=/etc/openshift/master/openshift-master.kubeconfig | tee -a $LOGFILE


echo "first run of oc label"  | tee -a $LOGFILE
oc get nodes --config=/etc/openshift/master/openshift-master.kubeconfig | tee -a $LOGFILE

systemctl restart openshift-master | tee -a $LOGFILE
echo "Sleep 30 - waiting for openshift-master to load." | tee -a $LOGFILE
sleep 30

echo "---Configure Registry for environment"
echo "Pulling ose-docker-registry:v3.0.0.0 and ose-haproxy-router:v3.0.0.1 to infranode00"
ssh infranode00-$GUID.oslab.opentlc.com 'docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.1'
ssh infranode00-$GUID.oslab.opentlc.com 'docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.2.0'
ssh infranode00-$GUID.oslab.opentlc.com 'docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1'
ssh node00-$GUID.oslab.opentlc.com "docker pull openshift/hello-openshift:v0.4.3; docker pull registry.access.redhat.com/openshift3/ruby-20-rhel7; docker pull registry.access.redhat.com/openshift3/nodejs-010-rhel7;"&>> .node00.Pull.Log &
ssh node01-$GUID.oslab.opentlc.com "docker pull openshift/hello-openshift:v0.4.3; docker pull registry.access.redhat.com/openshift3/ruby-20-rhel7; docker pull registry.access.redhat.com/openshift3/nodejs-010-rhel7;"&>> .node01.Pull.Log &


# All this can be removed

# This should already be added anyway. might produce errors
echo "Please ignore erros of priviously imported resources" | tee -a $LOGFILE
oc create -f /usr/share/openshift/examples/image-streams/image-streams-rhel7.json --config=/etc/openshift/master/openshift-master.kubeconfig -n openshift
oc create -f /usr/share/openshift/examples/db-templates/ --config=/etc/openshift/master/openshift-master.kubeconfig  -n openshift
oc create -f /usr/share/openshift/examples/quickstart-templates/ --config=/etc/openshift/master/openshift-master.kubeconfig -n openshift
oc create -f /usr/share/openshift/examples/xpaas-templates/ --config=/etc/openshift/master/openshift-master.kubeconfig -n openshift

# Always disabled
#oc create -f /usr/share/openshift/examples/xpaas-templates/ --config=/etc/openshift/master/openshift-master.kubeconfig -n instantapps
#oc create -f /usr/share/openshift/examples/xpaas-streams/jboss-image-streams.json --config=/etc/openshift/master/openshift-master.kubeconfig -n openshift
#oc create -f /usr/share/openshift/examples/quickstart-templates/ --config=/etc/openshift/master/openshift-master.kubeconfig -n instantapps


# Fix routing to point to : cloudapps-$GUID.oslab.opentlc.com
echo " Fix routing to point to : cloudapps-$GUID.oslab.opentlc.com" | tee -a $LOGFILE
echo "routingConfig:
  subdomain: cloudapps-$GUID.oslab.opentlc.com" >> /etc/openshift/master/master-config.yaml
## make the master unschedulable

# This should be done by the ansible script, but at the time of writing this it didn't.
echo "make the master unschedulable" | tee -a $LOGFILE
	echo "oadm manage-node master00-$GUID.oslab.opentlc.com  --schedulable=false --config=/etc/openshift/master/openshift-master.kubeconfig | tee -a $LOGFILE"
	oadm manage-node master00-$GUID.oslab.opentlc.com  --schedulable=false --config=/etc/openshift/master/openshift-master.kubeconfig  | tee -a $LOGFILE

echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}'  | oc create -n default -f -
oc get  scc privileged -o yaml > updated_scc_privileged.yaml
echo '- system:serviceaccount:default:registry' >>  updated_scc_privileged.yaml
oc create -f  updated_scc_privileged.yaml

echo "XXXX oadm registry --config=/etc/openshift/master/admin.kubeconfig   --credentials=/etc/openshift/master/openshift-registry.kubeconfig  --images='registry.access.redhat.com/openshift3/ose-${component}:v3.0.2.0' --selector='region=infra' " | tee -a $LOGFILE
oadm registry --config=/etc/openshift/master/admin.kubeconfig   --credentials=/etc/openshift/master/openshift-registry.kubeconfig  --images='registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.2.0' --selector='region=infra' --service-account='registry'

sleep 5


echo "----Creating router for environment"
echo "XXXX oadm router trainingrouter --stats-password='r3dh@t1!' --replicas=1     --credentials='/etc/openshift/master/openshift-master.kubeconfig'     --images='registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1'  --selector='region=infra'"
oadm router trainingrouter --stats-password='r3dh@t1!' --replicas=1  --config=/etc/openshift/master/admin.kubeconfig  --credentials='/etc/openshift/master/openshift-router.kubeconfig'     --images='registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1'  --selector='region=infra' --server="https://master00-$GUID.oslab.opentlc.com:8443"

cat << EOF > /root/Create_Users_And_Projects.sh

sed -i '/Create_Users_And_Projects/d' /etc/rc.d/rc.local



####3.0 User and project Creation
echo "----User and project Creation"
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`
####3.1 user Management
export USER1=andrew
export USER2=marina
echo "----user Management - Creating andrew and marina"
useradd \${USER1}
useradd \${USER2}
echo "----user Management - Adding them to /etc/openshift/openshift-passwd"
htpasswd -b /etc/openshift/openshift-passwd \${USER1} r3dh4t1!
htpasswd -b /etc/openshift/openshift-passwd \${USER2} r3dh4t1!

echo "----user Management - Creating Projects"
oadm new-project hello-openshift --display-name="Hello Openshift Lab Project" --node-selector='region=primary' --admin="\${USER1}" --server="https://master00-\$GUID.oslab.opentlc.com:8443"
oadm new-project hello-s2i --display-name="S2I Lab Project" --node-selector='region=primary' --admin="\${USER1}" --server="https://master00-\$GUID.oslab.opentlc.com:8443"
oadm new-project justanother --display-name="Just Another Lab Project" --node-selector='region=primary' --admin="\${USER1}"

# Workaround

echo "Trying to redeploy Registry and Router if the failed to deploy"
echo "If you see: 'only failed deployments can be retried', this is expected"
oc deploy docker-registry --retry --config=/etc/openshift/master/openshift-master.kubeconfig
oc deploy trainingrouter --retry --config=/etc/openshift/master/openshift-master.kubeconfig

EOF

chmod +x /root/Create_Users_And_Projects.sh
echo '/root/Create_UsersAnd_Projects.sh  &>> /root/.Create_Users_And_Projects.sh.log &' >> /etc/rc.d/rc.local

### Check the Registry and Router are Running.
sleep_time=60;
oc get pods --config=/etc/openshift/master/openshift-master.kubeconfig | grep registry | grep Running
export registry_is_running=$?

#until [ $registry_is_running -eq 0 ]; do
  #echo "Registry test failed, will try to redeply"
  #oc deploy docker-registry --retry --config=/etc/openshift/master/openshift-master.kubeconfig
  #echo "Retrying in $sleep_time"
  #sleep $sleep_time
  #oc get pods --config=/etc/openshift/master/openshift-master.kubeconfig| grep registry | grep Running
  #export registry_is_running=$?

#done

#oc get pods --config=/etc/openshift/master/openshift-master.kubeconfig| grep trainingrouter | grep Running
#export router_is_running=$?

#until [ $router_is_running -eq 0 ]; do
  #echo "Router test failed, will try to redeply"
  #oc deploy trainingrouter --retry --config=/etc/openshift/master/openshift-master.kubeconfig
  #echo "Retrying in $sleep_time"
  #sleep $sleep_time

  #oc get pods | grep trainingrouter | grep Running
  #export router_is_running=$?

#done


echo "Rebooting the nodes and master in $sleep_time seconds"
sleep $sleep_time
export DATE=`date`;
export TOOK=`uptime`;
cat << EOF > /etc/motd
###############################################################################
###############################################################################
###############################################################################
Environment Deployment Is Completed : ${DATE}
POST CONFIG COMPLETE - GOOD TO GO
###############################################################################
###############################################################################
###############################################################################


EOF

cat /etc/motd
echo this took aprox $TOOK

touch .Post.Ended
reboot


# Note
#reposync --gpgcheck -l --repoid=rhel-7-server-ose-3.0-rpms --download_path=.
#scp the repo across
#mv Packages/* .
#createrepo .
