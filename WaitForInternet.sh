#!/bin/bash


# This script checks that the interface is up, and that an internet connection is available
# It is based on code from http://askubuntu.com/questions/3299/how-to-run-cron-job-when-network-is-up
#
# Then it sleeps for a random number of seconds between 30 and 600.
# This is based on code from http://tldp.org/LDP/abs/html/randomvar.html
#
# Collated by @JonTheNiceGuy on 2015-10-15

function check_ipaddr
{
  # Here we look for an IP(v4|v6) address when doing ip addr
  # Note we're filtering out 127.0.0.1 and ::1/128 which are the "localhost" ip addresses
  # I'm also removing fe80: which is the "link local" prefix

  ip addr | \
  grep -v 127.0.0.1 | \
  grep -v '::1/128' | \
  grep -v 'inet6 fe80:' | \
  grep -E "inet [[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+|inet6" | \
  wc -l
}

function check_google
{
  netcat -z -w 5 8.8.8.8 53 && echo 1 || echo 0
}

until [ `check_ipaddr` -ge 1 ]; do
  sleep 1
done

until [ `check_google` -eq 1 ]; do
  sleep 1
done

exit
# Loop until there's an internet connection
while true; do
  # Ping Google's public DNS
  if ping -c 1 8.8.8.8 &> /dev/null; then
    #echo "Connected to the internet"
    # If the ping command succeeds, run the command and break the loop
    break
  else
    # If the ping command fails, sleep for a bit before trying again
    #echo "Not connected to the internet. Retrying in 5 seconds..."
    sleep 5
  fi
done
