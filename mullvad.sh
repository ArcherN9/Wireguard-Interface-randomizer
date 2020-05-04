#!/usr/bin/env bash

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# we don't want to continue execution of the script if something is broken. This may potentially
# complicate IP routing table entries which may require manual intervention to fix thereafter.
set -e

# Declare global variables here
# Modify the variables in this section in conformity with the naming convention of your Mullvad
# configuration files in /etc/wireguard
mullvadVpnInterfaceRegex="mullvad-\w*"
wireguardConfigurationDirectory="/etc/wireguard/"
connectedWireguardConfiguration=""

# A method to retrieve the current connected Mullvad interface.
checkMullvadConnectivity() {
	# Check if Mullvad VPN is already connected.
	connectedWireguardConfiguration=$(ip addr | grep --word-regexp "$1" | cut -d " " -f 2 | tr -d ":")
	# Return an arbitrary integer value | This value is not checked right now
	return 0
}

checkMullvadConnectivity "$mullvadVpnInterfaceRegex"

# Debug log
# echo " ip addr command returned $connectedWireguardConfiguration"

# Extract the wireguard configuration list that is available in /etc/wireguard
newWireguardConfigurationList=$(sudo ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex")

# Pick a wireguard interface at random to connect to next
newWireguardConfiguration=$(shuf -n 1 -e $newWireguardConfigurationList)

# Satisfies this condition if a connected interface was found.
if [[ -n "$connectedWireguardConfiguration" ]]; then
	
	echo "" # Blank space for formatting
	echo "Cron is re-configuring the connected VPN."
	echo "System is currently connected to $connectedWireguardConfiguration and switching over to $newWireguardConfiguration"

	sudo wg-quick down $connectedWireguardConfiguration 2> /dev/null
	sudo wg-quick up $wireguardConfigurationDirectory$newWireguardConfiguration 2> /dev/null

	checkMullvadConnectivity $mullvadVpnInterfaceRegex
	echo $connectedWireguardConfiguration

# Satisfies this condition if a connected interface was not found.
elif [[ -z "$connectedWireguardConfiguration" ]]; then
	
	echo "" # Blank space for formatting
	echo "Cron is configuring the connected VPN."
	echo "System will attempt to connect to $newWireguardConfiguration"

	sudo wg-quick up $wireguardConfigurationDirectory$newWireguardConfiguration 2> /dev/null

	checkMullvadConnectivity $mullvadVpnInterfaceRegex
	echo $connectedWireguardConfiguration
fi