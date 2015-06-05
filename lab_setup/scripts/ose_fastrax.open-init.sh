export course=$2;
export whoiam=`hostname -s| awk -F"-" '{print $1}'`;
echo curl --connect-timeout 120 --max-time=180 -s  http://www.opentlc.com/download/${course}/${whoiam}-init.sh > /usr/local/bin/${whoiam}-init.sh;
curl --connect-timeout 120 --max-time=180 -s  http://www.opentlc.com/download/${course}/${whoiam}-init.sh > /usr/local/bin/${whoiam}-init.sh;
bash /usr/local/bin/${whoiam}-init.sh;



