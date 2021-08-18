#!/bin/bash

url=$1

green='tput setaf 2'
red='tput setaf 1'
reset='tput sgr0'

#print ascii art header, because it's cool!
tput setaf 4;
cat << "EOF"
      _       ____                        _       _____                       
__  _| |_ ___|  _ \  ___  _ __ ___   __ _(_)_ __ | ____|_ __  _   _ _ __ ___  
\ \/ / __/ __| | | |/ _ \| '_ ` _ \ / _` | | '_ \|  _| | '_ \| | | | '_ \` _ \ 
 >  <| |_\__ \ |_| | (_) | | | | | | (_| | | | | | |___| | | | |_| | | | | | |
/_/\_\\__|___/____/ \___/|_| |_| |_|\__,_|_|_| |_|_____|_| |_|\__,_|_| |_| |_|
                                                                              

Requirements:

* assetfinder - https://github.com/tomnomnom/assetfinder
* amass - https://github.com/OWASP/Amass
* httprobe - https://github.com/tomnomnom/httprobe
* gowitness - https://github.com/sensepost/gowitness

Note: Give it some time, amass is good but really slow.

EOF
tput sgr0;

#check requirements are installed
if [[ $(which assetfinder) =~ "not found" ]];then
	echo "$(tput setaf 1)Error$(tput sgr0) - assetfinder could not be found. Please install and try again."
	exit 1;
fi
if [[ $(which amass) =~ "not found" ]];then
	echo "$(tput setaf 1)Error$(tput sgr0) - amass could not be found. Please install and try again."
	exit 1;
fi
if [[ $(which httprobe) =~ "not found" ]];then
	echo "$(tput setaf 1)Error$(tput sgr0) - httprobe could not be found. Please install and try again."
	exit 1;
fi
if [[ $(which gowitness) =~ "not found" ]];then
	echo "$(tput setaf 1)Error$(tput sgr0) - gowitness could not be found. Please install and try again."
	exit 1;
fi

if [ $# -eq 0 ];then
	echo "$(tput setaf 1)Error$(tput sgr0) - No arguments provided"
	echo "Syntax: xtsDomainEnum.sh <domain>"
	exit 1
fi

echo "$(tput setaf 1)[+]$(tput sgr0) Cleaning Output Files..."
if [ -d "$url" ];then
	rm -rf $url
fi

#Make Directories

if [ ! -d "$url" ];then
	mkdir $url
fi
if [ ! -d "$url/recon" ];then
	mkdir $url/recon
fi
if [ ! -d "$url/recon/screenshots" ];then
	mkdir $url/recon/screenshots
fi
if [ ! -d "$url/recon/assetfinder" ];then
	mkdir $url/recon/assetfinder
fi
if [ ! -d "$url/recon/amass" ];then
	mkdir $url/recon/amass
fi

#Harvest Subdomains and get screenshots of the live ones

echo "$(tput setaf 2)[+]$(tput sgr0) Harvesting Subdomains with AssetFinder..."
assetfinder $url > $url/recon/assets.txt
sort -u $url/recon/assets.txt | grep $url >> $url/recon/assetfinder/assetfinder.txt
rm $url/recon/assets.txt

echo "$(tput setaf 2)[+]$(tput sgr0) Harvesting Subdomains with Amass..."
amass enum -d $url > $url/recon/assets.txt
sort -u $url/recon/assets.txt | grep $url >> $url/recon/amass/amass.txt
rm $url/recon/assets.txt

echo "$(tput setaf 2)[+]$(tput sgr0) Removind Duplicate Discoveries"
echo "" > $url/recon/final.txt
sort -u $url/recon/assetfinder/assetfinder.txt >> $url/recon/final.txt
sort -u $url/recon/amass/amass.txt >> $url/recon/final.txt

echo "$(tput setaf 2)[+]$(tput sgr0) Probing for alive domains with httprobe..."
cat $url/recon/final.txt | httprobe | sed 's/https\?:\/\///' | tr -d ":443" | sort -u > $url/recon/alive.txt
echo $( cat $url/recon/alive.txt | wc -l ) "domains alive"

echo "$(tput setaf 2)[+]$(tput sgr0) Collecting Screenshots of " $( cat $url/recon/alive.txt | wc -l ) " live domains with gowitness..."
for line in $( cat $url/recon/alive.txt )
do
	gowitness single https://$line -P $url/recon/screenshots/
done

#Clean Up - remove unnecessary files and reset text colour
echo "$(tput setaf 2)[+]$(tput sgr0) Cleaning Up..."
rm gowitness.sqlite3
tput setaf 0;
