export project=lifecycle
export user=marina

echo "As root, Create a project for Marina to work with:"
oadm new-project ${project} --display-name="${project} Lab" \
    --description="This is the project we use to learn about ${project}" \
    --admin=${user} --node-selector='region=primary'

echo "Lets create an app based on the https://github.com/openshift/ruby-hello-world.git#beta4 repo"



oc new-app https://github.com/sborenst/ruby-hello-world.git

let’s take a moment to add the environment variables for it.


oc env dc/ruby-hello-world MYSQL_USER=root MYSQL_PASSWORD=redhat MYSQL_DATABASE=mydb -n ${project}

While we wait for the build to finish, lets expose our service

oc expose service ruby-hello-world \
  --name="ruby-hello-world" \
  --hostname=ruby-hello-world.lifecycle.cloudapps-${guid}.oslab.opentlc.com -n ${project}

  Take a look at the current BuildConfig for our application:



oc get buildconfig ruby-hello-world -o yaml -n ${project}

Change the "uri" reference to match the name of your Github repository.

echo "What is your user name in git hub"
echo "Example, mine is 'https://github.com/sborenst/ruby-hello-world'"
read repo


oc get buildconfig ruby-hello-world -o yaml -n ${project} | sed "s%https://github.com/openshift/ruby-hello-world.git%${repo}%g" | tee edited_ruby-hell-world.yaml
oc update bc -f edited_ruby-hell-world.yaml


oc get buildconfig ruby-hello-world -o yaml -n ${project}


Run oc get builds to see if the new build has started:

 oc get builds
