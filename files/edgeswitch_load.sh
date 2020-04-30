#!/bin/bash
snmpwalk -v2c -c public $1 -m FASTPATH-SWITCHING-MIB FASTPATH-SWITCHING-MIB::agentSwitchCpuProcessTotalUtilization.0 | sed -r 's/.*5 Secs|60 Secs|300 Secs|\(|\)|%|\"//g' | awk -v hostname=$1 '{print "edgeswitch_load,host="hostname" load0="$1",load1="$2",load5="$3}'
