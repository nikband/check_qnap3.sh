#!/bin/bash
############################# Written and Manteined by Nicola Bandini     ###############
############################# Created and written by Matthias Luettermann ###############
############################# finetuning by primator@gmail.com
############################# finetuning by n.bandini@gmail.com
############################# with code by Tom Lesniak
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
#Version 1.21
plgVer=1.21

if [ ! "$#" == "5" ]; then
        echo
        echo "Check_QNAP3 "$plgVer
        echo
    	echo "Warning: Wrong command line arguments."
        echo
	echo "Usage: ./check_qnap <hostname> <community> <part> <warning> <critical>"
        echo
	echo "Parts are: sysinfo, systemuptime, temp, cpu, cputemp, freeram, powerstatus, fans, diskused, hdstatus, hd#status, hd#temp, volstatus (Raid Volume Status), vol#status"
        echo
	echo "hdstatus shows status & temp; volstatus check all vols and vols space; powerstatus check power supply"
        echo "<#> is 1-8 for hd, 1-5 for vol"
	echo
        echo " Example for diskusage: ./check_qnap3.sh 127.0.0.1 public diskused 80 95"
	echo
	echo " Example for volstatus: ./check_qnap3.sh 127.0.0.1 public volstatus 15 10"
	echo "                        critical and warning value are releted to free disk space"
	echo
	echo " Example for fans: ./check_qnap3.sh 127.0.0.1 public fans 2000 1900"
	echo "                   critical and warning are minimum speed in rpm for fans"
	echo
        exit 3
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
        #echo $disk - $free - $UNITtest - $UNITtest2 

	if [ "$UNITtest" == "TB" ]; then
	 factor=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest" == "GB" ]; then
	 factor=$(echo "scale=0; 100" | bc -l)	 
	else
	 factor=$(echo "scale=0; 1" | bc -l)
	fi

	if [ "$UNITtest2" == "TB" ]; then
	 factor2=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest2" == "GB" ]; then
	 factor2=$(echo "scale=0; 100" | bc -l)
	else
	 factor2=$(echo "scale=0; 1" | bc -l)
	fi
	
	#echo $factor - $factor2
	disk=$(echo "scale=0; $disk*$factor" | bc -l)
	free=$(echo "scale=0; $free*$factor2" | bc -l)
	
	#debug used=$(echo "scale=0; 9000*1000" | bc -l) 
	used=$(echo "scale=0; $disk-$free" | bc -l)
	
	#echo $disk - $free - $used
	PERC=$(echo "scale=0; $used*100/$disk" | bc -l)
	
	diskF=$(echo "scale=0; $disk/$factor" | bc -l)
	freeF=$(echo "scale=0; $free/$factor" | bc -l)
	usedF=$(echo "scale=0; $used/$factor" | bc -l)

	#wdisk=$(echo "scale=0; $strWarning*$disk/100" | bc -l)
	#cdisk=$(echo "scale=0; $strCritical*$disk/100" | bc -l)
	
        OUTPUT="Total:"$diskF"$UNITtest - Used:"$usedF"$UNITtest - Free:"$freeF"$UNITtest2 - Used Space: $PERC%|Used=$PERC;$strWarning;$strCritical;0;100"
	
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
	OUTPUT="CPU Load="$CPU"%|CPU load="$CPU"%;$strWarning;$strCritical;0;100" 

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
	
	OUTPUT="Total:"$TOTALRAM"MB - Used:"$USEDRAM"MB - Free:"$FREERAM"MB = "$RAMPERC"%|Memory usage="$RAMPERC"%;$strWarning;$strCritical;0;100"

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
	OUTPUT="Temperature="$TEMP0"C|NAS termperature="$TEMP0"C;$strWarning;$strCritical;0;80"

    	if [ "$TEMP0" -ge "89" ]; then
            	echo "System temperatur to high!: "$OUTPUT
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

# HD4 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd4temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.4 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD4 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "59" ]; then
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

# HD5 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd5temp" ]; then
    	TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.5 | awk '{print $4}' | cut -c2-3)
	OUTPUT="Temperature="$TEMPHD"C|HDD5 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

    	if [ "$TEMPHD" -ge "59" ]; then
            	echo "HDD5 temperatur to high!: "$OUTPUT
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

# HD6 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd6temp" ]; then
        TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.6 | awk '{print $4}' | cut -c2-3)
        OUTPUT="Temperature="$TEMPHD"C|HDD6 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

        if [ "$TEMPHD" -ge "59" ]; then
                echo "HDD6 temperatur to high!: "$OUTPUT
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

# HD7 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd7temp" ]; then
        TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.7 | awk '{print $4}' | cut -c2-3)
        OUTPUT="Temperature="$TEMPHD"C|HDD7 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

        if [ "$TEMPHD" -ge "59" ]; then
                echo "HDD7 temperatur to high!: "$OUTPUT
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

