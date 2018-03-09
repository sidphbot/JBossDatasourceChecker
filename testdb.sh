
dstmp=/tmp/dstmp
dblist=/tmp/dblist

user=`whoami`

JBOSS_HOME=`ps -ef |grep jboss |grep $user |grep "\-server" |tr " " "\n" |grep "\-Djboss\.home\.dir" |cut -d "=" -f 2`

red='\033[0;31m'
green='\033[0;32m'
color=$green
nc='\033[0m'

if [ -f $dstmp ];then
rm $dstmp
fi
if [ -f $dslist ];then
rm $dblist
fi

touch $dstmp $dblist

portlist=(`ps -ef |grep jboss |grep $user|grep -v grep |grep "\-server"|tr " " "\n" |grep "\-Djboss\.socket\.binding\.port\-offset" |cut -d "=" -f 2|sort -u`)
for port in ${portlist[@]}
do 
portoffed=`expr 9990 + $port`
echo Port : $portoffed


${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=datasources:read-resource()" > $dstmp
dsstart=`grep -n "\"data-source\" =>" $dstmp |cut -d ":" -f 1`
#dsstart=$(($dsstart + 1))

dsstop=`grep -n "}," $dstmp|head -1|cut -f 1 -d ":"`
#dsstop=$((dsstop - 1))

if [ $dsstart -eq $dsstop ]
then

sed -n "$dsstart,$dsstop p" $dstmp |cut -f 4 -d "\"" > $dblist

else
dsstart=$(($dsstart + 1))
dsstop=$((dsstop - 1))
sed -n "$dsstart,$dsstop p" $dstmp |cut -f 2 -d "\"" > $dblist
fi

while read ds
do

echo -----------------------
#echo "Name        : $ds"

testres=`${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=datasources/data-source=${ds}:test-connection-in-pool()"`
outcome=`echo $testres|cut -d "\"" -f 4`

if [ "$outcome" == "failed" ]; then

error=`echo $testres|cut -d "\"" -f 8`
color=$red
echo -e "${color}Name        : $ds${nc}"
echo -e "${color}Status      : Not available${nc}"
echo -e "${color}Error       : $error${nc}"

elif [ "$outcome" == "success" ]; then
color=$green
echo -e "${color}Name        : $ds${nc}"
echo -e "${color}Status      : Available${nc}"

else 
color=$red
echo -e "${color}Status      : NA${nc}"

fi

touch $dstmp

${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=datasources/data-source=${ds}:read-resource(recursive=true,include-runtime=true)" > $dstmp

jndi=`cat $dstmp|grep jndi-name |cut -d "\"" -f 4`

if [ "$jndi" == "" ];then

jndi=`cat $dstmp|grep jndi-name |awk '{print $3}'|cut -d"," -f 1`

fi

conn=`cat $dstmp|grep connection-url |cut -d "\"" -f 4`


if [ "$conn" == "" ];then

conn=`cat $dstmp|grep connection-url |awk '{print $3}'|cut -d"," -f 1`

fi

drivername=`cat $dstmp|grep driver-name |cut -d "\"" -f 4`


if [ "$drivername" == "" ];then

drivername=`cat $dstmp|grep driver-name |awk '{print $3}'|cut -d"," -f 1`

fi

security=`cat $dstmp|grep security-domain |cut -d "\"" -f 4`


if [ "$security" == "" ];then

security=`cat $dstmp|grep security-domain|awk '{print $3}'|cut -d"," -f 1`

fi

avail=`cat $dstmp|grep ActiveCount |cut -d "\"" -f 4`


if [ "$avail" == "" ];then

avail=`cat $dstmp|grep ActiveCount |awk '{print $3}'|cut -d"," -f 1`

fi

active=`cat $dstmp|grep AvailableCount |cut -d "\"" -f 4`


if [ "$active" == "" ];then

active=`cat $dstmp|grep AvailableCount |awk '{print $3}'|cut -d"," -f 1`

fi


size=`cat $dstmp|grep max-pool-size |cut -d "\"" -f 4`


if [ "$size" == "" ];then

size=`cat $dstmp|grep max-pool-size |awk '{print $3}'|cut -d"," -f 1`

fi

stats=`cat $dstmp|grep statistics-enabled|head -1|awk '{print $3}'|cut -d"," -f 1`

basepath=`${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/path=jboss.server.base.dir:read-resource"|grep path |cut -d "\"" -f 4`


jdbcmodule=`${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=datasources/jdbc-driver=${drivername}:read-attribute(name=driver-module-name)"|grep result | cut -d "\"" -f 4`

if [ "$jdbcmodule" == "" ];then

jdbcmodule=`${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=datasources/jdbc-driver=${drivername}:read-attribute(name=driver-module-name)"|grep result |awk '{print $3}'|cut -d"," -f 1`

fi



if [ "`echo $basepath|grep standalone`" != "" ];then

modulepath=${JBOSS_HOME}/modules/`echo $jdbcmodule|tr "." "/"`/main

else

modulepath=${basepath}/modules/`echo $jdbcmodule|tr "." "/"`/main

fi
#echo modulepath=$modulepath
modulejar=`ls -l ${modulepath}|grep jar|awk '{print $9}'`

if [ "$security" == "" ] || [ "$security" == "undefined" ];then
user=`cat $dstmp|grep user-name|cut -d "\"" -f 4`

if [ "$user" == "" ];then

user=`cat $dstmp|grep user-name|awk '{print $3}'|cut -d"," -f 1`

fi

else
user=`${JBOSS_HOME}/bin/jboss-cli.sh -c --controller=localhost:$portoffed --command="/subsystem=security/security-domain=${security}:read-resource(recursive=true)"|grep username |cut -d "\"" -f 4`
fi

if [ -f $dstmp ];then
rm $dstmp
fi

echo -e "${color}JNDI name   : $jndi${nc}"
echo -e "${color}Conn String : $conn${nc}"
echo -e "${color}Driver_Name : $drivername${nc}"
echo -e "${color}Module_Jar  : $modulejar${nc}"
echo -e "${color}User        : $user${nc}"

if [ "$stats" == "false" ];then

echo -e "${color}Pool Usage  : [STATS_DISABLED]${nc}"
#echo pool Size   : "[STATS_DISABLED]"
else 

echo -e "${color}Pool Usage  :" $active"/"$avail "(active/available count)${nc}"
#echo pool Size   : $size
fi
echo -e "${color}pool Size   : $size${nc}"



done < "$dblist"
done
