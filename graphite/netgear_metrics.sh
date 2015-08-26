#!/bin/bash
#
# Uses snmpwalk to grab metrics from a netgear gig switch and
# then sends them to a defined graphite server.
#
# By: Tim Smith - 8/26/2015
# Based on work by: Josh Behrends - 04/29/2013

# variables
CarbonServer="localhost"
CarbonPort="2003"
MetricRoot="network"
Host="neatgear_switch"
HostIP="123.123.123.1"
SNMP_Community="public"

# snmpwalk the device
interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"' | grep -e ^g) )
ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')

# output to graphite from walked metrics above.
for (( i=0; i<${#interface[*]}; i=i+1 )); do
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCOutOctets" ${ifHCOutOctets[$i]} `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCInOctets" ${ifHCInOctets[$i]} `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
done

echo "$MetricRoot"."$Host".uptime.seconds" $(($sysUpTime/100)) `date +%s`" | nc -w 1 ${CarbonServer} ${CarbonPort};
