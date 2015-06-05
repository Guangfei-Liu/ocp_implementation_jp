#!/bin/bash
export USER=$1
export course=$2;

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


####2.1 Download and run the DNS bind install and configure the *.cloudapps-$GUID.oslab.opentlc.com wildcard

echo "XXXX2.1 Download and run the DNS bind install and configure the .cloudapps-$GUID.oslab.opentlc.com wildcard"  | tee -a $LOGFILE
echo "XXXXDownloading http://www.opentlc.com/download/o${course}/oselab.dns.installer.sh"  | tee -a $LOGFILE
curl -s http://www.opentlc.com/download/${course}/oselab.dns.installer.sh > /root/oselab.dns.installer.sh

#echo "XXXXrunning /root/oselab.dns.installer.sh"  | tee -a $LOGFILE
#bash /root/oselab.dns.installer.sh  | tee -a $LOGFILE

#yum install ipatables-service -y
#systemctl stop firewalld

#systemctl disable firewalld

#iptables -I INPUT -p tcp --dport 53 -j ACCEPT
#iptables -I INPUT -p udp --dport 53 -j ACCEPT
#iptables-save


###############################################################################################################
###############################################################################################################
###############################################################################################################
####2.2 Do IPA stuff for keys and guacd

if [ -z "$USER" ]
then
        echo "ERROR: Open-init requires a username."
        exit
fi
passwd=`uuidgen`

echo "<configs>
    <config name=\"Demo\" protocol=\"vnc\">
        <param name=\"hostname\" value=\"localhost\" />
        <param name=\"port\" value=\"5901\" />
        <param name=\"password\" value=\"$passwd\" />
    </config>
</configs>" > /etc/guacamole/noauth-config.xml

chgrp tomcat /etc/guacamole/noauth-config.xml
chmod o-rwx /etc/guacamole/noauth-config.xml

#mv /home/user /home/$USER
#ln -s /home/$USER /home/user

rm -rf /home/$USER/.vnc /home/$USER/.X*
mkdir -p /home/$USER/.vnc
echo $passwd|vncpasswd -f > /home/$USER/.vnc/passwd
chmod go-rwx /home/$USER/.vnc/passwd
chown -R $USER:partner-users /home/$USER
restorecon -R /home/$USER

# commented out by sborenst because it was erroring out
#unalias cp
cp -f /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service
sed -i "s/<USER>/$USER/g" /etc/systemd/system/vncserver@.service
systemctl daemon-reload
systemctl start vncserver@:1.service
systemctl enable vncserver@:1

echo "RewriteEngine on
RewriteRule ^/guacamole/ /guacamole [R]

<Proxy *>
        Order deny,allow
        Deny from all
        Allow from localhost
</Proxy>

<Location /guacamole>
  SSLREQUIRESSL
  AuthType Kerberos
  AuthName \"Password Required\"
  KrbAuthRealms OPENTLC.COM
  KrbServiceName HTTP/guacamole.opentlc.com
  KrbMethodNegotiate off
  KrbMethodK5Passwd on
  KrbSaveCredentials on
  Krb5Keytab /etc/httpd/conf/guacamole.opentlc.com.keytab
  Require user $USER@OPENTLC.COM tonyv@OPENTLC.COM adingman@OPENTLC.COM prutledg@OPENTLC.COM awaizman@OPENTLC.COM
  ProxyPass http://localhost:48080/guacamole
  ProxyPassReverse http://localhost:48080/guacamole
  Order allow,deny
  Allow from all
</Location>" > /etc/httpd/conf.d/guacamole.conf

systemctl enable guacd
systemctl enable tomcat
systemctl enable httpd
systemctl restart guacd
systemctl restart tomcat 
systemctl restart httpd 

#replaced by sborenst 
#firewall-cmd --zone=public --add-service=https --permanent
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables-save

export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################################################
###############################################################################################################
###############################################################################################################
Environment Deployment Is Completed : ${DATE}
###############################################################################################################
###############################################################################################################
###############################################################################################################

EOF

reboot;