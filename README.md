# About

Check NAS QNAP from Nagios or similar monitoring software

# Usage

Enable SNMP on QNAP NAS appliance and use this script with Nagios

Add the following configuration into Nagios Command file

	define command{
		command_name 	check_qnap
		command_line 	$USER1$/check_qnap3.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$
	}

Parameters:

$ARG1$ - Nas HostAddress

$ARG2$ - Snmp Community Name with readonly rights

$ARG3$ - Type of Check (part)

$ARG4$ - Warning  (mandatory for some check use simbolic value like 1)

$ARG5$ - Critical (mandatory for some check use simbolic value like 1)


# Contributing

Please feel free to fork and collaborate to this little but usefull project.

# Parts of script to improve

- Power unit check - (let me know if on your device work)
- HDSTATUS check smart and temperature foreach disk and performance output (rewrite this)
- Improve Performance output for command
- Check script input parameters
- Disk usage to be rewrite

# Test
This script was tested with:
- QNAP model TS-853U-RP (with 4 disk)
- QNAP model TS-859U+ (by Omar S. Ramirez thanks for your help)
- QNAP model TS-212 and TS-231P (by github user mir07 Michael Rasmussen)
- QNAP Model TS-EC1280U, Firmware 4.2.2 (Thanks to AndresCidoncha)
- QNAP Model TS-459 Pro+, Firmware 4.2.6, Max HD number 4, No. Volume 1
- QNAP Model TS-1263U-RP, Firmware 4.3.3, Max HD number 12, No. Volume 1

Nicola
