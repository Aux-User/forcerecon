#!/bin/bash

#The script will first start with declaring functions and assigning variables.
#It will prompt the user to define some login credentials to be used later.
#Next, it will determine network range and viable hosts.
#Then it will perform a vulnerability scan on and attempt to brute force each machine.
#Lastly, it will allow the user to view the either a main report of all the scans
#or the findings for a particular host.


#These colour codes are for some quality of life enhancements to 
#highlight some outputs from the script.
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BGRN='\033[1;32m'
BCYN='\033[1;36m'
BIRED='\033[1;91m'
BGYLW='\033[43m'
UYLW='\033[4;33m'
CLR='\033[0m'

#Now the various functions will be declared.
#This function is for stopping the script until a key is pressed.
#This is for letting the user take note of certain details before continuing.
function pressany()
{
read -n 1 -r -s -p $'Press any key to continue...\n'
}

#This function is for an nmap scan.
#It will enumerate for OS type, open ports and services, as well as run
#vuln category scripts for the detected protocols to determine CVE's.
#It will also start to generate the subreprt for host being scanned.
function nmapvul()
{

echo "SUBREPORT for $TARGETIP" > subrep.txt
echo 'This section will only contain details pertaining to the above host
and may be referenced separately from other subreports and the main report if needed.' >> subrep.txt
echo ' ' >> subrep.txt
	sudo nmap $TARGETIP -script vuln -sV -vv -p 21-30 -O --open -oN nmapvres.txt
#For demonstration purposes, the script will only run on ports 21-30
#A full scan of all ports on the host will use the command below instead.
	#sudo nmap $TARGETIP -script vuln -sV -vv -p- -O --open -oN nmapvres.txt
cat nmapvres.txt | grep ttl > svclist.lst
echo "Here is a summary of the open ports and services for $TARGETIP" >> subrep.txt
cat svclist.lst >> subrep.txt
echo ' ' >> subrep.txt
echo 'Full nmap vulnerability report as follows:' >> subrep.txt
cat nmapvres.txt >> subrep.txt
echo ' ' >> subrep.txt

sudo chmod 777 nmapvres.txt
rm nmapvres.txt
#Some housekeeping for temporary files that are no longer needed.
}

#This function is for a Hydra brute force attack on the same host using
#user provided credentials that the script will ask for when it starts running.
#It will continue to add the results to the host-specific subreport.
#Since this is the last action against the host, it will conclude the subreport,
#as well as adding the all the findings for the host to the main report.
function bfatk()
{

#Popular login services are used for this attack, the presence of which are
#determined by the earlier scan and the brute force uses the first availabile service.
cat svclist.lst | awk '{print$3}' | grep -E 'ftp|ssh|smtp|smb|telnet|rdp' > svcatk.lst
echo "The following popular protocols have been found to be running on $TARGETIP"
cat svcatk.lst
echo ' '
SVTYPE=$(cat svcatk.lst | head -n 1)
echo "Using the first protocol available, $SVTYPE, a Brute Force attack will now be made
against $TARGETIP with the credentials provided earlier."

	sudo hydra -L $USERHIT -P $PWHIT $TARGETIP $SVTYPE -vV > hydratest.txt
	
echo 'Brute Force report as follows:' >> subrep.txt
cat hydratest.txt >> subrep.txt
echo ' ' >> subrep.txt
echo "This concludes the subreport for $TARGETIP" >> subrep.txt
echo '_______________________________________________________' >> subrep.txt
cat subrep.txt >> mainrep.txt
echo ' ' >> mainrep.txt
mv subrep.txt  PTrun-$DTST/subrep-$TARGETIP.txt

rm svclist.lst
rm svcatk.lst
rm pwrandom$PWMIN$PWMAX.lst 2>/dev/null
rm hydratest.txt
#Some housekeeping for removing temporary files

}

#Now that functions have been defined, this is where the running starts.

echo 'Greetings, User.'
echo 'This script will
1) Identify your network range and scan it for viable hosts
2) Scan each host for vunlerabilities
3) Brute force each host with credentials that you will be prompted for
4) Allow you to view the findings'
echo ' '
pressany
echo ' '
echo -e "Please enter the name of the file you wish to use as a Brute Force ${BGYLW}USER${CLR} list"
read INPUTUSER
USERHIT=$(find / -name $INPUTUSER 2>/dev/null)
#Even if the user does not enter the file path, the file can still be located.
echo -e "You have specified ${UYLW}$USERHIT${CLR} as the Brute Force ${UYLW}user${CLR} list."
echo ' '
echo 'Do you wish to
1) Use an existing password list or
2) Create one now?'
read PWANS
#The user is given the option to provide a list of passwords or make one on the spot.
case $PWANS in

	1)
		echo 'You have opted to use an existing password list.
Please enter the name of the file you wish to use as a Brute Force password list'
		read INPUTPW
		PWHIT=$(find / -name $INPUTPW 2>/dev/null)
		echo -e "You have specified ${UYLW}$PWHIT${CLR} as the Brute Force ${UYLW}password${CLR} list."
		
	;;
	2) 
		echo 'You have decided to create a new password list.'
		echo -e "${BIRED}!!!WARNING!!!${CLR} This list will be randomly generated."
		echo 'Depending on your input parameters, the resulting list MAY be very long.
