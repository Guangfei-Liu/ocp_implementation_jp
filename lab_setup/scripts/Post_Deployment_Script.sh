####3.0 User and project Creation 
echo "----User and project Creation"  

####3.1 user Management
echo "----user Management - Creating Joe and Alice"  
useradd joe
useradd alice
echo "----user Management - Adding them to /etc/openshift-passwd" 
htpasswd -b /etc/openshift-passwd joe r3dh4t1!
htpasswd -b /etc/openshift-passwd alice r3dh4t1! 

echo 'export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`' >> /home/joe/.bash_profile
echo 'export GUID=`hostname|cut -f2 -d-|cut -f1 -d.`' >> /home/alice/.bash_profile




 
