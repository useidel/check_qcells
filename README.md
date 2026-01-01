# check_qcells

A very simply Nagios/Icinga plugin to check the SOC of a PV plant battery.
The required input is the serial number of the invertern. It also needs an API access token which - for now - must be hard-coded in the script. The current design requires that this API is stored in clear text somewhere. Either in this script or as part of the Icinga/NRPE configuration or in some wrapper items. 

Some of the performed checks require additional tools to be installed: bc and curl.

DEFAULT: It will trigger a warning if the battery SOC is below 8% but still more 5%. Once it is below 6% a critical message is triggered.


````
$ ./check_qcells.sh 

 This plugin will check the battery SOC of a PV plant one


 Usage: check_qcells.sh -<h|n> -w <warning> -c <critical>

   -n: Inverter S/N
   -w: WARNING percentage
   -c: CRITICAL percentage

   -h: print this help

$
````
