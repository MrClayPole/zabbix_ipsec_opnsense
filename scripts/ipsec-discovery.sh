#!/bin/sh

# Script to discover ipsec VPN tunnels on OPNsense for auto discovery by Zabbix
#

OPNSENSE_CONF="/conf/config.xml"

echo "{"
echo "    \"data\":["

#Get last IKEID from OPNsense config
for IKEID_XML in $(xmllint --xpath '//opnsense/ipsec/phase1/ikeid' $OPNSENSE_CONF)
do
    LAST_IKEID=$(echo $IKEID_XML | sed -e 's/<[^>]*>//g')
done

# Grab IKE IDs and description from OPNsense config. Get the source and destination phase 1 IP's from ipsec command
for IKEID_XML in $(xmllint --xpath '//opnsense/ipsec/phase1/ikeid' $OPNSENSE_CONF)
do
  IKEID=$(echo $IKEID_XML | sed -e 's/<[^>]*>//g')

  XMLQUERY="//opnsense/ipsec/phase1[ikeid=$IKEID]/descr"
  DESCRIPTION=$(xmllint --xpath "$XMLQUERY" $OPNSENSE_CONF | sed -e 's/<[^>]*>//g')

  REMOTE_PHASE1_IP=$(ipsec statusall | grep con$IKEID | grep -v "{" | grep -v "]:" | grep "remote:" | cut -d "[" -f2 | cut -d "]" -f1)

  LOCAL_PHASE1_IP=$(ipsec statusall | grep con$IKEID | grep -v "{" | grep -v "]:" | grep "local:" | cut -d "[" -f2 | cut -d "]" -f1)

  if [ $IKEID == $LAST_IKEID ]; then
    echo "        { \"{#TUNNEL}\":\"con$IKEID\",\"{#TARGETIP}\":\"$REMOTE_PHASE1_IP\",\"{#SOURCEIP}\":\"$LOCAL_PHASE1_IP\",\"{#DESCRIPTION}\":\"$DESCRIPTION\" }"
  else
    echo "        { \"{#TUNNEL}\":\"con$IKEID\",\"{#TARGETIP}\":\"$REMOTE_PHASE1_IP\",\"{#SOURCEIP}\":\"$LOCAL_PHASE1_IP\",\"{#DESCRIPTION}\":\"$DESCRIPTION\" },"
  fi
done

echo "    ]"
echo "}"
