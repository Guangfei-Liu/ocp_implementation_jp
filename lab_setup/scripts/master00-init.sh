###############################################################################################################
#### COMMON Tasks
#1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo

#### master 00 ONLY 

###############################################################################################################
####
## Notes
## Maybe I need to remove all repos other than open.repo at the beginning

#vars
###############################################################################################################
export LOGFILE="/root/.master00Log.log"
###############################################################################################################

echo "Hostname is `cat /etc/hostname`" >> $LOGFILE

export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################################################
###############################################################################################################
###############################################################################################################
Environment Deployment In Progress : ${DATE}
DO NOT USE THIS ENVIRONMENT AT THIS POINT - DISCONNECT AND TRY AGAIN 20 MINUTES FROM THE DATE ABOVE
DO NOT USE THIS ENVIRONMENT AT THIS POINT - DISCONNECT AND TRY AGAIN 20 MINUTES FROM THE DATE ABOVE
DO NOT USE THIS ENVIRONMENT AT THIS POINT - DISCONNECT AND TRY AGAIN 20 MINUTES FROM THE DATE ABOVE
DO NOT USE THIS ENVIRONMENT AT THIS POINT - DISCONNECT AND TRY AGAIN 20 MINUTES FROM THE DATE ABOVE
Is this clear enough?
###############################################################################################################
###############################################################################################################
###############################################################################################################

EOF


# Delete repo file 
rm /etc/yum.repos.d/open.repo
rm /etc/sysconfig/docker
yum remove docker 
rm root/.ssh/*




export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################################################
###############################################################################################################
###############################################################################################################
Environment Deployment Is Completed : ${DATE}
The environment is ready Post Deployment Script. (If you already ran that, don't do it again)
###############################################################################################################
###############################################################################################################
###############################################################################################################

EOF


reboot

