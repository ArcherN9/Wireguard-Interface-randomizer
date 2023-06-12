#!/bin/bash

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# we don't want to continue execution of the script if something is broken. This may potentially
# complicate IP routing table entries which may require manual intervention to fix thereafter.
set -e

# Declare global variables here
# Modify the variables in this section in conformity with the naming convention of your Mullvad
# configuration files in /etc/wireguard
mullvadVpnInterfaceRegex="wg.*"
wireguardConfigurationDirectory="/opt/etc/wireguard.d/"
connectedWireguardConfiguration=""

# A method to retrieve the current connected Mullvad interface.
checkMullvadConnectivity() {
	# Check if Mullvad VPN is already connected.
	connectedWireguardConfiguration=$(wg| grep wg | grep -v wg21 | cut -c 12-16)
	# Return an arbitrary integer value | This value is not checked right now
	return 0
}

case $1 in
	toggle)
            connectedStatus=$(curl -sSk https://am.i.mullvad.net/connected)
	    if [[ "$connectedStatus" == *"("* ]]; then    
	      #status=$(echo $connectedStatus | cut -d "(" -f 1 | sed 's/ *$//g')
	      STOP="true"
	    else
	      #echo "$(echo $connectedStatus | cut -d "." -f 1 | sed 's/ *$//g')." #1> /tmp/.checkip
	      STOP="false"
	    fi
	;;
	stop)
		STOP="true"
	;;
	status)
		curl -sSk https://am.i.mullvad.net/connected
		exit
	;;
	checkIP)
		# This shell script is used to keep a track of which server the VPN is current connected to 
		# in a format that is easily readable. Let's face it,  mullvad-lv1 isn\'t very descriptive.
		# This script on its own is a little useless but particularly useful when queried from an 
		# external system.

		# A good use case to use this script with is in the shortcuts iOS application or with IFTTT to query the 
		# client that runs the VPN to check which server it is connected to. My previous implementation 
		# was to keep this logic on the shortcuts application but realised that executing all curl commands
		# may take sometime and I did not always have the patience to wait for a response.

		# Retrieve the current status of the VPN client. The general output of this is
		# You are connected to Mullvad (server us107-wireguard). Your IP address is 86.106.121.248
		# We strip out the sections we don't require and use the rest.
		connectedStatus=$(curl -sSk https://am.i.mullvad.net/connected)
		if [[ "$connectedStatus" == *"("* ]]; then

    		#curl https://am.i.mullvad.net/connected
    		#You are connected to Mullvad (server ca14-wireguard). Your IP address is 89.36.78.216
   		#curl https://am.i.mullvad.net/ip
		#89.36.78.216
		#curl https://am.i.mullvad.net/city
    		#Montreal
   		#curl https://am.i.mullvad.net/country
    		#Canada
    		#curl https://am.i.mullvad.net/json
    		#{
    		#  "ip": "89.36.78.216",
    		#  "country": "Canada",
    		#  "city": "Montreal",
    		#  "longitude": -73.5525,
    		#  "latitude": 45.5053,
    		#  "mullvad_exit_ip": true,
    		#  "mullvad_exit_ip_hostname": "ca14-wireguard",
    		#  "mullvad_server_type": "WireGuard",
    		#  "blacklisted": {
    		#    "blacklisted": false,
    		#    "results": [
    		#      {
    		#        "name": "Project Honeypot",
    		#        "link": "https://www.projecthoneypot.org/about_us.php",
    		#        "blacklisted": false
    		#      },
    		#      {
    		#        "name": "Spamhaus",
    		#        "link": "https://www.spamhaus.org/organization/",
    		#        "blacklisted": false
    		#      }
    		#    ]
    		#  },
    		#  "organization": "M247"
    		#}

			status=$(echo $connectedStatus | cut -d "(" -f 1 | sed 's/ *$//g')
			ip=$(echo $connectedStatus | cut -d "." -f 2-5 | sed 's/ *$//g')

			# This returns a country name.
			country=$(curl --silent https://am.i.mullvad.net/country | sed 's/ *$//g')

			# This returns a city name
			city=$(curl --silent https://am.i.mullvad.net/city | sed 's/ *$//g')

			echo "$status server in $city, $country.$ip" #1> /tmp/.checkip
		else
			echo "$(echo $connectedStatus | cut -d "." -f 1 | sed 's/ *$//g')." #1> /tmp/.checkip
		fi
		exit
	;;

	start)
		STOP="false"
	;;
	restart)
		STOP="false"
	;;
	*) 
		echo "Usage: $0 {status|toggle [policy]|stop|start [policy]|restart [policy]}"
		exit
	;;
esac

checkMullvadConnectivity

# Debug log
# echo " ip addr command returned $connectedWireguardConfiguration"

