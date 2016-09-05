#About
Check NAS QNAP from Nagios or similar monitoring software
Enable snmp on QNAP Nas appliance and use this with Nagios

Add the following configuration into Nagios Command file
define command{
	command_name 	check_qnap
	command_line 	$USER1$/check_qnap3.sh $HOSTADDRESS$ $ARG1$ $ARG2$ $ARG3$ $ARG4$	
}


# Contributing
Please feel free to fork, and collaborate to this little but usefull project.

#Point to be improve
- HD Temperature and Status for each disk we have to automate this
- Improve Performance output for most command

Nicola
