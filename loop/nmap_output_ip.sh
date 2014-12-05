#!/bin/bash

#Setup Variables
workingDirectory=`pwd`
server_list="${1}"

for ip in $(cat ${server_list})
	j=`echo $ip | sed 's!\/!_!g' | sed 's!\.!_!g'` 
	do
	nmap -sS -sU -v --max-retries 3 --min-rtt-timeout 100ms --max-rtt-timeout 3000ms --initial-rtt-timeout 100ms --top-ports 1000 -g 53,111,123,161 -iL $ip -oX ${server_list}.xml
done