# Extract the wireguard configuration list that is available in /etc/wireguard
# newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex")

if [ -z "$(ls $wireguardConfigurationDirectory | grep $mullvadVpnInterfaceRegex | grep .conf$ | grep -v "wg21.conf")" ]; then
	echo "Wireguard Configuration files are missing. Expecting filed matching regex $mullvadVpnInterfaceRegex in $wireguardConfigurationDirectory. Exiting."
fi
if [ "$STOP" == "true" ];then
	if [[ -n "$connectedWireguardConfiguration" ]]; then
		echo "Disconnecting from $connectedWireguardConfiguration"
		echo "Stopping $connectedWireguardConfiguration"
		/opt/bin/wg_manager stop $interface

	# Satisfies this condition if a connected interface was not found.
	#elif [[ -z "$connectedWireguardConfiguration" ]]; then
		#echo "Not currently connected to any VPN."
	fi

	curl -sSk https://am.i.mullvad.net/connected
	exit
else
	while : ; do
		if [[ -n "$connectedWireguardConfiguration" ]]; then
			fileCount=$(ls $wireguardConfigurationDirectory | grep -v "$connectedWireguardConfiguration".conf$ | grep .conf$ | grep -v "wg21.conf" | grep $mullvadVpnInterfaceRegex | wc -l)
			if [ "$fileCount" ==  0  ];then
				echo "Not enough config files to randomize. Reconnecting to $connectedWireguardConfiguration"
			else
				newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep -v "$connectedWireguardConfiguration".conf$ | grep .conf$ | grep -v "wg21.conf" | grep $mullvadVpnInterfaceRegex)
				newWireguardConfigurationListCount=$(ls $wireguardConfigurationDirectory | grep -v "$connectedWireguardConfiguration".conf$ | grep .conf$ | grep -v "wg21.conf" | grep $mullvadVpnInterfaceRegex | wc -l)
			fi
		elif [[ -z "$connectedWireguardConfiguration" ]]; then
			newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep $mullvadVpnInterfaceRegex | grep .conf$ | grep -v "wg21.conf")
			newWireguardConfigurationListCount=$(ls $wireguardConfigurationDirectory | grep $mullvadVpnInterfaceRegex | grep .conf$ | grep -v "wg21.conf" | wc -l)
		fi
		# Pick a wireguard interface at random to connect to next
		if [ "$fileCount" ==  0  ]; then
			newWireguardConfiguration=$connectedWireguardConfiguration
		else
			random=$(awk -v count="$newWireguardConfigurationListCount" 'BEGIN { srand(); print int( rand() * (count-1)+1);}')
			newWireguardConfiguration=$(echo "$newWireguardConfigurationList" | awk -v random="$random" 'FNR==random {print $1}' | grep -oE 'wg[0-9]{2,3}')
		fi
		# Satisfies this condition if a connected interface was found.
		if [[ -n "$connectedWireguardConfiguration" ]]; then
			echo "System is currently connected to $connectedWireguardConfiguration and will reconnect to $newWireguardConfiguration"
			echo "Stopping $connectedWireguardConfiguration"
			/opt/bin/wg_manager stop $connectedWireguardConfiguration
			sleep 5
			/opt/bin/wg_manager start $newWireguardConfiguration $2

		# Satisfies this condition if a connected interface was not found.
		elif [[ -z "$connectedWireguardConfiguration" ]]; then
			echo "System will attempt to connect to $newWireguardConfiguration"
			/opt/bin/wg_manager start $newWireguardConfiguration $2
		fi
		sleep 2
		checkMullvadConnectivity
		if [[ -n "$connectedWireguardConfiguration" ]]; then
			echo "Connected to $connectedWireguardConfiguration"
		elif [[ -z "$connectedWireguardConfiguration" ]]; then
			echo "You are not connected."
		fi
		IP=$(curl -sSk https://am.i.mullvad.net/connected)
		DELIMITER=':'
		if [[ "$IP" == *"$DELIMITER"* ]]; then
			echo "$IP"
			echo "Connected to IPV6. Reconnecting."
			checkMullvadConnectivity

			# Debug log
			# echo " ip addr command returned $connectedWireguardConfiguration"

			# Extract the wireguard configuration list that is available in /etc/wireguard
			# newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex")
			#if [[ -n "$connectedWireguardConfiguration" ]]; then
			#	newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep -v "$connectedWireguardConfiguration".conf$ | grep --word-regexp "$mullvadVpnInterfaceRegex" | grep conf$)

			#elif [[ -z "$connectedWireguardConfiguration" ]]; then
			#	newWireguardConfigurationList=$(ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex" | grep conf$)
			#fi
		else
			#curl -sSk https://am.i.mullvad.net/connected
			exit
		fi
		[[ "$IP" == *"$DELIMITER"* ]] || break
	done
fi

