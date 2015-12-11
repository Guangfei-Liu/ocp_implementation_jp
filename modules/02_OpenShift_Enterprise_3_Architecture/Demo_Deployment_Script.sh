#!/usr/bin/bash -x
export LOGFILE=./.Demo_Deployment.log

#### Demo prep script V1.0 - By Red Hat Global Enablement Team - Shachar Boresntein <sborenst@redhat.com>
#######################################################################################################################################################
#######################################################################################################################################################
################################################Common Tasks ##########################################################################################
#######################################################################################################################################################
#######################################################################################################################################################

# Vars
export USER1="david"
export USER2="karla"
export USER3="dude"

#### Check that the nodes are configured correctly
export nodes_online=0;
export sleep_time=5 ;

while [ $nodes_online == 0 ] ; do
echo "---Checking all nodes are on-line, sleeping for $sleep_time" | tee -a $LOGFILE
sleep $sleep_time;

export nodes_online=1;

# Checking that master is in the Master region
HOST=master00;
oc get nodes | grep $HOST | grep -vi not | grep Ready
if [ $? == 0 ]
then
	echo "----$HOST is configured correctly and is ready"
else
 	echo "----$HOST is not ready" ; export nodes_online=0 ;
fi

# Checking that Infranode is in the infra region
HOST=infranode00;
oc get nodes | grep $HOST | grep "region=infra" | grep -vi not | grep Ready
if [ $? == 0 ]
then
	echo "----$HOST is configured correctly and is ready"
else
 	echo "----$HOST is not ready" ; export nodes_online=0 ;
fi

# Checking that Node00 is in the East Zone region
HOST=node00;
oc get nodes | grep $HOST | grep "zone=east" | grep -vi not | grep Ready
if [ $? == 0 ]
then
	echo "----$HOST is configured correctly and is ready"
else
 	echo "----$HOST is not ready" ; export nodes_online=0 ;
fi

# Checking that Node01 is in the West Zone region
HOST=node01;
oc get nodes | grep $HOST | grep "zone=west" | grep -vi not | grep Ready
if [ $? == 0 ]
then
	echo "----$HOST is configured correctly and is ready"
else
 	echo "----$HOST is not ready" ; export nodes_online=0 ;
fi

done

echo 'All nodes were found to be "Ready" and in their appropriate "Regions".'
oc get nodes

# Workaround
echo "don't be alarmed to see erros in the next few lines, this is expected."
echo "we are trying to re-deploy something that should already be deployed"
oc deploy docker-registry --retry
oc deploy trainingrouter --retry

####4.0 COMMON For all Demo Snippets
echo "----COMMON Tasks - user Management - Creating ${USER1}, ${USER2} and ${USER3}" | tee -a $LOGFILE
useradd ${USER1}  | tee -a $LOGFILE
useradd ${USER2}  | tee -a $LOGFILE
useradd ${USER2}  | tee -a $LOGFILE

echo "----user Management - Adding them to /etc/openshift-passwd"  | tee -a $LOGFILE
htpasswd -cb /etc/openshift/openshift-passwd ${USER1} r3dh4t1!
htpasswd -b /etc/openshift/openshift-passwd ${USER2} r3dh4t1!
htpasswd -b /etc/openshift/openshift-passwd ${USER3} r3dh4t1!


## Vars
export GUID=`hostname|cut -f2 -d-|cut -f1 -d.` | tee -a $LOGFILE

echo "----COMMON Tasks - Grab the Repository"  | tee -a $LOGFILE
cd ~
git clone https://github.com/sborenst/OpenShiftEnterprise3_Demo  | tee -a $LOGFILE


#######################################################################################################################################################
#######################################################################################################################################################
#############################Prep for Demo snippet: Demo Snippet-Deploy from pre-baked containers######################################################
#######################################################################################################################################################
#######################################################################################################################################################
####5.1 Demo Snippet Tasks - Prep for Demo snippet: Demo Snippet-Deploy from pre-baked containers (Command Line)
echo "----COMMON Tasks - Prep for Demo snippet: Demo Snippet-Deploy from pre-baked containers (Command Line)"  | tee -a $LOGFILE

echo "----Create Project: weightwatcher-demo"   | tee -a $LOGFILE
oadm new-project weightwatcher-demo --display-name="Weightwatcher Demonstration"  --description="Weightwatcher Prebuild BRMS container" --node-selector='region=primary' --admin=${USER1}  | tee -a $LOGFILE
echo "----Create Project: hello-openshift-demo"   | tee -a $LOGFILE
oadm new-project hello-openshift-demo --display-name="hello-openshift Demonstration"  --description="hello-openshift Prebuild container" --node-selector='region=primary' --admin=${USER1}  | tee -a $LOGFILE

