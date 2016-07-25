###############################################################################################################
#### COMMON Tasks
# Fix some Internal issues, We don't do anything in implementation

#vars
###############################################################################################################
export LOGFILE="/root/.Node2.log"
###############################################################################################################

echo "Hostname is `hostname`" >> $LOGFILE

# This is the Fix for the SSH issue we have in our environment 
systemctl restart firewalld
# add eth0 to public zone
firewall-cmd --zone public --add-interface=eth0


echo "----Completed Host Specific Script `date` "| tee -a $LOGFILE