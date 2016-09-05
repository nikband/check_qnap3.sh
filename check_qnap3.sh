#!/bin/bash
############################# Created and written by Matthias Luettermann ###############
############################# finetuning by primator@gmail.com
############################# finetuning by n.bandini@gmail.com
#
#	copyright (c) 2008 Shahid Iqbal
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# contact the author directly for more information at: matthias@xcontrol.de
##########################################################################################

#Version 1.15

if [ ! "$#" == "5" ]; then
    	echo -e "\nWarning: Wrong command line arguments. \nUsage: ./check_qnap <hostname> <community> <part> <warning> <critical>\n \nParts are:  sysinfo, systemuptime, cpu, cputemp, freeram, diskused, temp, tmphd1, tmphd2, tmphd3 tmphd4, hdstatus, hd1status, hd2status, hd3status, hd4status and volstatus (volstatus = Raid Info)\nExample: ./check_qnap 127.0.0.1 public diskusage 80 95\n" && exit "3"
fi
strHostname=$1
strCommunity=$2
strpart=$3
strWarning=$4
strCritical=$5

# Check if QNAP is online
TEST=$(snmpstatus -v 1 $Hostname -c "$strCommunity" -t 5 -r 0 2>&1) 
# echo "Test: $TEST"; 
if [ "$TEST" == "Timeout: No Response from $strHostname" ]; then 
echo "CRITICAL: SNMP to $strHostname is not available"; 
exit 2; 
fi

# DISKUSAGE ---------------------------------------------------------------------------------------------------------------------------------------
if [ "$strpart" == "diskused" ]; then
	disk=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	free=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	UNITtest=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
	UNITtest2=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
        #echo $disk - $free - $GBtest - $GBtest2 

	if [ "$UNITtest" == "TB" ]; then
	 factor=$(echo "scale=0; 1000" | bc -l)
	else
	 factor=$(echo "scale=0; 1" | bc -l)
	fi

	if [ "$UNITtest2" == "TB" ]; then
	 factor2=$(echo "scale=0; 1000" | bc -l)
	else
	 factor2=$(echo "scale=0; 1" | bc -l)
	fi

	disk=$(echo "scale=0; $disk*$factor" | bc -l)
	free=$(echo "scale=0; $free*$factor2" | bc -l)
	
	#debug used=$(echo "scale=0; 9000*1000" | bc -l) 
	used=$(echo "scale=0; $disk-$free" | bc -l)
	
	PERC=$(echo "scale=0; $used*100/$disk" | bc -l)
	
	diskF=$(echo "scale=0; $disk/$factor" | bc -l)
	freeF=$(echo "scale=0; $free/$factor" | bc -l)
	usedF=$(echo "scale=0; $used/$factor" | bc -l)

	wdisk=$(echo "scale=0; $strWarning*$disk/100" | bc -l)
	cdisk=$(echo "scale=0; $strCritical*$disk/100" | bc -l)
	
	#OUTPUT="total:"$disk"$UNITtest - used:"$used"$UNITtest - free:"$free"$UNITtest2 =  $PERC%|Used=$PERC%;$strWarning;$strCritical;0;100"
        OUTPUT="total:"$diskF"$UNITtest - used:"$usedF"$UNITtest - free:"$freeF"$UNITtest2 =  $PERC%|Used=$used;$wdisk;$cdisk;0;$disk"
	
	if [ $PERC -ge $strCritical ]; then
		echo "CRITICAL: "$OUTPUT
		exit 2
	
	elif [ $PERC -ge $strWarning ]; then
		echo "WARNING: "$OUTPUT
		exit 1
	else 
		echo "OK: "$OUTPUT
		exit 0
	fi

	
# CPU ----------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "cpu" ]; then
    	CPU=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.1.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	OUTPUT="Load="$CPU"%|CPU load="$CPU"%;$strWarning;$strCritical;0;100" 

   	if [ $CPU -ge $strCritical ]; then
		echo "CRITICAL: "$OUTPUT
		exit 2

	elif [ $CPU -ge $strWarning ]; then
		echo "WARNING: "$OUTPUT
		exit 1

	else 
		echo "OK: "$OUTPUT
		exit 0
	fi