# HD8 Temperature---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd8temp" ]; then
        TEMPHD=$(snmpget -v1 -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.11.1.3.8 | awk '{print $4}' | cut -c2-3)
        OUTPUT="Temperature="$TEMPHD"C|HDD8 termperature="$TEMPHD"C;$strWarning;$strCritical;0;60"

        if [ "$TEMPHD" -ge "59" ]; then
                echo "HDD8 temperatur to high!: "$OUTPUT
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

# Volume 1 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "vol1status" ]; then
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

# Volume 2 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "vol2status" ]; then
        Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.6.2 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

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

# Volume 3 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "vol3status" ]; then
        Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.6.3 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

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

# Volume 4 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "vol4status" ]; then
        Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.6.4 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

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

# Volume 5 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "vol5status" ]; then
        Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.6.5 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

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

# HD5 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd5status" ]; then
        HD5=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.5 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        if [ "$HD5" == "GOOD" ]; then
                echo OK: GOOD
                exit 0
        else
                echo CRITICAL: ERROR
                exit 2
        fi

# HD6 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd6status" ]; then
        HD6=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.6 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        if [ "$HD6" == "GOOD" ]; then
                echo OK: GOOD
                exit 0
        else
                echo CRITICAL: ERROR
                exit 2
        fi

# HD7 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd7status" ]; then
        HD7=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.7 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        if [ "$HD7" == "GOOD" ]; then
                echo OK: GOOD
                exit 0
        else
                echo CRITICAL: ERROR
                exit 2
        fi

# HD8 Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hd8status" ]; then
        HD8=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.3.11.1.7.8 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        if [ "$HD8" == "GOOD" ]; then
                echo OK: GOOD
                exit 0
        else
                echo CRITICAL: ERROR
                exit 2
        fi


