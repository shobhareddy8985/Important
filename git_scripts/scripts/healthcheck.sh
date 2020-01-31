#!/bin/bash 
while true
do
EMAIL='shobha.reddy@diyotta.com,rajendra.cherukuri@diyotta.com,shekhar.gundemoni@diyotta.com'
datentime=`date`
function sysstat {
echo -e "
#####################################################################
    Health Check Report (CPU,Process,Disk Usage, Memory)
#####################################################################


Hostname         : `hostname`
User		 : `echo $USER`
Kernel Version   : `uname -r`
Uptime           : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
Last Reboot Time : `who -b | awk '{print $3,$4}'`



*********************************************************************
CPU Load - > Threshold < 1 Normal > 1 Caution , > 2 Unhealthy 
*********************************************************************
"
MPSTAT=`which mpstat`
MPSTAT=$?
if [ $MPSTAT != 0 ]
then
        echo "Please install mpstat!"
        echo "On Debian based systems:"
        echo "sudo apt-get install sysstat"
        echo "On RHEL based systems:"
        echo "yum install sysstat"
else
echo -e ""
LSCPU=`which lscpu`
LSCPU=$?
if [ $LSCPU != 0 ]
then
        RESULT=$RESULT" lscpu required to producre acqurate reults"
else
cpus=`lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}'`
i=0
while [ $i -lt $cpus ]
do
        echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($3 == var ) print $4 }' `"
        let i=$i+1
done
fi
echo -e "
Load Average   : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,`

Heath Status : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`
"
fi
echo -e "
*********************************************************************
                             Process
*********************************************************************

=> Top memory using processs/application

PID %MEM RSS COMMAND
`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10`

=> Top CPU using process/application
`top -M b -n1 | head -17 | tail -11`

"
#df -Pkh | grep -v 'Filesystem' > /tmp/df.status
#while read DISK
#do
#        LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
#        echo -e $LINE 
#        echo 
#done < /tmp/df.status
#echo -e "
#
#Heath Status"
#echo
#while read DISK
#do
#        USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
#        if [ $USAGE -ge 95 ] 
#        then
#                STATUS='Unhealty'
#        elif [ $USAGE -ge 90 ]
#        then
#                STATUS='Caution'
#        else
#                STATUS='Normal'
#        fi
#
#        LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
#        echo -ne $LINE "\t\t" $STATUS
#        echo 
#done < /tmp/df.status
#rm /tmp/df.status
#TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
#TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
#USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
#USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
#FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
#FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
#TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
#TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
#USEDSWAP=`free -m | tail -1| awk '{print $3}'`
#USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
#FREESWAP=`free -m |  tail -1| awk '{print $4}'`
#FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

echo -e "
*********************************************************************
                     PG Connections
*********************************************************************
"
installLog=$DI_HOME/logs/pgconn_check_log.log

#datentime=`date`
echo "--------------------PG connection status at $datentime----------------------------------" >>$installLog

while read line
do
	echo "${line}"|grep -q "^diserver.startup_port"
	if [[ $? -eq 0 ]] ; then
		expval=`echo ${line}|sed 's/\./_/g'`
		export ${expval}
	fi
	echo "${line}"|grep -q "^diserver.shutdown_port"
	if [[ $? -eq 0 ]] ; then
		expval=`echo ${line}|sed 's/\./_/g'`
		export ${expval}
	fi
		echo "${line}"|grep -q "^diserver.msg_port"
	if [[ $? -eq 0 ]] ; then
		expval=`echo ${line}|sed 's/\./_/g'`
		export ${expval}
	fi


done <"${DI_HOME}/conf/diserver.config"


url=`cat ${DI_HOME}/conf/diserver.config | grep "^jdbc.url=jdbc:postgresql://"`
host_details_vals=`echo $url |cut -d"/" -f3`
host=`echo $host_details_vals |cut -d":" -f1`
port=`echo $host_details_vals |cut -d":" -f2`
database=`cat ${DI_HOME}/conf/diserver.config | grep "^jdbc.url=jdbc:postgresql://" | cut -d "/" -f4`
user=`cat ${DI_HOME}/conf/diserver.config | grep "^jdbc.username" | cut -d "=" -f2`
password=`cat ${DI_HOME}/conf/diserver.config | grep "^jdbc.password" | cut -d "=" -f2`

echo "Postgres Host : $host" >> $installLog
echo "Postgres Port : $port" >> $installLog
echo "Postgres Database : $database" >> $installLog
echo "Postgres User : $user" >> $installLog
#count1=$1
count1=`psql -h $host -p $port -U $user -w -d $database -Atc "select count(*) from pg_stat_activity where state='active';"`
count2=`psql -h $host -p $port -U $user -w -d $database -Atc "select count(*) from pg_stat_activity where state IN('idle','idle in transaction','idle in transaction(aborted)');"`
count3=$((count1 + count2))
echo $count3
echo "Number of Active connections =' $count1'" >> $installLog
echo "Number of Idle connections=' $count2 '" >> $installLog
echo "Number of Connections=' $count3 '" >> $installLog
echo "****************** Jobs Running in PG *********************************************************************"
psql -h $host -p $port -U $user -w -d $database -Atc "select * from pg_stat_activity where state='active';"
echo "***********************************************************************************************************"

echo " "


echo "****************** Jobs 'idle','idle in transaction','idle in transaction(aborted)' in PG *********************************************************************"
psql -h $host -p $port -U $user -w -d $database -Atc "select * from pg_stat_activity where state IN('idle','idle in transaction','idle in transaction(aborted)');;"
echo "***********************************************************************************************************"


#if [[ $count3 -gt 350 ]] ;then

