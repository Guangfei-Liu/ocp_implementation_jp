####3.0 User and project Creation 
echo "----User and project Creation"  

####3.1 user Management
echo "----user Management - Creating Joe and Alice"  
useradd joe
useradd alice
echo "----user Management - Adding them to /etc/openshift-passwd" 
htpasswd -b /etc/openshift-passwd joe r3dh4t1!
htpasswd -b /etc/openshift-passwd alice r3dh4t1! 



####3.2 Create Project Demo
echo "----Create Project: Demo"  
echo "XXXX openshift ex new-project demo"  
#openshift ex new-project demo --display-name="OpenShift 3 Demo" --description="This is the first demo project with OpenShift v3" --admin=htpasswd:joe
osadm new-project demo --display-name="OpenShift 3 Demo"  --description="This is the first demo project with OpenShift v3" --admin=joe
# check the output that this happened.

echo ----sleeping for 10 seconds
sleep 10

echo "osc get projects" 
osc get projects 

sed -i "s/schedulerConfigFile:.*/schedulerConfigFile: \"\/etc\/openshift\/scheduler.json\"/g" /etc/openshift/master.yaml 


cat << EOF >>   /etc/openshift/scheduler.json  
{
      "predicates" : [
        {"name" : "PodFitsResources"},
        {"name" : "PodFitsPorts"},
        {"name" : "NoDiskConflict"},
        {"name" : "Region", "argument" : {"serviceAffinity" : { "labels" : ["region"]}}}
      ],"priorities" : [
        {"name" : "LeastRequestedPriority", "weight" : 1},
        {"name" : "ServiceSpreadingPriority", "weight" : 1},
        {"name" : "Zone", "weight" : 2, "argument" : {"serviceAntiAffinity" : { "label" : "zone" }}}
      ]
    }
EOF





#/etc/openshift/master.yaml
#
#/etc/openshift/scheduler.json


echo "----Creating router for environment"  
#openshift ex router --create --credentials=/var/lib/openshift/openshift.local.certificates/openshift-client/.kubeconfig --images='registry.access.redhat.com/openshift3_beta/ose-${component}:${version}' --replicas=3 
osadm router --create --credentials=/var/lib/openshift/openshift.local.certificates/openshift-router/.kubeconfig --images='registry.access.redhat.com/openshift3_beta/ose-${component}:${version}'
echo "---Configure Registry for environment"  
echo "XXXX openshift ex registry --create "  
#openshift ex registry --create --credentials=/var/lib/openshift/openshift.local.certificates/openshift-client/.kubeconfig --images='registry.access.redhat.com/openshift3_beta/ose-${component}:${version}'
osadm registry --create --credentials=/var/lib/openshift/openshift.local.certificates/openshift-registry/.kubeconfig --images='registry.access.redhat.com/openshift3_beta/ose-${component}:${version}'



#expect as the result, don't continue until you get it. this can take several minutes. 
#"docker-registry server (dev) (v0.9.0)"
echo "curl 172.x.x.x:5000"
export registry_online=0;
export sleep_time=20 ;
while [ $registry_online == 0 ] ;do
echo "Waiting for Registry to get online, sleeping for $sleep_time";
sleep $sleep_time;
echo curl -s `osc get services | grep registry | awk '{print $4":"$5}' | awk -F'/' '{print $1}' `
curl -s `osc get services | grep registry | awk '{print $4":"$5}' | awk -F'/' '{print $1}'` >> .registry.check.output.log

search_string="docker-registry";
echo "Waiting on search string: $search_string";
grep  $search_string .registry.check.output.log;
if [ $? == 0 ] 
then
	export registry_online=1;	
fi

done


osc create -f ~/training/beta3/image-streams.json -n openshift




 
