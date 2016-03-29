#!/bin/bash

########
#LICENSE                                                   
########

# DNS axfr misconfiguration testing script VERSION 1.0.2 Please visit the project's website at: https://github.com/cybernova/DNSaxfr
# Copyright (C) 2016 Andrea 'cybernova' Dari (andreadari91@gmail.com)                                   
#                                                                                                       
# This shell script is free software: you can redistribute it and/or modify                             
# it under the terms of the GNU General Public License as published by                                   
# the Free Software Foundation, either version 2 of the License, or                                     
# any later version.                                                                   
#                                                                                                       
# This program is distributed in the hope that it will be useful,                                       
# but WITHOUT ANY WARRANTY; without even the implied warranty of                                        
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                         
# GNU General Public License for more details.                                                          
#                                                                                                       
# You should have received a copy of the GNU General Public License                                     
# along with this shell script.  If not, see <http://www.gnu.org/licenses/>.

filter()
{
	#One domain to test per line
	while read DOMAIN
	do
		DOMAIN="$(echo $DOMAIN | tr '[:upper:]' '[:lower:]')"
		digSite $DOMAIN
	done
	exit 0
}

alexaTop500()
{
	for VAL in {0..19}
	do
		for DOMAIN in $(wget -qO- "http://www.alexa.com/topsites/countries;${VAL}/$COUNTRY" | grep site-listing | cut -d ">" -f 7 | cut -d "<" -f 1 | tr '[:upper:]' '[:lower:]')
		do
			digSite $DOMAIN
		done
	done
	exit 0
}

alexaTop1M()
{
	#$ALEXAMFILE is the Alexa's .csv file
	#$RANGE is the range to test.

	if [ -n "$ALEXAMFILE" ]
	then
		if [ -n "$RANGE1" ]
		then
			for NL in $(seq $RANGE1 $RANGE2)	
			do
				DOMAIN=$(egrep "^$NL," $ALEXAMFILE | cut -d , -f 2)
				digSite $DOMAIN 
			done	
		else
			for NL in $(seq $RANGE $(wc -l $ALEXAMFILE | cut -d " " -f 1))	
			do
				DOMAIN=$(egrep "^$NL," $ALEXAMFILE | cut -d , -f 2) 
				digSite $DOMAIN
			done
		fi
	else
		echo "Downloading from Amazon top 1 milion sites list..."
		if ! wget "http://s3.amazonaws.com/alexa-static/top-1m.csv.zip" -O top-1m.csv.zip; then
			echo "ERROR: unable to download sites list" && exit 1
		fi
		if ! gunzip -fS .zip "top-1m.csv.zip"; then
		 echo "ERROR: unable to decompress archive" && exit 1
		fi
		ALEXAMFILE="top-1m.csv"
		echo "File's path: $PWD/$ALEXAMFILE"
		alexaTop1M
	fi
	exit 0
}

usage()
{
	echo "Usage: DNSaxfr.sh [OPTION...][DOMAIN...]"
	echo -e  "Shell script for testing DNS AXFR misconfiguration\n"
	echo "0 ARGUMENTS:"
	echo "The script acts like a filter, reads from stdin and writes on stdout, useful for using it in a pipeline."
	echo "NOTE: It takes one domain to test per line"
	echo "1+ ARGUMENTS:"
	echo "The script tests every domain specified as argument, writing the output on stdout."
	echo "OPTIONS:"
	echo "-b              Batch mode, useful for making the output readable when saved in a file"
	echo "-c COUNTRY_CODE Test Alexa top 500 sites by country"
	echo "-f FILE         Alexa's top 1M sites .csv file. To use in conjuction with -m option"
	echo "-h              Display the help and exit"
	echo "-i              Interactive mode"
	echo "-m RANGE        Test Alexa top 1M sites. RANGE examples: 1 (start to test from 1st) or 354,400 (test from 354th to 400th)"
	echo "-r              Test recursively every subdomain of a vulnerable domain"
	echo "-z              Save the zone transfer in a directory named as the domain vulnerable in the following form: domain_axfr.log" 
}

iMode()
{
	echo -e "########\n#LICENSE\n########\n"
	echo "# DNS axfr misconfiguration testing script VERSION 1.0.2 Please visit the project's website at: https://github.com/cybernova/DNSaxfr"
	echo "# Copyright (C) 2016 Andrea 'cybernova' Dari (andreadari91@gmail.com)"
	echo "#"
	echo "# This shell script is free software: you can redistribute it and/or modify"
	echo "# it under the terms of the GNU General Public License as published by"
	echo "# the Free Software Foundation, either version 3 of the License, or"
	echo "# any later version."
	echo "#"
	echo "# This program is distributed in the hope that it will be useful,"
	echo "# but WITHOUT ANY WARRANTY; without even the implied warranty of"
	echo "# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
	echo "# GNU General Public License for more details."
	echo -e "\n\n"
	echo "Insert the domain you want to test (Ctrl+d to terminate):"
	while read DOMAIN 
	do
		DOMAIN="$(echo $DOMAIN | tr '[:upper:]' '[:lower:]')"
		digSite $DOMAIN
		echo "Insert the domain you want to test (Ctrl+d to terminate):"
	done
	exit 0
}

