echo "On the master host as `root`, create a new project:"

oadm new-project quickstart --display-name="Quickstart" \
    --description='A demonstration of a "quickstart/template"' \
    --node-selector='region=primary' --admin=andrew


echo "On the master host as `root`, get and create the Example template:"

wget http://www.opentlc.com/download/ose_implementation/resources/Template_Example.json
oc create -f Template_Example.json -n openshift

echo "Create an instance of the template"
oc process -f  Template_Example.json > Template_InstantApp.json
oc get route -n quickstart

# the $guid var should be available already, but I'll keep this here just in case
export guid=`hostname|cut -f2 -d-|cut -f1 -d.`

echo "get, edit, and update the route resource"
oc get route -n quickstart -o yaml > example-route.yaml
sed -i s/frontend.quickstart.router.default.local/integrated.quickstart.cloudapps-$guid.oslab.opentlc.com/g example-route.yaml
oc update -f example-route.yaml -n quickstart

echo "Lab: Wiring Templates together"

echo "On the *master* host as `root`, create a new project, *wiring*:"

oadm new-project wiring --display-name='Wiring' \
    --description='A demonstration of wiring components together' \
    --node-selector='region=primary' --admin=marina

echo 'Enter password for Marina, r3dh4t1!'
su - marina -c "oc login -u marina --insecure-skip-tls-verify --server=https://master00-${GUID}.oslab.opentlc.com:8443"

echo "Stand Up the Frontend"
oc new-app -i openshift/ruby https://github.com/openshift/ruby-hello-world#beta4 -n wiring

echo "lets look at the BuildConfig that was created and the DeploymentConfig"
sleep 10

echo "The Builds"
oc get builds -n wiring

echo "The the DeploymentConfigs"
oc get dc -n wiring


echo "Modify the environment variables on our DC"
oc env dc/ruby-hello-world MYSQL_USER=root MYSQL_PASSWORD=redhat MYSQL_DATABASE=mydb -n wiring

echo "verifying the change"
oc env dc/ruby-hello-world --list -n wiring


echo "Expose the ruby-hello-world Service"

oc expose service --name=frontend-route ruby-hello-world --hostname="frontwire.wiring.cloudapps-$guid.oslab.opentlc.com" -n wiring


echo "Get the mysql template file"
wget http://www.opentlc.com/download/ose_implementation/resources/mysql_template.json

oc create -f mysql_template.json -n wiring

echo "start an instance of the mysql template in marinas project"
oc process  mysql-ephemeral -v MYSQL_USER=root,MYSQL_PASSWORD=redhat,MYSQL_DATABASE=mydb -n wiring | oc create -n wiring -f -

 echo "wait for 30 seconds and test the mysql database"
 sleep 30

curl `oc get services -n wiring | grep mysql | awk '{print $4}'`:3306


export hosting_node=`oc get pod -n wiring -t '{{range .items}}{{.metadata.name}} {{.spec.host}}{{"\n"}}{{end}}' | grep ruby-hello-world | grep -vi build | awk '{print $2}'`
export docker_id=`ssh $hosting_node "docker ps | grep hello-world | grep run" | awk '{print $1}'`
ssh $hosting_node "docker inspect $docker_id | grep -i mysql"


echo "We need to kill our front-end pods so they retry the database"

oc delete pods -l deploymentconfig=ruby-hello-world -n wiring

echo "Get the replication controller that is running for both the frontend and backend:"

oc get rc -n wiring

oc describe rc ruby-hello-world-1 -n wiring

oc delete pod   `oc get pod -n wiring | grep -e "hello-world-[0-9]" | grep -v build | awk '{print $1}'` -n wiring


echo "After a few moments, we can look at the list of pods again:"
sleep 5

oc get pod -n wiring | grep world

echo "inspect the actual docker container and check for mysql environment variables"
export hosting_node=`oc get pod -n wiring -t '{{range .items}}{{.metadata.name}} {{.spec.host}}{{"\n"}}{{end}}' | grep ruby-hello-world | grep -v build | awk '{print $2}'`
export docker_id=`ssh $hosting_node "docker ps | grep hello-world | grep run" | awk '{print $1}'`
ssh $hosting_node "docker inspect $docker_id | grep -i mysql"