# CPUTEMP ----------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "cputemp" ]; then
    	TEMP0=$(snmpget -v1 -c "$strCommunity" $strHostname  .1.3.6.1.4.1.24681.1.2.5.0 | awk '{print $4}' | cut -c2-3)
	OUTPUT="CPU Temperature="$TEMP0"C|NAS CPUtermperature="$TEMP0"C;$strWarning;$strCritical;0;90"

    	if [ "$TEMP0" -ge "89" ]; then
            	echo "Cpu temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMP0 -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMP0 -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# Free RAM---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "freeram" ]; then
	TOTALRAM=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.2.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	FREERAM=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.3.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	
	let "USEDRAM=($TOTALRAM-$FREERAM)"
	
	let "RAMPERC=(100-($FREERAM*100)/$TOTALRAM)"
	
	OUTPUT="total:"$TOTALRAM"MB - used:"$USEDRAM"MB - free:"$FREERAM"MB = "$RAMPERC"%|Memory usage="$RAMPERC"%;$strWarning;$strCritical;0;100"

	if [ $RAMPERC -ge $strCritical ]; then
		echo "CRITICAL: "$OUTPUT
		exit 2

	elif [ $RAMPERC -ge $strWarning ]; then
		echo "WARNING: "$OUTPUT
		exit 1
	
	else echo "OK: "$OUTPUT
		exit 0

	fi

# System Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "temp" ]; then
    	TEMP0=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.6.0 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMP0"C|NAS termperature="$TEMP0"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMP0" -ge "59" ]; then
            	echo "Sytem temperatur to high!: "$OUTPUT
            	exit 2
    	else

            	if [ $TEMP0 -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMP0 -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# HD1 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd1temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.1 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD1 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "59" ]; then
            	echo "HDD1 temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMPHD -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMPHD -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# HD2 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd2temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.2 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD2 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "59" ]; then
            	echo "HDD2 temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMPHD -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMPHD -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# HD3 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd3temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.3 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD3 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "59" ]; then
            	echo "HDD3 temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMPHD -le "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMPHD -le "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# HD4 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd4temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.4 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD4 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "45" ]; then
            	echo "HDD4 temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMPHD -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMPHD -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

# Volume Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "volstatus" ]; then
    	Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.6.1 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

    	if [ "$Vol_Status" == "Ready" ]; then
            	echo OK: $Vol_Status
            	exit 0

    	elif [ "$Vol_Status" == "Rebuilding..." ]; then
            	echo "WARNING: "$Vol_Status
            	exit 1

    	else
            	echo "CRITICAL: "$Vol_Status
            	exit 2
    	fi

# HD Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hdstatus" ]; then

	hdnum=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')

        hdok=0
        hdnop=0
	
	for (( c=1; c<=$hdnum; c++ ))
	do
	   HD=$(snmpget -v1 -c "$strCommunity" -mALL "$strHostname" 1.3.6.1.4.1.24681.1.2.11.1.7.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	   
	   if [ "$HD" == "GOOD" ]; then
            	hdok=$(echo "scale=0; $hdok+1" | bc -l)
    	   elif [ "$HD" == "--" ]; then    	        
    	        hdnop=$(echo "scale=0; $hdnop+1" | bc -l)
    	   else
            	echo "HD Status: CRITICAL"
            	exit 2
    	   fi
	done

	echo "HS Status: OK Disk $hdok, Free Slot $hdnop"
	exit 0
	
# HD1 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd1status" ]; then
    	HD1=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.11.1.7.1 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

    	if [ "$HD1" == "GOOD" ]; then
            	echo OK: GOOD
            	exit 0
    	else
            	echo CRITICAL: ERROR
            	exit 2
    	fi

# HD2 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd2status" ]; then
    	HD2=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.11.1.7.2 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

    	if [ "$HD2" == "GOOD" ]; then
            	echo OK: GOOD
            	exit 0
    	else
            	echo CRITICAL: ERROR
            	exit 2
    	fi

# HD3 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd3status" ]; then
    	HD3=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.3 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
    	if [ "$HD3" == "GOOD" ]; then
            	echo OK: GOOD
            	exit 0
    	else
            	echo CRITICAL: ERROR
            	exit 2
    	fi

# HD4 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd4status" ]; then
    	HD4=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.4 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
    	if [ "$HD4" == "GOOD" ]; then
            	echo OK: GOOD
            	exit 0
    	else
            	echo CRITICAL: ERROR
            	exit 2
    	fi

# System Uptime----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "systemuptime" ]; then
    	netuptime=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.2.1.1.3.0 | awk '{print $5, $6, $7, $8}')
    	sysuptime=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.2.1.25.1.1.0 | awk '{print $5, $6, $7, $8}') 
    	
            	echo System Uptime $sysuptime - Network Uptime $netuptime
            	exit 0

# System Info------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "sysinfo" ]; then
    	model=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.12.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
    	hdnum=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')
    	name=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.13.0  | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
    	
            	echo NAS $name Model $model, Max HD number $hdnum
            	exit 0
    	
#----------------------------------------------------------------------------------------------------------------------------------------------------
else
    	echo -e "\nUnknown Part!" && exit "3"
fi
exit 0
