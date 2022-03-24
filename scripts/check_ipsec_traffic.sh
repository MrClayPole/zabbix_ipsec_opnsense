#!/bin/sh
#Expect conxxxxx [bytesIn,bytesOut]
# ------------------------------------------
IPSECBIN="/usr/local/sbin/ipsec"
IPSECCMD=$IPSECBIN
# ------------------------------------------

# Testing availability of $IPSECBIN

if [ $# -eq 0 ];
then
   echo UNKNOWN - missing Arguments. Run check_ipsec_traffic --help
   exit $STATE_UNKNOWN
fi

test -e $IPSECBIN
if [ $? -ne 0 ]; then
    echo CRITICAL - $IPSECBIN not exist
    exit $STATE_CRITICAL
else
    STRONG=`$IPSECBIN --version |grep strongSwan | wc -l`
fi

ipsec_get_bytes()
{
  for ipsec in $(ipsec statusall | grep $1\{ | grep bytes_ | tr -su ' ' '\n' | tail -n +2)
  do
    if [ "$ipsec" == "$2" ] || [ "$ipsec" == "$2," ]; then
      echo $ipsec_prev
      break
    else
      ipsec_prev=$ipsec
    fi
  done

}

getTraffic() {

    CONN="$1" METRIC="$2"

    if [ "$STRONG" -eq "1" ]; then
        #check if tunel exists
        ipsec status | grep -e "$CONN" > /dev/null 2>&1
        #Save the retuned status code
        tmp=$?
        #If tunnel exists
        if [ $tmp -eq 0 ]; then
                ipsec status | grep -e "$CONN" | grep -e "ESTABLISHED" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        ipsec statusall | grep -e "$CONN" | grep -v "ESTABLISHED" | grep -e "bytes" > /dev/null 2>&1

                        #If tunnel is up and match IP REGEX
                        if [ $? -eq 0 ]; then
                                case $METRIC in
                                        bytesIn)
                                                ipsec_get_bytes $CONN "bytes_i"
                                                ;;
                                        bytesOut)
                                                ipsec_get_bytes $CONN "bytes_o"
                                                ;;

                                        *)
                                                echo "Undefined. Parameter $METRIC in not allowed"
                                                ;;
                                esac
                                #echo "Tunnel $CONN look ok"
                                return 0
                        else
                                echo 0
                        fi
                else
                        #echo "Tunnel $CONN not ESTABLISHED"
                        echo 0
                        return 1
                fi
        fi
    fi

}

getTraffic $1 $2
