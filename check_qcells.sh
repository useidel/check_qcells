#!/bin/sh
# check_qcells plugin for Nagios
# Written by Udo Seidel
#
# Description:
#
# This plugin will check the battery SOC of a PV plant one
#

CUSTOMWARNCRIT=0 # no external defined warning and critical levels
WARNLEVEL=8 # predefined Warning level
CRITLEVEL=6 # predefined Critical level
MYAPIKEY=XXXXXXXXXXXXXXXXXXXXXXXX


# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

EXITSTATUS=$STATE_UNKNOWN #default


PROGNAME=`basename $0`

print_usage() {
	echo 
	echo " This plugin will check the battery SOC of a PV plant one"
	echo 
	echo 
        echo " Usage: $PROGNAME -<h|n> -w <warning> -c <critical>"
        echo
        echo "   -n: Inverter S/N"
        echo "   -w: WARNING percentage"
        echo "   -c: CRITICAL percentage"
	echo
        echo "   -h: print this help"
	echo 
}

if [ "$#" -lt 2 ]; then
	print_usage
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi

check_tools()
{
EXITMESSAGE=""
# run a basic bc to see if it works
echo "2+2" | bc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	EXITMESSAGE="Please install bc"
	EXITSTATUS=$STATE_UNKNOWN
	echo $EXITMESSAGE
	exit $EXITSTATUS
fi

which curl > /dev/null 2>&1
if [ $? -ne 0 ]; then
	EXITMESSAGE="Please install curl"
	echo $EXITMESSAGE
	exit $EXITSTATUS
fi
}

get_battery_soc()
{
# Fetch the battery soc
# QCELLS -> https://qhome-ess-g3.q-cells.eu/proxyApp/proxy/api/getRealtimeInfo.do?tokenId=APIKEY&sn=INVERTER_SN
# SOLAX -> https://www.solaxcloud.com/proxyApp/proxy/api/getRealtimeInfo.do?tokenId=APIKEY&sn=INVERTER_SN
#
MYBATTSOC=`curl -X GET "https://qhome-ess-g3.q-cells.eu/proxyApp/proxy/api/getRealtimeInfo.do?tokenId=${MYAPIKEY}&sn=${MYINVERTER}"|awk -F"soc" '{ print $2 }'|cut -f1 -d","|cut -f2 -d":"|cut -f1 -d"."`
# the variable will be empty in case of missing file or access to it
echo $MYBATTSOC | grep '[0-9]' > /dev/null
if [ $? -ne 0 ]; then
	echo " Battery problems or missing access to it"
	echo " Please x-check"
	EXITSTATUS=$STATE_UNKNOWN
	exit $EXITSTATUS
fi
}

check_warning_critical() 
{
if [ $CUSTOMWARNCRIT -ne 0 ]; then
        # check if the levels are integers
        echo $WARNLEVEL | awk '{ exit ! /^[0-9]+$/ }'
        if [ $? -ne 0 ]; then
                echo " warning level ($WARNLEVEL) is not an integer"
                exit $STATE_UNKNOWN
        fi
        echo $CRITLEVEL | awk '{ exit ! /^[0-9]+$/ }'
        if [ $? -ne 0 ]; then
                echo " critical level ($CRITLEVEL) is not an integer"
                exit $STATE_UNKNOWN
        fi
        if [ $WARNLEVEL -lt $CRITLEVEL ]; then
                echo
                echo " The value for critical level has to be equal or lower than the one for warning level"
                echo " Your values are: critcal ($CRITLEVEL) and warning ($WARNLEVEL)"
                echo
                exit $STATE_UNKNOWN
        fi
fi
}

compare_percentage(){
# Take action, i.e. set the EXITSTATUS
if [ $MYBATTSOC -gt $WARNLEVEL ];  # more than Warninglevel days 
then
	echo "OK - Battery is still at $MYBATTSOC"
	EXITSTATUS=$STATE_OK
else
	if [ $MYBATTSOC -gt $CRITLEVEL ]; # more than Criticallevel percentag 
	then
		echo "WARNING - Battery is at $MYBATTSOC"
		EXITSTATUS=$STATE_WARNING
	else
		echo "CRITICAL - Battery is at $MYBATTSOC"
		EXITSTATUS=$STATE_CRITICAL	    # less than Criticallevel percentage 
	fi
fi
}

while getopts "hn:w:c:" OPT
do		
	case "$OPT" in
	h)
		print_usage
		exit $STATE_UNKNOWN
		;;
	n)
		MYINVERTER=$2
		;;
        w)
                WARNLEVEL=$4
                CUSTOMWARNCRIT=1
                ;;
        c)
                [ $CUSTOMWARNCRIT -eq 1 ] && CRITLEVEL=$6 || CRITLEVEL=$4
                CUSTOMWARNCRIT=1
		;;
	*)
		print_usage
		exit $STATE_UNKNOWN
	esac
done

check_tools
get_battery_soc $MYINVERTER
check_warning_critical
compare_percentage
exit $EXITSTATUS
