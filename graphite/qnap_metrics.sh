#!/bin/bash
#
# Uses snmpwalk to grab metrics from a QNAP nas and then sends 
# them to a defined graphite server.
#
# By: Josh Behrends - 09/09/2013

# variables
CarbonServer="localhost"
CarbonPort="2003"

MetricRoot="servers"
Host="nas01"
HostIP="123.123.123.50"
SNMP_Community="public"


# snmpwalk the device
interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"') )
ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
hd1temp=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.4.1.24681.1.2.11.1.3.1 | awk '{print $5}'| tr -d 'C/')
hd2temp=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.4.1.24681.1.2.11.1.3.2 | awk '{print $5}'| tr -d 'C/')
cpu_pct=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.24681.1.2.1 | awk '{print $4}'| tr -d '"')
systemp=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.24681.1.2.6 | awk '{print $5}'| tr -d 'C/')

# output to graphite from walked metrics above.
for (( i=0; i<${#interface[*]}; i=i+1 )); do
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCOutOctets" ${ifHCOutOctets[$i]} `date +%s`" | nc ${CarbonServer} ${CarbonPort};
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCInOctets" ${ifHCInOctets[$i]} `date +%s`" | nc ${CarbonServer} ${CarbonPort};
done

echo "$MetricRoot"."$Host".hdd.HDD1.Temp_F" $hd1temp `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".hdd.HDD2.Temp_F" $hd2temp `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".cpu.pct" $cpu_pct `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".system.Temp_F" $systemp `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".uptime.seconds" $(($sysUpTime/100)) `date +%s`" | nc ${CarbonServer} ${CarbonPort};


