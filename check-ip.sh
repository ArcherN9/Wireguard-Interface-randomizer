#!/bin/bash
curl -sSk --ipv4 https://am.i.mullvad.net/connected

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
#connectedStatus=$(curl --silent https://am.i.mullvad.net/connected)
#if [[ "$connectedStatus" == *"("* ]]; then
#	status=$(echo $connectedStatus | cut -d "(" -f 1 | sed 's/ *$//g')
#	ip=$(echo $connectedStatus | cut -d "." -f 2-5 | sed 's/ *$//g')
#
#	# This returns a country name.
#	country=$(curl --silent https://am.i.mullvad.net/country | sed 's/ *$//g')
#
#	# This returns a city name
#	city=$(curl --silent https://am.i.mullvad.net/city | sed 's/ *$//g')
#
#	echo "$status server in $city, $country.$ip" # 1> /tmp/.checkip
#else
#	echo "$(echo $connectedStatus | cut -d "." -f 1 | sed 's/ *$//g')."# 1> /tmp/.checkip
#fi
