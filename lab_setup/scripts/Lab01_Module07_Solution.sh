whoami | grep andrew
if [ $? -ne 0 ]
    echo "Need to be andrew"
  exit
fi

echo "Echo enter Root Password to create project:"
su - root -c "oadm new-project hello-s2i --display-name='Hello Source2Image' \
    --description='This is the project we use to learn about Source to Image builds' \
      --node-selector='region=primary' --admin='andrew'"

export guid=`hostname|cut -f2 -d-|cut -f1 -d.`


echo "Become and authenticate to OpenShift Enterprise as user andrew:"

oc login -u andrew --insecure-skip-tls-verify --server=https://master00-${guid}.oslab.opentlc.com:8443

echo "Change the context to the hello-s2i project:"

echo "Switch to the hello-s2i project"
oc project hello-s2i
 echo "create a 'new-app' defenition the simple-openshift-sinatra-sti repo"
 oc new-app https://github.com/openshift/simple-openshift-sinatra-sti.git -o json | tee ~/simple-sinatra.json

echo "To create the build components, use the oc create command on the BuildConfig file:"
oc create -f ~/simple-sinatra.json

echo "This will take some time, here"
echo "sleeping to let the build start so we can review the log"
echo "pushing the image might take up to 10-12 minutes with the hardware we are using"
sleep 30
oc build-logs simple-openshift-sinatra-sti-1

sleep 10
echo "After your build is complete, to verify your pod and service, run the following:"

curl `oc get services | grep sin | awk '{print $4":"$5}' | awk -F'/' '{print $1}'`

echo "Your last step is to add a route to make the application publicly accessible. To do this, run the following:"
oc expose service simple-openshift-sinatra  --hostname=mysinatra.cloudapps-${guid}.oslab.opentlc.com

echo "Echo enter Root Password to create project:"
su - root -c "oadm new-project nodejs --display-name='Hello nodejs' \
    --description='This is the project we use to learn about nodejs' \
      --node-selector='region=primary' --admin='andrew'"

echo "Creating project nodejs"
oc project nodejs

echo "Creating new-app defenition file"
oc new-app  https://github.com/openshift/nodejs-ex -o json | tee ~/nodejs-example.json
echo "Create the application"
oc create -f ~/nodejs-example.json
echo "Scale the application"
oc scale --replicas=4 deploymentconfigs/nodejs-ex
echo "expose the service and create the route"
oc expose services/nodejs-ex --name="nodejs-route" --hostname="nodejs.cloudapps-${guid}.oslab.opentlc.com"
echo "next we will watch the build log"
sleep 30
oc build-logs nodejs-ex-1

sleep 10
oc get pods
echo "press any key to see the output of curl to the route"
echo "Better yet, check in your browser: nodejs.cloudapps-${guid}.oslab.opentlc.com"
read x
curl nodejs.cloudapps-${guid}.oslab.opentlc.com