#echo "Total No of connection reached threshold : $count3" >>$installLog
#stat=`psql -h $host -p $port -U $user -w -d $database -Atc "select * from pg_stat_activity where state IN('idle','idle in transaction','idle in transaction(aborted)');"`
#echo "-----------Below are the $count2 connections which is in idle, idle in transaction or idle in transaction(aborted)' state -------------" >> $installLog
#echo "$stat" >> $installLog

#echo "Sending email notification...." >>$installLog

#echo -e 'Hi All,\n\nNumberi of Active connections =' $count1 '\nNumber of Idle connections=' $count2 '\nTotal Number of Connections=' $count3 '\n\n\nThanks\nRegards,\nDiyotta Support'   | mailx -s "PG connection threshold exceeded V4" techstylesupport@diyotta.com,anand.menon@diyotta.com
echo "-------------------------------------------------END--------------------------------------------------" >>$installLog
echo "" >> $installLog
echo "" >> $installLog
#fi

echo -e "
#*********************************************************************
#                     Controller Status
#*********************************************************************
#"


status=$($DI_HOME/bin/dicmd serverstatus)
stat=$(echo "$status" | grep "ExitCode" | cut -d ":" -f2)
if [ $stat -eq 0 ] ; then   
echo "Controller is Running Fine" 
echo "Checking Number of Connections on Startup Port $diserver_startup_port"

  nofstart=$(netstat -alnp | grep $diserver_startup_port | wc -l)
  startCLwait=$(netstat -alnp | grep $diserver_startup_port | grep CLOSE_WAIT | wc -l)
  startTMwait=$(netstat -alnp | grep $diserver_startup_port | grep TIME_WAIT | wc -l)
  startEST=$(netstat -alnp | grep $diserver_startup_port | grep ESTABLISHED | wc -l)
  echo " Total Number of Connection on Startup Port ($diserver_startup_port) are: $nofstart"
   echo "  Total Number of CLOSE_WAIT Connection on Startup Port ($diserver_startup_port) are: $startCLwait"
   echo "  Total Number of TIME_WAIT Connection on Startup Port ($diserver_startup_port) are: $startTMwait"
   echo "  Total Number of ESTABLISHED Connection on Startup Port ($diserver_startup_port) are: $startEST"

    echo "Checking Number of Connections on MSG Port $diserver_msg_port"
  nofmsg=$(netstat -alnp | grep $diserver_msg_port | wc -l)
  msgCLwait=$(netstat -alnp | grep $diserver_msg_port | grep CLOSE_WAIT | wc -l)
  msgMTMwait=$(netstat -alnp | grep $diserver_msg_port | grep TIME_WAIT | wc -l)
  msgEST=$(netstat -alnp | grep $diserver_msg_port | grep ESTABLISHED | wc -l)
  echo " Total Number of Connection on MSG Port ($diserver_msg_port) are: $nofmsg"
   echo "  Total Number of CLOSE_WAIT Connection on MSG Port ($diserver_msg_port) are: $msgCLwait"
   echo "  Total Number of TIME_WAIT Connection on MSG Port ($diserver_msg_port) are: $msgMTMwait"
   echo "  Total Number of ESTABLISHED Connection on MSGPort ($diserver_msg_port) are: $msgEST"

else
redflag=Y
  echo "*************WARNING:DICMD command not completed.******************" 
#  
  echo "Checking Number of Connections on Startup Port $diserver_startup_port"
  nofstart=$(netstat -alnp | grep $diserver_startup_port | wc -l)
  startCLwait=$(netstat -alnp | grep $diserver_startup_port | grep CLOSE_WAIT | wc -l)
  startTMwait=$(netstat -alnp | grep $diserver_startup_port | grep TIME_WAIT | wc -l)
  startEST=$(netstat -alnp | grep $diserver_startup_port | grep ESTABLISHED | wc -l)
  echo " Total Number of Connection on Startup Port ($diserver_startup_port) are: $nofstart"
   echo "  Total Number of CLOSE_WAIT Connection on Startup Port ($diserver_startup_port) are: $startCLwait"
   echo "  Total Number of TIME_WAIT Connection on Startup Port ($diserver_startup_port) are: $startTMwait"
   echo "  Total Number of ESTABLISHED Connection on Startup Port ($diserver_startup_port) are: $startEST"
   
    echo "Checking Number of Connections on MSG Port $diserver_msg_port"
  nofmsg=$(netstat -alnp | grep $diserver_msg_port | wc -l)
  msgCLwait=$(netstat -alnp | grep $diserver_msg_port | grep CLOSE_WAIT | wc -l)
  msgMTMwait=$(netstat -alnp | grep $diserver_msg_port | grep TIME_WAIT | wc -l)
  msgEST=$(netstat -alnp | grep $diserver_msg_port | grep ESTABLISHED | wc -l)
  echo " Total Number of Connection on Startup Port ($diserver_msg_port) are: $nofmsg"
   echo "  Total Number of CLOSE_WAIT Connection on Startup Port ($diserver_msg_port) are: $msgCLwait"
   echo "  Total Number of TIME_WAIT Connection on Startup Port ($diserver_msg_port) are: $msgMTMwait"
   echo "  Total Number of ESTABLISHED Connection on Startup Port ($diserver_msg_port) are: $msgEST"
   fi
}
FILENAME="$DI_HOME/logs/healthcheck/health-`hostname`-`date +%y%m%d`-`date +%H%M`.txt"
sysstat > $FILENAME
echo -e "Reported file $FILENAME generated in current directory." $RESULT
if [ "$EMAIL" != '' ] && [ "$redflag" = "Y" ]
then
        STATUS=`which mail`
        if [ "$?" != 0 ] 
        then
                echo "The program 'mail' is currently not installed."
        else
                cat $FILENAME | mail -s "$FILENAME" $EMAIL
        fi
fi
redflag=N
sleep 120
done

