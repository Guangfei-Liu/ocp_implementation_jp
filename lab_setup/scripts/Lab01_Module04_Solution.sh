#Labs_Module04.adoc
#1. Resource Management
#In this module we have the following labs:
## Lab: Users, Projects and Quotas
## Lab: Creating Services and Routes
## Lab: Deployment Configuration and Replication Controllers (Missing)

echo "Create Projects"
echo "On the master host use the oadm command to create a project, and assign an administrative user to it:"

oadm new-project resourcemanagement --display-name="Resources Management" \
    --description="This is the project we use to learn about resource management" \
    --admin=andrew  --node-selector='region=primary'

echo "Applying Quota to Projects"
echo "Create a Quota definition file"

cat << EOF > quota.json
{
  "apiVersion": "v1",
  "kind": "ResourceQuota",
  "metadata": {
    "name": "test-quota"
  },
  "spec": {
    "hard": {
      "memory": "1Gi",
      "cpu": "20",
      "pods": "3",
      "services": "5",
      "replicationcontrollers":"5",
      "resourcequotas":"1"
    }
  }
}
EOF

echo "On the master host apply the file you just created with the oc create command:"

oc create -f quota.json --namespace=resourcemanagement

echo "On the master host make sure it was created:"

oc get -n resourcemanagement quota
echo "On the master host verify limits and examine usage:"

oc describe quota test-quota -n resourcemanagement

echo "Create the Limits file"

cat << EOF > limits.json
{
    "kind": "LimitRange",
    "apiVersion": "v1",
    "metadata": {
        "name": "limits",
        "creationTimestamp": null
    },
    "spec": {
        "limits": [
            {
                "type": "Pod",
                "max": {
                    "cpu": "500m",
                    "memory": "750Mi"
                },
                "min": {
                    "cpu": "10m",
                    "memory": "5Mi"
                }
            },
            {
                "type": "Container",
                "max": {
                    "cpu": "500m",
                    "memory": "750Mi"
                },
                "min": {
                    "cpu": "10m",
                    "memory": "5Mi"
                },
                "default": {
                    "cpu": "100m",
                    "memory": "100Mi"
                }
            }
        ]
    }
}
EOF

echo "On the master host run oc create against the limits.json file and the 'resourcemanagement' project"

oc create -f limits.json --namespace=resourcemanagement

echo "Review your limit ranges on the master host:"

oc describe limitranges limits -n resourcemanagement

echo "Running commands as Andrew"
echo 'When asked for Password, Enter: r3dh4t1!'
su - andrew -c "export guid=`hostname|cut -f2 -d-|cut -f1 -d.` ; oc login -u andrew --insecure-skip-tls-verify --server=https://master00-${guid}.oslab.opentlc.com:8443"


cat <<EOF > hello-pod.json
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-openshift",
    "creationTimestamp": null,
    "labels": {
      "name": "hello-openshift"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "hello-openshift",
        "image": "openshift/hello-openshift:v0.4.3",
        "ports": [
          {
            "hostPort": 36061,
            "containerPort": 8080,
            "protocol": "TCP"
          }
        ],
        "resources": {
          "limits": {
            "cpu": "10m",
            "memory": "16Mi"
          }
        },
        "terminationMessagePath": "/dev/termination-log",
        "imagePullPolicy": "IfNotPresent",
        "capabilities": {},
        "securityContext": {
          "capabilities": {},
          "privileged": false
        },
        "nodeSelector": {
          "region": "primary"
        }
      }
    ],
    "restartPolicy": "Always",
    "dnsPolicy": "ClusterFirst",
    "serviceAccount": ""
  },
  "status": {}
}

EOF


/bin/cp -f hello-pod.json  /home/andrew/hello-pod.json
chown andrew:andrew /home/andrew/hello-pod.json

su - andrew -c "oc create -f hello-pod.json"
pods/hello-openshift

sleep 3
su - andrew -c "oc get pods"

echo "Run the oc describe command to learn about your pod."
su - andrew -c "oc describe pod hello-openshift"
Test that your pod is responding with "Hello OpenShift"


export ip=`oc get pod -t '{{range .items}}{{.metadata.name}} {{.status.podIP}}{{"\n"}}{{end}}'|grep hello-openshift|awk '{print $2}'`
su - andrew -c "curl http://${ip}:8080"

echo "Great, the pod works, Now, lets kill it and create a few more"

su - andrew -c "oc delete -f hello-pod.json"

echo "Create a new definition file that launches 4 hello-pods"

