#!/bin/bash

/home/pi/WaitForInternet.sh

# Check if another instance of script is running
pidof -o %PPID -x "$0" >/dev/null && echo "ERROR: Script $0 already running" && exit 1
echo $$ > /run/Mullvad.pid

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# we don't want to continue execution of the script if something is broken. This may potentially
# complicate IP routing table entries which may require manual intervention to fix thereafter.
#set -e

# Declare global variables here
# Modify the variables in this section in conformity with the naming convention of your Mullvad
# configuration files in /etc/wireguard
mullvadVpnInterfaceRegex="mullvad-\w*"
wireguardConfigurationDirectory="/etc/wireguard/"
connectedWireguardConfiguration=""

# A method to retrieve the current connected Mullvad interface.
checkWireguardConnectivity() 
{
  # Check if Mullvad VPN is already connected.
  #connectedWireguardConfiguration=$(ip addr | grep --word-regexp "$1" | cut -d " " -f 2 | tr -d ":")
  connectedWireguardConfiguration=$(wg| grep mullvad | grep -v wg0 | sed "s/interface:// ")
  # Return an arbitrary integer value | This value is not checked right now
  return 0
}

checkMullvadConnectivity()
{
  response=$(curl --max-time 3 --connect-timeout 3  --write-out %{http_code} --silent --output /dev/null https://am.i.mullvad.net/connected)

  if [ "$response" = "200" ]; then
     echo "Connection is healthy"
     return 0
  else
     echo "Connection is not healthy (response code - $response )"
     if [ "$1" = true ]; then
         exit 1
     fi
  fi
}

case $1 in
  toggle)
      connectedStatus=$(curl -sSk https://ipv4.am.i.mullvad.net/connected)
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
    curl -sSk --ipv4 --max-time 3 --connect-timeout 3 https://ipv4.am.i.mullvad.net/connected
    curl -sSk --ipv4 --max-time 3 --connect-timeout 3 https://ipinfo.io
    exit
  ;;
  #checkIP)
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
    #connectedStatus=$(curl -sSk --ipv4 --connect-timeout 5 https://ipv4.am.i.mullvad.net/connected)
    #if [[ "$connectedStatus" == *"("* ]]; then

    #curl --sS https://ipv4.am.i.mullvad.net/connected
    #You are connected to Mullvad (server ca14-wireguard). Your IP address is 89.36.78.216
    #curl --sS https://ipv4.am.i.mullvad.net/ip
    #89.36.78.216
    #curl --sS https://ipv4.am.i.mullvad.net/city
    #Montreal
    #curl --sS https://ipv4.am.i.mullvad.net/country
    #Canada
    #curl --sS https://ipv4.am.i.mullvad.net/json
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
    #   status=$(echo $connectedStatus | cut -d "(" -f 1 | sed 's/ *$//g')
    #   ip=$(echo $connectedStatus | cut -d "." -f 2-5 | sed 's/ *$//g')

    #   # This returns a country name.
    #   country=$(curl -sSk --ipv4 https://ipv4.am.i.mullvad.net/country | sed 's/ *$//g')

    #   # This returns a city name
    #   city=$(curl -sSk --ipv4 https://ipv4.am.i.mullvad.net/city | sed 's/ *$//g')

    #   echo "$status server in $city, $country.$ip" #1> /tmp/.checkip
    # else
    #   echo "$(echo $connectedStatus | cut -d "." -f 1 | sed 's/ *$//g')." #1> /tmp/.checkip
    # fi
    # exit
  #;;
  start)
    STOP="false"
  ;;
  restart)
    STOP="false"
  ;;
  *) 
    echo "Usage: $0 {start|stop|toggle|restart|status}"
    exit
  ;;
esac
# checkMullvadConnectivity
checkWireguardConnectivity "$mullvadVpnInterfaceRegex"

# Debug log
# echo " ip addr command returned $connectedWireguardConfiguration"

# Extract the wireguard configuration list that is available in /etc/wireguard
# newWireguardConfigurationList=$(sudo ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex")

if [ -z "$(sudo ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex" | grep conf$)" ]; then
  echo "Wireguard Configuration files are missing. Expecting filed matching regex $mullvadVpnInterfaceRegex in $wireguardConfigurationDirectory. Exiting."
fi

if [[ -n "$connectedWireguardConfiguration" ]]; then
  newWireguardConfigurationList=$(sudo ls $wireguardConfigurationDirectory | grep -v "$connectedWireguardConfiguration" | grep --word-regexp "$mullvadVpnInterfaceRegex" | grep conf$)
elif [[ -z "$connectedWireguardConfiguration" ]]; then
  newWireguardConfigurationList=$(sudo ls $wireguardConfigurationDirectory | grep --word-regexp "$mullvadVpnInterfaceRegex" | grep conf$)
fi
if [ "$STOP" == "true" ];then
  if [[ -n "$connectedWireguardConfiguration" ]]; then
    echo "Disconnecting currently connected to $connectedWireguardConfiguration"
    sudo wg-quick down $connectedWireguardConfiguration # 2> /dev/null

  # Satisfies this condition if a connected interface was not found.
  #This is redundant because the output of the curl says "You are not connected to Mullvad"
  #elif [[ -z "$connectedWireguardConfiguration" ]]; then
    #echo "Not currently connected to any VPN."
  fi
  curl -sSk --ipv4 --max-time 3 --connect-timeout 3 https://ipv4.am.i.mullvad.net/connected
  exit
else
  while : ; do
    # Pick a wireguard interface at random to connect to next
    newWireguardConfiguration=$(shuf -n 1 -e $newWireguardConfigurationList)

    # Satisfies this condition if a connected interface was found.
    if [[ -n "$connectedWireguardConfiguration" ]]; then
      echo "System is currently connected to $connectedWireguardConfiguration and will be switching over to $newWireguardConfiguration"
      echo "Disconnecting from $connectedWireguardConfiguration"
      sudo wg-quick down $connectedWireguardConfiguration # 2> /dev/null
      echo "Connecting to $newWireguardConfiguration"
      sudo wg-quick up $wireguardConfigurationDirectory$newWireguardConfiguration # 2> /dev/null

    # Satisfies this condition if a connected interface was not found.
    elif [[ -z "$connectedWireguardConfiguration" ]]; then
      echo "System will attempt to connect to $newWireguardConfiguration"
      sudo wg-quick up $wireguardConfigurationDirectory$newWireguardConfiguration # 2> /dev/null
    fi
    sleep 2
    checkMullvadConnectivity
    IP=$(curl -sSk --ipv4 --max-time 3 --connect-timeout 3 https://ipv4.am.i.mullvad.net/connected)
    successDelimiter='.'
    ipv6Delimiter=':'
    if [[ "$IP" == *"$ipv6Delimiter"* ]]; then
      echo "$IP"
      echo "Connected to IPV6. Reconnecting."
      checkWireguardConnectivity "$mullvadVpnInterfaceRegex"

    elif [[ "$IP" != *"$successDelimiter"* ]]; then
      echo "$IP"
      echo "Failed to connect."
      checkWireguardConnectivity "$mullvadVpnInterfaceRegex"

    else
      curl -sSk --ipv4 --max-time 3 --connect-timeout 3 https://ipv4.am.i.mullvad.net/connected
      exit
    fi
    [[ "$IP" != *"$successDelimiter"* ]] || [[ "$IP" == *"$ipv6Delimiter"* ]] || break
  done
fi