# HD Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "hdstatus" ]; then

	hdnum=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')

        hdok=0
        hdnop=0
	output_crit=""
	
	for (( c=1; c<=$hdnum; c++ ))
	do
	   HD=$(snmpget -v1 -c "$strCommunity" -mALL "$strHostname" 1.3.6.1.4.1.24681.1.2.11.1.7.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	   
	   if [ "$HD" == "GOOD" ]; then
            	hdok=$(echo "scale=0; $hdok+1" | bc -l)
    	   elif [ "$HD" == "--" ]; then    	        
    	        hdnop=$(echo "scale=0; $hdnop+1" | bc -l)
    	   else
                output_crit=${output_crit}" Disk ${c}"
    	   fi
	done

    if [ -n "$output_crit" ]
    then
        echo "CRITICAL: ${output_crit}"
        exit 2
    else
	echo "OK: Online Disk $hdok, Free Slot $hdnop"
	exit 0    
    fi

# Volume Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "volstatus" ]; then
     ALLOUTPUT=""
     PERFOUTPUT=""
     WARNING=0
     CRITICAL=0
     VOL=1
     VOLCOUNT=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}')

     while [ "$VOL" -le "$VOLCOUNT" ]; do
        Vol_Status=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.17.1.6.$VOL | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

        if [ "$Vol_Status" == "Ready" ]; then
                VOLSTAT="OK: $Vol_Status"

        elif [ "$Vol_Status" == "Rebuilding..." ]; then
                VOLSTAT="WARNING: $Vol_Status"
                WARNING=1
        else
                VOLSTAT="CRITICAL: $Vol_Status"
                CRITICAL=1
        fi

        VOLCAPACITY=0
        VOLFREESIZE=0
        VOLPCT=0

        VOLCAPACITY=$(snmpget -v2c -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.17.1.4.$VOL | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        VOLFREESIZE=$(snmpget -v2c -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.17.1.5.$VOL | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        UNITtest=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.4.$VOL | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
	UNITtest2=$(snmpget -v1 -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.5.$VOL | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')

	if [ "$UNITtest" == "TB" ]; then
	 factor=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest" == "GB" ]; then
	 factor=$(echo "scale=0; 100" | bc -l)
	else
	 factor=$(echo "scale=0; 1" | bc -l)
	fi

	if [ "$UNITtest2" == "TB" ]; then
	 factor2=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest2" == "GB" ]; then
	 factor2=$(echo "scale=0; 100" | bc -l)
	else
	 factor2=$(echo "scale=0; 1" | bc -l)
	fi
	
	VOLCAPACITYF=$(echo "scale=0; $VOLCAPACITY*$factor" | bc -l)
	VOLFREESIZEF=$(echo "scale=0; $VOLFREESIZE*$factor2" | bc -l)

        VOLPCT=`echo "($VOLFREESIZEF*100)/$VOLCAPACITYF" | bc`

        if [ "$VOLPCT" -le "$strCritical" ]; then
                VOLPCT="CRITICAL: $VOLPCT"
                CRITICAL=1
        elif [ "$VOLPCT" -le "$strWarning" ]; then
                VOLPCT="WARNING: $VOLPCT"
                WARNING=1
        fi

        if [ "$VOL" -lt "$VOLCOUNT" ]; then
           ALLOUTPUT="${ALLOUTPUT}Volume #${VOL}: $VOLSTAT, Total Size (bytes): $VOLCAPACITY $UNITtest, Free: $VOLFREESIZE $UNITtest2 (${VOLPCT}%), "
        else
           ALLOUTPUT="${ALLOUTPUT}Volume #${VOL}: $VOLSTAT, Total Size (bytes): $VOLCAPACITY $UNITtest, Free: $VOLFREESIZE $UNITtest2 (${VOLPCT}%)"
        fi
		
	#Performance Data
        if [ $VOL -gt 1 ]; then
          PERFOUTPUT=$PERFOUTPUT" "
        fi
        PERFOUTPUT=$PERFOUTPUT"FreeSize_Volume-$VOL=${VOLPCT}%;$strWarning;$strCritical;0;100"

        VOL=`expr $VOL + 1`
     done

     echo $ALLOUTPUT"|"$PERFOUTPUT

     if [ $CRITICAL -eq 1 ]; then
        exit 2
     elif [ $WARNING -eq 1 ]; then
        exit 1
     else
        exit 0
     fi
     
# Power Supply Status  ----------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "powerstatus" ]; then
     ALLOUTPUT=""
     WARNING=0
     CRITICAL=0
     PS=1
     COUNT=$(snmpget -v1 -c "$strCommunity" $strHostname .1.3.6.1.4.1.24681.1.4.1.1.1.1.3.1.0 | awk '{print $4}')
     while [ "$PS" -le "$COUNT" ]; do
        STATUS=$(snmpget -v1 -c "$strCommunity" $strHostname .1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.4.$PS | awk '{print $4}')
        if [ "$STATUS" -eq "0" ]; then
                PSSTATUS="OK: GOOD"
        else
                PSSTATUS="CRITICAL: ERROR"
                CRITICAL=1
        fi
        if [ "$PS" -lt "$COUNT" ]; then
           ALLOUTPUT="${ALLOUTPUT}Power Supply #${PS} - $PSSTATUS\n"
        else
           ALLOUTPUT="${ALLOUTPUT}Power Supply #${PS} - $PSSTATUS"
        fi
        PS=`expr $PS + 1`
     done

     echo $ALLOUTPUT

     if [ $CRITICAL -eq 1 ]; then
        exit 2
     elif [ $WARNING -eq 1 ]; then
        exit 1
     else
        exit 0
     fi

# Fan Status----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "fans" ]; then
     ALLOUTPUT=""
     PERFOUTPUT=""
     WARNING=0
     CRITICAL=0
     FAN=1
     FANCOUNT=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.14.0 | awk '{print $4}')
     while [ "$FAN" -le "$FANCOUNT" ]; do
        FANSPEED=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.15.1.3.$FAN | awk '{print $4}' | cut -c 2- )

	#Performance data
	if [ $FAN -gt 1 ]; then
		PERFOUTPUT=$PERFOUTPUT" "
	fi
	PERFOUTPUT=$PERFOUTPUT"Fan-$FAN=$FANSPEED;$strWarning;$strCritical" 

        if [ "$FANSPEED" == "" ]; then
                FANSTAT="CRITICAL: $FANSPEED RPM"
                CRITICAL=1
		
        elif [ "$FANSPEED" -le "$strCritical" ]; then
                FANSTAT="CRITICAL: $FANSPEED RPM"
                CRITICAL=1

        elif [ "$FANSPEED" -le "$strWarning" ]; then
                FANSTAT="WARNING: $FANSPEED RPM"
                WARNING=1
        else
                FANSTAT="OK: $FANSPEED RPM"
        fi

        if [ "$FAN" -lt "$FANCOUNT" ]; then
           ALLOUTPUT="${ALLOUTPUT}Fan #${FAN}: $FANSTAT, "
        else
           ALLOUTPUT="${ALLOUTPUT}Fan #${FAN}: $FANSTAT"
        fi

        FAN=`expr $FAN + 1`
     done

     echo $ALLOUTPUT"|"$PERFOUTPUT

     if [ $CRITICAL -eq 1 ]; then
        exit 2
     elif [ $WARNING -eq 1 ]; then
        exit 1
     else
        exit 0
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
	VOLCOUNT=$(snmpget -v1 -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}')
	name=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.13.0  | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')
	firmware=$(snmpget -v1 -c "$strCommunity" "$strHostname"  .1.3.6.1.2.1.47.1.1.1.1.9.1 | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')

	echo NAS $name Model $model, Firmware $firmware, Max HD number $hdnum, No. Volume $VOLCOUNT
	exit 0

#----------------------------------------------------------------------------------------------------------------------------------------------------
else
    	echo -e "\nUnknown Part!" && exit "3"
fi
exit 0
