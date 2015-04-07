#!/bin/bash
#Ping Alert by JJ Agha
#Revision 2 10/2/2014

#Setup Some Global Variables
workingDirectory="/root/ping_alert"

#Setup Some NMAP Variables
IPList="${workingDirectory}/list"
nmapOutput="${workingDirectory}/scan_results"

#Setup Scan File Variables
baseScanFileName="${workingDirectory}/base_scan"
newScanFileName="${workingDirectory}/new_scan"
newSevers="${workingDirectory}/new_servers"
suppressTestFileName="${workingDirectory}/suppress_alerts"

#Setup Email Variables
sendEmailProgram="/usr/local/bin/sendEmail.pl"
emailServer="smtp.l.domain.com"
fromAddress="you@example.com"
toAddress="to@example.com"
ccAddress="CC@example.com"
emailSubject="Email Subject"

#Email Template
read -d '' emailTemplate <<EOF
Email Body
TEXT TEXT TEXT
EOF

# Delete previous files
rm -rf ${nmapOutput}

#Run NMAP
nmap -sP -iL ${IPList} -n -oG ${nmapOutput} > /dev/null 2>&1
cat ${nmapOutput} | grep Nmap >> /var/log/messages

#Setup New Scan File
grep Up ${nmapOutput} | awk '{print $2}' | sort | uniq > ${newScanFileName}

#Compare New Scan with Base Scan
compareNewToBaseTest=`comm -13 ${baseScanFileName} ${newScanFileName} | wc -l`

#Alert Logic
if [ ${compareNewToBaseTest} -ge 1 ]
then
  # New servers have been detected
  # Define what has changed
  comm -13 ${baseScanFileName} ${newScanFileName} > ${newSevers}
  cat ${newSevers} >> /var/log/messages     
  #Sort the files
  cat ${newSevers} | sort | uniq > out; mv out ${newSevers}
  #Compare New Scan with Suppress File
  compareNewToSuppressTest=`comm -13 ${suppressTestFileName} ${newSevers} | wc -l`
  # Test if NewServers should be suppressed
  if [ ${compareNewToSuppressTest} -ge 1 ]
  then
    #Send an email
    echo | awk -v template="$emailTemplate" -v bservers="$(comm -13 ${suppressTestFileName} ${newSevers})" 'BEGIN {sub(/BADSERVERS/, bservers, template); print template}' | ${sendEmailProgram} -f ${fromAddress} -t ${toAddress} -cc ${ccAddress} -u ${emailSubject} -s ${emailServer} >> /var/log/messages
    # Add new servers to suppress_alerts to prevent future errors
  cat ${newSevers} >> ${suppressTestFileName}
    # Sort the files
    cat ${suppressTestFileName} | sort | uniq > out; mv out ${suppressTestFileName}
  else
    # Do nothing
  echo 'Nothing new has popped up'  
  exit 0
  fi
fi
