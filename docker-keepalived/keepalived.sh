#!/bin/bash

# Setup check script
if [[ -z ${CHECK_SCRIPT} ]]; then
  if [[ -z ${CHECK_IP} ]] || [[ ${CHECK_IP} = 'any' ]]; then
    CHECK_SCRIPT="iptables -t nat -nL CATTLE_PREROUTING | grep ':${CHECK_PORT}'"
  else
    CHECK_SCRIPT="iptables -nL | grep '${CHECK_IP}' && iptables -t nat -nL CATTLE_PREROUTING | grep ':${CHECK_PORT}'"
  fi
fi

validate-ip ()
{
  if ! [[ $1 =~ ^(([1-9]|[1-9][0-9]|1[0-9]{2}|2[0-2][0-3])\.)(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-5][0-5])\.){2}([1-9]|[1-9][0-9]|1[0-9]{2}|2[0-5][0-5])$ ]]; then
    echo "The $2 environment variable is null or not a valid IP address, exiting..."
    exit 1
  fi
}

# Substitute variables in config file.
/bin/sed -i "s/{{VIRTUAL_IP}}/${VIRTUAL_IP}/g" /etc/keepalived/keepalived.conf
if [[ -z ${STATE} ]]; then
  /bin/sed -i "s/{{STATE}}/BACKUP/g" /etc/keepalived/keepalived.conf
else
  /bin/sed -i "s/{{STATE}}/${STATE}/g" /etc/keepalived/keepalived.conf
fi
if [[ -z ${PRIORITY} ]]; then
  /bin/sed -i "s/{{PRIORITY}}/100/g" /etc/keepalived/keepalived.conf
else
  /bin/sed -i "s/{{PRIORITY}}/${PRIORITY}/g" /etc/keepalived/keepalived.conf
fi

if [[ -z ${ADVERT_INT} ]]; then
  /bin/sed -i "s/{{ADVERT_INT}}/1/g" /etc/keepalived/keepalived.conf
else
  /bin/sed -i "s/{{ADVERT_INT}}/${ADVERT_INT}/g" /etc/keepalived/keepalived.conf
fi

/bin/sed -i "s/{{VIRTUAL_MASK}}/${VIRTUAL_MASK}/g" /etc/keepalived/keepalived.conf
/bin/sed -i "s/{{CHECK_SCRIPT}}/${CHECK_SCRIPT}/g" /etc/keepalived/keepalived.conf
/bin/sed -i "s/{{VRID}}/${VRID}/g" /etc/keepalived/keepalived.conf
/bin/sed -i "s/{{INTERFACE}}/${INTERFACE}/g" /etc/keepalived/keepalived.conf
if [[ -z ${UNICAST_SRC_IP} ]]; then
  /bin/sed -i "/unicast_src_ip/d" /etc/keepalived/keepalived.conf
else
  /bin/sed -i "s/{{UNICAST_SRC_IP}}/${UNICAST_SRC_IP}/g" /etc/keepalived/keepalived.conf
fi
# unicast peers
for peer in ${UNICAST_PEERS}; do
  validate-ip ${peer} 'UNICAST_PEERS'
  /bin/sed -i "s/{{UNICAST_PEERS}}/${peer}\n            {{UNICAST_PEERS}}/g" /etc/keepalived/keepalived.conf
done
/bin/sed -i "/{{UNICAST_PEERS}}/d" /etc/keepalived/keepalived.conf

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating keepalived process..."
  # Record PIDs
  pid=$(pidof keepalived)
  # Kill them
  kill -TERM $pid > /dev/null 2>&1
  # Wait until processes have been killed.
  # Use 'wait $pid' instead if you dislike using sleep (the wait command has less OS support)
  sleep 1
  echo "Terminated."
  exit 0
}

# Make sure the variables we need to run are populated and (roughly) valid

validate-ip $VIRTUAL_IP 'VIRTUAL_IP'


if ! [[ $VIRTUAL_MASK =~ ^([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
  echo "The VIRTUAL_MASK environment variable is null or not a valid subnet mask, exiting..."
  exit 1
fi

if ! [[ $VRID =~ ^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-5][0-5])$ ]]; then
  echo "The VRID environment variable is null or not a number between 1 and 255, exiting..."
  exit 1
fi

# Possibly some interfaces are named and don't end in a number so beware of this one
if ! [[ $INTERFACE =~ ^.*[0-9]$ ]]; then
  echo "The INTERFACE environment variable is null or doesn't end in a number, exiting..."
  exit 1
fi

# Make sure to clean up VIP before start (in case of ungraceful shutdown)
if [[ $(ip addr | grep $INTERFACE | grep $VIRTUAL_IP) ]]
  then
    ip addr del $VIRTUAL_IP/$VIRTUAL_MASK dev $INTERFACE
fi

# This loop runs till until we've started up successfully
while true; do

  # Check if Keepalived is running by recording it's PID (if it's not running $pid will be null):
  pid=$(pidof keepalived)

  # If $pid is null, do this to start or restart Keepalived:
  while [ -z "$pid" ]; do
    #Obviously optional:
    #echo "Starting Confd population of files..."
    #/usr/bin/confd -onetime
    echo "Displaying resulting /etc/keepalived/keepalived.conf contents..."
    cat /etc/keepalived/keepalived.conf
    echo "Starting Keepalived in the background..."
    /usr/sbin/keepalived --dont-fork --dump-conf --log-console --log-detail --vrrp &
    # Check if Keepalived is now running by recording it's PID (if it's not running $pid will be null):
    pid=$(pidof keepalived)

    # If $pid is null, startup failed; log the fact and sleep for 2s
    # We'll then automatically loop through and try again
    if [ -z "$pid" ]; then
      echo "Startup of Keepalived failed, sleeping for 2s, then retrying..."
      sleep 2
    fi

  done

  # Break this outer loop once we've started up successfully
  # Otherwise, we'll silently restart and Rancher won't know
  break

done

while true; do

  # Check if Keepalived is STILL running by recording it's PID (if it's not running $pid will be null):
  pid=$(pidof keepalived)
  # If it is not, lets kill our PID1 process (this script) by breaking out of this while loop:
  # This ensures Docker 'sees' the failure and handles it as necessary
  if [ -z "$pid" ]; then
    echo "Keepalived is no longer running, exiting so Docker can restart the container..."
    break
  fi

  # If it is, give the CPU a rest
  sleep 0.5

done

exit 1
