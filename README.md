# Monitoring IPsec tunnels on OPNsense using zabbix

This project was forked from https://github.com/alanwds/zabbix_ipsec_OPNsense. Thanks to @alanwds by sharing 

This template is used for monitoring IPSEC tunnels on OPNsense using zabbix.

# Dependencies

- Zabbix agent (you can install it from OPNsense packages manager)
- sudo (you can install it from OPNsense packages manager)
- Zabbix Server >= 5.0
- check_ipsec.sh
- check_ipsec_traffic.sh
- ipsec-discovery.sh
- check_carp_state.sh
- zabbix_sudoers

# How it works

The template queries ipsec-discovery.sh for tunnels ids (conXXXX). After that, the items prototipes are created consuming check_ipsec.sh script. The script check_ipsec_traffic is used to collect traffic about the tunnel. Added a check for Carp/HA status so that VPN down's won't trigger on the passive firewall

### Installation

- You have to put check_ipsec.sh, check_ipsec_traffic.sh, check_carp_state.sh and ipsec-discovery.sh on OPNsense filesystem. (/usr/local/bin/ in this example)
- Install sudo pakage at OPNsense packages manager
- Copy file zabbix_sudoers under /usr/local/etc/sudoers.d
- At the console "touch /usr/local/etc/strongswan.opnsense.d/dummy.conf" (This prevents an error when running ipsec commands)
- Create the follow user parameters at zabbix-agent config page on OPNsense (Service -> Zabbix-agent -> Advanced Options)
```
UserParameter=ipsec.discover,/usr/local/bin/sudo /usr/local/bin/ipsec-discovery.sh
UserParameter=ipsec.tunnel[*],/usr/local/bin/sudo /usr/local/bin/check_ipsec.sh $1
UserParameter=ipsec.traffic[*],/usr/local/bin/sudo /usr/local/bin/check_ipsec_traffic.sh $1 $2
UserParameter=carp.status,/usr/local/bin/check_carp_state.sh
```
- Set execution permissions
```
chmod +x /usr/local/bin/ipsec-discovery.sh
chmod +x /usr/local/bin/check_ipsec.sh 
chmod +x /usr/local/bin/check_ipsec_traffic.sh
chmod +x /usr/local/bin/check_carp_state.sh
``` 
- Import the template OPNsense IPSec template.xml on zabbix and attach to OPNsense hosts
- Go get a beer
