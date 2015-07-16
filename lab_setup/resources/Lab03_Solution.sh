yum -y install bind bind-utils
host infranode00-$guid.oslab.opentlc.com  ipa.opentlc.com |grep infranode | awk '{print $4}'
54.201.162.205
 HostIP=`host infranode00-$guid.oslab.opentlc.com  ipa.opentlc.com |grep infranode | awk '{print $4}'`
 domain="cloudapps-$guid.oslab.opentlc.com"
  mkdir /var/named/zones
  echo "\$ORIGIN  .
\$TTL 1  ;  1 seconds (for testing only)
${domain} IN SOA master.${domain}.  root.${domain}.  (
  2011112904  ;  serial
  60  ;  refresh (1 minute)
  15  ;  retry (15 seconds)
  1800  ;  expire (30 minutes)
  10  ; minimum (10 seconds)
)
  NS master.${domain}.
\$ORIGIN ${domain}.
test A ${HostIP}
* A ${HostIP}"  >  /var/named/zones/${domain}.db


echo "// named.conf
options {
  listen-on port 53 { any; };
  directory \"/var/named\";
  dump-file \"/var/named/data/cache_dump.db\";
  statistics-file \"/var/named/data/named_stats.txt\";
  memstatistics-file \"/var/named/data/named_mem_stats.txt\";
  allow-query { any; };
  recursion yes;
  /* Path to ISC DLV key */
  bindkeys-file \"/etc/named.iscdlv.key\";
};
logging {
  channel default_debug {
    file \"data/named.run\";
    severity dynamic;
  };
};
zone \"${domain}\" IN {
  type master;
  file \"zones/${domain}.db\";
  allow-update { key ${domain} ; } ;
};" > /etc/named.conf

 chgrp named -R /var/named
 chown named -R /var/named/zones
 restorecon -R /var/named
 chown root:named /etc/named.conf
 restorecon /etc/named.conf

 systemctl enable named
 systemctl start named

 firewall-cmd --zone=public --add-service=dns --permanent
 firewall-cmd --reload




 ssh-keygen -f /root/.ssh/id_rsa -N ''
 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
 echo StrictHostKeyChecking no >> /etc/ssh/ssh_config
 for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh-copy-id root@$node ; done

 cat << EOF >> /etc/yum.repos.d/open.repo
[rhel-7-server-ose-3.0-rpms]
name=Red Hat Enterprise Linux 7 OSE 3
baseurl=http://www.opentlc.com/repos/rhel-7-server-ose-3.0-rpms
enabled=1
gpgcheck=0

EOF

for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do scp /etc/yum.repos.d/open.repo ${node}:/etc/yum.repos.d/open.repo ; done
yum -y  remove NetworkManager*
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y  remove NetworkManager*"  ; done

yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv gcc
yum -y install docker
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "yum -y install docker"  ; done
rm -rf /var/lib/docker/*
for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do ssh $node "rm -rf /var/lib/docker/*"  ; done
sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 0.0.0.0\/0'/" /etc/sysconfig/docker
  for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com; do scp  /etc/sysconfig/docker $node:/etc/sysconfig/docker ; done
  pvcreate /dev/vdb
  vgextend `vgs | grep rhel | awk '{print $1}'` /dev/vdb
  docker-storage-setup


  for node in infranode00-$guid.oslab.opentlc.com node00-$guid.oslab.opentlc.com node01-$guid.oslab.opentlc.com
  do
  ssh $node "pvcreate /dev/vdb ; vgextend `vgs | grep rhel | awk '{print $1}'` /dev/vdb; docker-storage-setup ; "
  ssh $node "systemctl enable docker; reboot "
  done

  