Please be mindful of your storage space as well as
the time requirements for the Brute Force attack.'
		echo 'For the purposes of demonstration, the randomly generated
passwords will only conist of a, b and c.'
		echo 'Please enter the minimum password length'
		read PWMIN
		echo 'Please enter the maximum password length'
		read PWMAX
		crunch $PWMIN $PWMAX abc > pwrandom$PWMIN$PWMAX.lst
#For demonstration purposes, only abc will be used to generate the password list.
#For a more comprehensive list using all alphanumeric characters, the below command should be used		
#crunch $PWMIN $PWMAX -f /usr/share/crunch/charset.lst mixalpha-numeric-all-space > pwrandom$PWMIN$PWMAX.txt
		PWHIT=pwrandom$PWMIN$PWMAX.lst
		echo -e "Your random password list ${UYLW}$PWHIT${CLR} has been generated and
will be used as the Brute Force ${UYLW}password${CLR} list."
			
esac

echo ' '
echo 'Thank you for your input.
You may choose to wait or return in a few minutes.
A series of tones will play to indicate when the report is ready for viewing.'
echo ' '
pressany

#Here the network range and number of live hosts are determined.
SELFIP=$(ifconfig | grep broadcast | awk '{print$2}')
SELFIPRNG=$(ipcalc $SELFIP | grep Network | awk '{print$2}')
echo "The IP of your current machine is $SELFIP"
echo "Its network range is $SELFIPRNG"
echo ' '
echo 'Now performing scans for live hosts on network...'
#A directory is created based on the date and time of the run.
#Main and subreports relevant to this run will be stored here.
DTST=$(date +%F-%H%M)
mkdir PTrun-$DTST
#The main report is created here, capturing the details of the network scan.
DTHD=$(date "+%x %R")
ATKTIME=$(TZ=Asia/Singapore date)
echo "MAIN REPORT FOR VULNERABILITY ASSESSMENT ON $DTHD" > mainrep.txt
echo ' ' >> mainrep.txt
echo "Network scan started on $ATKTIME" >> mainrep.txt 
nmap -sn "$SELFIPRNG" -oG nmaptgt.lst

cat nmaptgt.lst | grep Up | awk '{print$2}' > shortlist.lst
#Here the results are cleaned before presented to the user.
#The user's own machine and NAT device are removed from the scan results.
cat shortlist.lst | grep -v "$SELFIP"| grep -Ewv '([0-9]{1,3}[\.]){3}2' > viable.lst

echo 'The live hosts on the network are:'
cat viable.lst
echo ' '

#The next few lines are for generating the main report.
echo 'The live hosts on the network are:' >> mainrep.txt
cat viable.lst >> mainrep.txt
echo ' ' >> mainrep.txt
echo 'The findings for each host will be detailed in their respective subpreports below.' >> mainrep.txt
echo 'Each subreport will display:' >> mainrep.txt
echo 'A) A summary of open ports and their respective services' >> mainrep.txt
echo 'B) Full results of an nmap vulnerability scan' >> mainrep.txt
echo 'C) Full results of a hydra brute force attack' >> mainrep.txt
echo ' ' >> mainrep.txt
echo ' '
echo -e "${GRN}Network scan complete${CLR}"
echo 'Assessing hosts for vulnerabilities and weak passwords...'
echo ' '

#Here the functions for the nmap scan and hydra brute force will be called
#for each viable machine in the network scan.
for TARGETIP in $(cat viable.lst)
	do
		nmapvul
		
		bfatk
		
	done

echo '------<<<|This Concludes the Main Report|>>>------' >> mainrep.txt
mv mainrep.txt PTrun-$DTST/mainrep-$DTST.txt
rm nmaptgt.lst
rm shortlist.lst
#Main report for this run concluded and more housekeeping for temporary files.
#A series of tones will play to alert the user that the run is complete
#and report available for viewing
paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
paplay /usr/share/sounds/sound-icons/prompt.wav
paplay /usr/share/sounds/speech-dispatcher/test.wav
echo ' '
echo -e "${BGRN}Assessment Complete${CLR}"
echo 'Thank you for your patience'
echo -e "Findings have been consolidated and saved in ${BCYN}./PTrun-$DTST${CLR}"
echo 'Please press
1)	To view the main report.
	This contains the findings of the entire run, from network scanning to
	the findings of each machine.
2)	To view the details of actions taken against a specific machine.
	This will display the findings of one machine only.'
read REPANS
#The user may choose to view the main report which contains all the details
#of the run or focus on the findings of a specific host via that host's subreport
case $REPANS in

	1) echo 'Directing you to main report...'
	   pressany
	   cat PTrun-$DTST/mainrep-$DTST.txt
	      
	;;
	2) echo 'Please key in the IP address of the subreport you wish to view'
	   echo 'To refresh your memory, the scanned hosts are:'
	   cat viable.lst
	   read SUBCHOICE
	   echo "Directing you to subreport for $SUBCHOICE..."
	   pressany
	   cat PTrun-$DTST/subrep-$SUBCHOICE.txt

esac 

rm viable.lst
#Last bit of housekeeping