sleep 3;

echo "oc get projects"  | tee -a $LOGFILE
oc get projects  | tee -a $LOGFILE

echo "----Copying over ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/weightwatcher-pod.json to /home/${USER1}"  | tee -a $LOGFILE

cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/weightwatcher-pod.json /home/${USER1}
cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/hello-openshift-pod.json /home/${USER1}


echo "----Copying over ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/weightwatcher-complete.json"  | tee -a $LOGFILE
cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/weightwatcher-complete.json /home/${USER1}
cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployPrebuiltImage/hello-openshift-complete.json /home/${USER1}

### Fixing the GUID so that the .json file is set for our system.
sed -i s/GUID/$GUID/g /home/${USER1}/weightwatcher-complete.json
sed -i s/GUID/$GUID/g /home/${USER1}/hello-openshift-complete.json



ssh 192.168.0.200 "nohup docker pull spicozzi/weightwatcher &> /root/.spicozzi_image_status.log&"
ssh 192.168.0.201 "nohup docker pull spicozzi/weightwatcher &> /root/.spicozzi_image_status.log&"

#######################################################################################################################################################
#######################################################################################################################################################
#############################Demo Snippet-Deploy from an existing Git repository (Web Console) (STI Build)#############################################
#######################################################################################################################################################
#######################################################################################################################################################
####5.2 Demo Snippet Tasks - Prep for Demo Snippet-Deploy from an existing Git repository (Web Console) (STI Build)
echo "----COMMON Tasks - Prep for Demo Snippet-Deploy from an existing Git repository (Web Console) (STI Build)" | tee -a $LOGFILE

echo "----Create Project: SourceToImage-demo"   | tee -a $LOGFILE
oadm new-project sourcetoimage-demo --display-name="SourceToImage Demonstration"  --description="SourceToImage Demonstration" --node-selector='region=primary' --admin=${USER1}  | tee -a $LOGFILE

sleep 3;

echo "oc get projects"  | tee -a $LOGFILE
oc get projects | tee -a $LOGFILE

echo "----Creating /home/${USER1}/simplerubyapp-route.json " | tee -a $LOGFILE

#cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployS2I/simplerubyapp-route.json /home/${USER1}/simplerubyapp-route.json
### Fixing the GUID so that the .json file is set for our system.
#sed -i s/GUID/$GUID/g /home/${USER1}/simplerubyapp-route.json



#######################################################################################################################################################
#######################################################################################################################################################
#############################Demo Snippet- Deploy a 2 tiered application from template (Web Console and Command line)###################################
#######################################################################################################################################################
#######################################################################################################################################################
####5.3 Demo Snippet Tasks - Prep for Demo Snippet-Deploy a 2 tiered application from template (Web Console and Command line)
echo "----COMMON Tasks - Prep for Demo Snippet-Deploy a 2 tiered application from template (Web Console and Command line)" | tee -a $LOGFILE

echo "----Create Project: instantapps-demo"   | tee -a $LOGFILE
oadm new-project instantapps-demo --display-name="Instant Apps Demonstration"  --description="Instant Apps Demonstration" --node-selector='region=primary' --admin=${USER1}  | tee -a $LOGFILE

sleep 3;

echo "oc get projects"  | tee -a $LOGFILE
oc get projects | tee -a $LOGFILE



### Fixing the GUID so that the .json file is set for our system.
sed -i s/GUID/$GUID/g ~/OpenShiftEnterprise3_Demo/Snippet_DeployTemplate_2tier/InstantAppTempalte.json
cp ~/OpenShiftEnterprise3_Demo/Snippet_DeployTemplate_2tier/InstantAppTempalte.json /home/${USER1}/InstantAppTempalte.json


#oc create -f ~/OpenShiftEnterprise3_Demo/Snippet_DeployTemplate_2tier/InstantAppTempalte.json -n openshift  | tee -a $LOGFILE
oc create -f ~/OpenShiftEnterprise3_Demo/Snippet_DeployTemplate_2tier/InstantAppTempalte.json -n instantapps-demo | tee -a $LOGFILE


echo "#####Ignore an error regarding 'only failed deployments can be retried.'"  | tee -a $LOGFILE
oc deploy docker-registry --retry


#######################################################################################################################################################
#######################################################################################################################################################
#############################Demo Snippet-#############################################################################################################
#######################################################################################################################################################
#######################################################################################################################################################
####5.x Demo Snippet Tasks - #######################################################################################