cat << EOF > hello-many-pods.json
{
  "metadata":{
    "name":"quota-pod-deployment-test"
  },
  "kind":"List",
  "apiVersion":"v1",
  "items":[
    {
      "kind": "Pod",
      "apiVersion": "v1",
      "metadata": {
        "name": "hello-openshift-1",
        "creationTimestamp": null,
        "labels": {
          "name": "hello-openshift"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "hello-openshift",
            "image": "openshift/hello-openshift",
            "ports": [
              {
                "containerPort": 8080,
                "protocol": "TCP"
              }
            ],
            "resources": {
              "limits": {
                "cpu": "10m",
                "memory": "16Mi"
              }
            },
            "terminationMessagePath": "/dev/termination-log",
            "imagePullPolicy": "IfNotPresent",
            "capabilities": {},
            "securityContext": {
              "capabilities": {},
              "privileged": false
            }
          }
        ],
        "restartPolicy": "Always",
        "dnsPolicy": "ClusterFirst",
        "serviceAccount": ""
      },
      "status": {}
    },
    {
      "kind": "Pod",
      "apiVersion": "v1",
      "metadata": {
        "name": "hello-openshift-2",
        "creationTimestamp": null,
        "labels": {
          "name": "hello-openshift"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "hello-openshift",
            "image": "openshift/hello-openshift",
            "ports": [
              {
                "containerPort": 8080,
                "protocol": "TCP"
              }
            ],
            "resources": {
              "limits": {
                "cpu": "10m",
                "memory": "16Mi"
              }
            },
            "terminationMessagePath": "/dev/termination-log",
            "imagePullPolicy": "IfNotPresent",
            "capabilities": {},
            "securityContext": {
              "capabilities": {},
              "privileged": false
            }
          }
        ],
        "restartPolicy": "Always",
        "dnsPolicy": "ClusterFirst",
        "serviceAccount": ""
      },
      "status": {}
    },
    {
      "kind": "Pod",
      "apiVersion": "v1",
      "metadata": {
        "name": "hello-openshift-3",
        "creationTimestamp": null,
        "labels": {
          "name": "hello-openshift"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "hello-openshift",
            "image": "openshift/hello-openshift",
            "ports": [
              {
                "containerPort": 8080,
                "protocol": "TCP"
              }
            ],
            "resources": {
              "limits": {
                "cpu": "10m",
                "memory": "16Mi"
              }
            },
            "terminationMessagePath": "/dev/termination-log",
            "imagePullPolicy": "IfNotPresent",
            "capabilities": {},
            "securityContext": {
              "capabilities": {},
              "privileged": false
            }
          }
        ],
        "restartPolicy": "Always",
        "dnsPolicy": "ClusterFirst",
        "serviceAccount": ""
      },
      "status": {}
    },
    {
      "kind": "Pod",
      "apiVersion": "v1",
      "metadata": {
        "name": "hello-openshift-4",
        "creationTimestamp": null,
        "labels": {
          "name": "hello-openshift"
        }
      },
      "spec": {
        "containers": [
          {
            "name": "hello-openshift",
            "image": "openshift/hello-openshift",
            "ports": [
              {
                "containerPort": 8080,
                "protocol": "TCP"
              }
            ],
            "resources": {
              "limits": {
                "cpu": "10m",
                "memory": "16Mi"
              }
            },
            "terminationMessagePath": "/dev/termination-log",
            "imagePullPolicy": "IfNotPresent",
            "capabilities": {},
            "securityContext": {
              "capabilities": {},
              "privileged": false
            }
          }
        ],
        "restartPolicy": "Always",
        "dnsPolicy": "ClusterFirst",
        "serviceAccount": ""
      },
      "status": {}
    }
  ]
}


EOF

/bin/cp -f hello-many-pods.json  /home/andrew/hello-many-pods.json
chown andrew:andrew /home/andrew/hello-many-pods.json

echo "Create the items in the hello-many-pods.json file"

su - andrew -c"oc create -f hello-many-pods.json"

echo "Because we created a quota, the forth pod will not be created."
echo "Lets delete the objects and move on"

sleep 5;

su - andrew -c"oc delete  -f hello-many-pods.json"

echo "Lab: Creating Services and Routes"

oadm new-project svcslab --display-name="Services Lab" \
    --description="This is the project we use to learn about services" \
    --admin=andrew  --node-selector='region=primary'

echo "Become the andrew user and log back into OpenShift and switch to the svcslab project:"

su - andrew -c"oc project svcslab"

echo "Run the following command to create the hello-service.json file:"

cat <<EOF > hello-service.json
{
  "kind": "Service",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-service"
  },
  "spec": {
    "selector": {
      "name":"hello-openshift"
    },
    "ports": [
      {
        "protocol": "TCP",
        "port": 8888,
        "targetPort": 8080
      }
    ]
  }
}
EOF

/bin/cp -f hello-service.json  /home/andrew/hello-service.json
chown andrew:andrew /home/andrew/hello-service.json

echo "Before we create the service, lets create a few pods for it to represent"

su - andrew -c"oc delete -f hello-many-pods.json"

echo "Run the following commands to create and verify the pod:"

su - andrew -c"oc create -f hello-service.json"

echo "Display the running services (under the current project)"

su - andrew -c"oc get services"

su - andrew -c"oc describe service hello-service"
echo "Notice that there are no 'endpoints' for the service because there are not pods. yet."
su - andrew -c"oc create -f hello-many-pods.json"

echo "Now lets check the service again, you can see that the pods who share the label 'name=hello-service' are all listed."


su - andrew -c"oc describe service hello-service"

echo "expose the route and the service."
su - andrew -c"export guid=`hostname|cut -f2 -d-|cut -f1 -d.` ; echo  --hostname=hello2-openshift.cloudapps-${guid}.oslab.opentlc.com"
echo "Lets see our routes"

su - andrew -c"oc get routes"
su - andrew -c"export guid=`hostname|cut -f2 -d-|cut -f1 -d.` ;curl http://hello2-openshift.cloudapps-${guid}.oslab.opentlc.com"
