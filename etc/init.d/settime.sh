#!/bin/sh
# (c) Robert Shingledecker 2012
#     Bela Markus 2015

# Wait for network to come up and then set time

CNT=0
until ifconfig | grep -q Bcast
do
    [ $((CNT++)) -gt 60 ] && break || sleep 1
done

if [ $CNT -le 60 ]
then
    CNT=9999
    NRT=0
    while sleep 0
    do
        XXX=$(/bin/date -I)
        XXX=${XXX:0:4}

        if [ "$XXX" -ge "2015" ];
        then
            break
        fi

        if [ $CNT -gt 10 ];
        then
            /usr/bin/getTime.sh
            if [ $NRT -gt 5 ];
            then 
                break
            fi
            CNT=0
            NRT=$((NRT+1))
        fi

    CNT=$((CNT+1))
    sleep 1
    done
fi