drawTree()
{
	#Customize the tree changing these 2 shell variables
	local TREE1="|--"
	local TREE2="|  "
	if [[ "$DOMAIN" = "$1" ]]
	then
		[[ -n "$VULNERABLE" ]] && printf "DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		[[ -n "$NOT_VULNERABLE" ]] && printf "DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		return 
 	fi
	if [[ $LVLDIFF -eq 1 ]]
	then
		[[ -n "$VULNERABLE" ]] && printf "${TREE1}DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [[ ! -n "$VULNERABLE" ]]
		then
			printf "${TREE1}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[[ -n "$NOT_VULNERABLE" ]] && printf "${TREE2}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	else
		for i in $(seq 1 $(($LVLDIFF - 1)))
		do
				#When customizing the tree "|   " has to be replaced with the TREE2 value
				TREE1="|  $TREE1"
				TREE2="|  $TREE2"
		done
		[[ -n "$VULNERABLE" ]] && printf "${TREE1}DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [[ ! -n "$VULNERABLE" ]]
		then
			printf "${TREE1}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[[ -n "$NOT_VULNERABLE" ]] && printf "${TREE2}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	fi
}

digSite()
{
	unset VULNERABLE NOT_VULNERABLE
	#$1 domain to test
	FILE="${1}_axfr.log"
	NS="$(dig +retry=1 $1 ns | egrep "^$1" | awk '{ print $5 }')"
	#Error control
	[[ ! -n $NS ]] && return
	for NSERVER in $NS
	do
		if [[ "$ZONETRAN"  = 'y' ]]
		then
			if dig @$NSERVER $1 axfr | tee /tmp/$FILE | grep "[[:space:]]NS[[:space:]]" > /dev/null 2>&1
			then
					[[ ! -d $DOMAIN ]] && mkdir $DOMAIN
					mv /tmp/$FILE $DOMAIN
					VULNERABLE="$VULNERABLE $NSERVER"
			else
				rm /tmp/$FILE
				NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
			fi
		else
			if dig @$NSERVER $1 axfr | grep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
			then
				VULNERABLE="$VULNERABLE $NSERVER"
			else
				NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
			fi
		fi
	done
	[[ -n "$VULNERABLE" || -n "$NOT_VULNERABLE" ]] && drawTree $1
	if [[ "$RECURSIVE" = 'y' && -n "$VULNERABLE" ]]
	then
		(( LVLDIFF++ ))
		if [[ -f $DOMAIN/$FILE ]]
		then 
			for SDOMAIN in $(grep "[[:space:]]NS[[:space:]]" $DOMAIN/$FILE | egrep -v "^$1" | awk '{ print $1 }' | sort -u)
			do
				SDOMAIN="$(echo $SDOMAIN | tr '[:upper:]' '[:lower:]')"
				digSite $SDOMAIN
			done
		else
			for SDOMAIN in $(dig @$(echo $VULNERABLE | awk '{ print $1 }') $1 axfr | grep '[[:space:]]NS[[:space:]]' | egrep -v "^$1" | awk '{ print $1 }' | sort -u)	
			do
				SDOMAIN="$(echo $SDOMAIN | tr '[:upper:]' '[:lower:]')"
				digSite $SDOMAIN
			done
		fi
	(( LVLDIFF-- ))
	fi
}

parse()
{
	while getopts ':bc:f:him:pqrz' OPTION
	do
		case $OPTION in
		b)unset GREEN RED RCOLOR;;
		c)local ALEXA500='y'; COUNTRY="$OPTARG";;
		f)ALEXAMFILE="$OPTARG";;
		h)usage; exit 0;;
		i)local IMODE='y';;
		m)local ALEXA1M='y'; RANGE="$OPTARG"
						#Error control
						if [[ "$RANGE" =~ [[:digit:]]+,[[:digit:]]+ ]]
						then
							RANGE1=$(echo "$RANGE" | cut -d , -f 1)
							RANGE2=$(echo "$RANGE" | cut -d , -f 2)	
							[[ ! $RANGE2 -ge $RANGE1 || ! $RANGE1 -ge 1 || ! $RANGE2 -le 1000000 ]] && echo "ERROR: Invalid range value" && exit 1
						else
							[[ ! $RANGE =~ [[:digit:]]+ || ! $RANGE -ge 1 || ! $RANGE -le 1000000 ]] && echo "ERROR: Invalid range value"  && exit 1
						fi ;;
		r)RECURSIVE='y';;
		z)ZONETRAN='y';;
		\?)
			echo "Option -$OPTARG not reconized"
			exit 1;;
		:)  
			echo "Option -$OPTARG requires an argument"
			exit 2;;
		esac
	done	
	shift $(($OPTIND - 1))

	[[ "$ALEXA1M" = 'y' ]] && alexaTop1M
	[[ "$ALEXA500" = 'y' ]] && alexaTop500
	[[ "$IMODE" = 'y' ]] && iMode

	#No argument
	[[ $# -eq 0 ]] && filter

	#Testing every domain specified as argument
	for CONT in $(seq 1 $#)
	do
	DOMAIN="$(echo ${!CONT} | tr '[:upper:]' '[:lower:]')"
	digSite $DOMAIN
	done
}

#############
#SCRIPT START
#############
GREEN='\033[1;92m'
RED='\033[1;91m'
RCOLOR='\033[1;00m'

LVLDIFF=0

parse "$@"
exit 0
