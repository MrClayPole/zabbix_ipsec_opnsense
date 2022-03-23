#!/bin/sh

#
# Script to check if firewall is in high availability mode and if its backup or master
#
# Possible returns
#   DISABLED: HA is disabled
#   MASTER: HA is enable and this firewall is the MASTER
#   BACKUP: HA is enabled and this firewall is the BACKUP

# Init variables
carp_state="UNKNOWN"

# Test for CARP interfaces
ifconfig -a | grep 'carp:' > /dev/null
if [ $? = 0 ]; then
  ifconfig -a | grep 'carp:' | grep BACKUP > /dev/null
  if [ $? = 0 ]; then
    carp_state="BACKUP"
  else
    ifconfig -a | grep 'carp:' | grep MASTER > /dev/null
    if [ $? = 0 ]; then
      carp_state="MASTER"
    fi
  fi
else
  carp_state="DISABLED"
fi

# Print carp state
echo $carp_state
