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



####1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo [ deprecated this is done in the image for now]
echo "----1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo" | tee -a $LOGFILE
echo "---- Adding OSE3 Repository to  /etc/yum.repos.d/open.repo" | tee -a $LOGFILE
# added the Repo to enable the Ravello Fix packages.
cat << EOF >> /etc/yum.repos.d/open.repo
[ose3_fix]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/ose3_ravellofix
enabled=1
gpgcheck=0
EOF

cat << EOF >> /etc/motd


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

