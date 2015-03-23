#!/bin/bash
#
# Uses snmpwalk to grab metrics from an AVTech Roomlert 24E monitoring device
# and then sends them to a defined graphite server.
#
# By: Josh Behrends - 03/21/2015

# variables
CarbonServer="localhost"
CarbonPort="2003"

MetricRoot="environment"
Host="roomalert24e"
HostIP="123.123.123.123"
SNMP_Community="public"


# snmpwalk the device
sysUpTime=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3.0 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
internaltempf=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.1.1.1.0 | awk '{print $4 * .01}')
internaltempc=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.1.1.2.0 | awk '{print $4 * .01}')
internalrh=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.1.2.1.0 | awk '{print $4 * .01}')
extsensors=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.2  | cut -d'.' -f13 | uniq)

# echo output to graphite from walked metrics above.
echo "$MetricRoot"."$Host".uptime.seconds" $(($sysUpTime/100)) `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".sensors.internal.tempf" $internaltempf `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".sensors.internal.tempc" $internaltempc `date +%s`" | nc ${CarbonServer} ${CarbonPort};
echo "$MetricRoot"."$Host".sensors.internal.rh" $internalrh `date +%s`" | nc ${CarbonServer} ${CarbonPort};

# loop through the detected external sensors
for s in $extsensors; do
  exttempc[$s]=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.2.$s.1.0 | awk '{print $4 * .01}')
  exttempf[$s]=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.2.$s.2.0 | awk '{print $4 * .01}')
  extrh[$s]=$(snmpwalk -On -v 1 -c $SNMP_Community $HostIP 1.3.6.1.4.1.20916.1.5.1.2.$s.3.0 | awk '{print $4 * .01}')
  [[ ! -z "${exttempc[$s]}" ]] && echo "$MetricRoot"."$Host".sensors.external."${s}".tempc" ${exttempc[$s]} `date +%s`" | nc ${CarbonServer} ${CarbonPort};
  [[ ! -z "${exttempf[$s]}" ]] && echo "$MetricRoot"."$Host".sensors.external."${s}".tempf" ${exttempf[$s]} `date +%s`" | nc ${CarbonServer} ${CarbonPort};
  [[ ! -z "${extrh[$s]}" ]] && echo "$MetricRoot"."$Host".sensors.external."${s}".rh" ${extrh[$s]} `date +%s`" | nc ${CarbonServer} ${CarbonPort};
done

