###############################################################################################################
#### COMMON Tasks
#1.1 COMMON -  Add the Red Hat OpenShift Enterprise 3.0 Repo (with Ravello Fix)

#vars
###############################################################################################################
export LOGFILE="/root/.Node01Log.log"
###############################################################################################################

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

echo "Hostname is `hostname`" >> $LOGFILE
echo "----Completed Host Specific Script `date`" | tee -a $LOGFILE