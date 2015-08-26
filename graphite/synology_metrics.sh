#!/bin/bash
#
# Uses snmpwalk to grab metrics from a synology nas and
# then sends them to a defined graphite server.
#
# By: Tim Smith - 7/20/2015
# Based on work by: Josh Behrends - 04/29/2013

# variables
CarbonServer="localhost"
CarbonPort="2003"
MetricRoot="servers"
Host="SynologyNAS"
HostIP="123.123.123.1"
SNMP_Community="public"

# snmpwalk the device
interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"') )
ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
load1=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.1 | awk '{print $4}'| tr -d '"')
load5=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.2 | awk '{print $4}'| tr -d '"')
load15=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.3 | awk '{print $4}'| tr -d '"')
cpufanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.4.2.0 | awk '{print $4}'| tr -d '"')
systemfanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.4.1.0 | awk '{print $4}'| tr -d '"')
powerstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.3.0 | awk '{print $4}'| tr -d '"')
systemstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.1.0 | awk '{print $4}'| tr -d '"')
temperature=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.2.0 | awk '{print $4}'| tr -d '"')
memTotalReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.5 | awk '{print $4}')
memAvailReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.6 | awk '{print $4}')
memBuffer=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.14 | awk '{print $4}')
memShared=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.13 | awk '{print $4}')
memCached=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.15 | awk '{print $4}')

# output to graphite from walked metrics above.
for (( i=0; i<${#interface[*]}; i=i+1 )); do
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCOutOctets" ${ifHCOutOctets[$i]} `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCInOctets" ${ifHCInOctets[$i]} `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
done

echo "$MetricRoot"."$Host".load.load-1" $load1 `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".load.load-5" $load5 `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".load.load-15" $load15 `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".uptime.seconds" $(($sysUpTime/100)) `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".temperature.degrees" $temperature `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};

echo "$MetricRoot"."$Host".status.cpu_fan" $cpufanstatus `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".status.system_fan" $systemfanstatus `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".status.power" $powerstatus `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".status.system" $systemstatus `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".memory.memTotalReal" $memTotalReal `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".memory.memAvailReal" $memAvailReal `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".memory.memBuffer" $memBuffer `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".memory.memShared" $memShared `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".memory.memCached" $memCached `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
