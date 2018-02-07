#!/bin/bash

########
#LICENSE                                                   
########

# DNS axfr misconfiguration testing script VERSION 1.1a Please visit the project's website at: https://github.com/cybernova/DNSaxfr
# Copyright (C) 2015-2018 Andrea Dari (andreadari91@gmail.com)                                   
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

alexaTop50()
{
		#Error control
		wget -qO- "http://www.alexa.com/topsites/countries/$COUNTRY" | egrep 'We do not currently have a top sites list for this country' &> /dev/null && printf "${RED}ERROR:${RCOLOR} Invalid country code\n" && exit 1
		for DOMAIN in $(wget -qO- "http://www.alexa.com/topsites/countries/$COUNTRY" | egrep '^<a href.*/siteinfo/' | cut -d ">" -f 2 | cut -d "<" -f 1 | tr '[:upper:]' '[:lower:]')
		do
			digSite $DOMAIN
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
		printf "${YELLOW}INFO:${RCOLOR} Downloading from Amazon top 1 milion sites list...\n"
		if ! wget "http://s3.amazonaws.com/alexa-static/top-1m.csv.zip" -O top-1m.csv.zip; then
			printf "${RED}ERROR:${RCOLOR} Unable to download sites list\n" && exit 1
		fi
		if ! gunzip -fS .zip "top-1m.csv.zip"; then
		 printf "${RED}ERROR:${RCOLOR} Unable to decompress archive\n" && exit 1
		fi
		ALEXAMFILE="top-1m.csv"
		printf "${YELLOW}INFO:${RCOLOR} Alexa's top 1m file path: $PWD/$ALEXAMFILE\n${YELLOW}TIP:${RCOLOR} Use in future the -f option\n"
		alexaTop1M
	fi
	exit 0
}

usage()
{
	printf "${YELLOW}Usage:${RCOLOR} DNSaxfr.sh [OPTION...][DOMAIN...]\n"
	printf "Shell script for testing DNS AXFR misconfiguration\n"
	printf "${YELLOW}0 ARGUMENTS:${RCOLOR}\n"
	printf "The script reads from stdin and writes on stdout, it takes one domain to test per line\n"
	printf "${YELLOW}1+ ARGUMENTS:${RCOLOR}\n"
	printf "The script tests every domain specified as argument\n"
	printf "${YELLOW}OPTIONS:${RCOLOR}\n"
	printf -- "${GREEN}-b${RCOLOR}              Batch mode, makes the output readable when saved in a file\n"
  printf -- "${GREEN}-c${RCOLOR} ${RED}COUNTRYCODE${RCOLOR}  Test Alexa's top 50 sites by country\n"
	printf -- "${GREEN}-f${RCOLOR} ${RED}FILE${RCOLOR}         Alexa's top 1M sites .csv file. To use with -m option\n"
	printf -- "${GREEN}-h${RCOLOR}              Display the help and exit\n"
	printf -- "${GREEN}-i${RCOLOR}              Interactive mode\n"
	printf -- "${GREEN}-m${RCOLOR} ${RED}RANGE${RCOLOR}        Test Alexa's top 1M sites. RANGE examples: 1 (start to test from 1st) or 354,400 (test from 354th to 400th)\n"
  printf -- "${GREEN}-n${RCOLOR}              Numeric address format for name servers\n"
	printf -- "${GREEN}-r${RCOLOR} ${RED}MAXDEPTH${RCOLOR}     Test recursively every subdomain of a vulnerable domain, descend at most MAXDEPTH levels. 0 means no limit\n" 
	printf -- "${GREEN}-x${RCOLOR} ${RED}REGEXP${RCOLOR}       Do not test domains that match with regexp\n"              
	printf -- "${GREEN}-z${RCOLOR}              Save zone transfer data in a directory named as the vulnerable domain\n" 
}

iMode()
{
	printf "${YELLOW}########\n#${RCOLOR}LICENSE\n${YELLOW}########${RCOLOR}\n"
	printf "${YELLOW}#${RCOLOR} DNS axfr misconfiguration testing script ${GREEN}VERSION 1.1a${RCOLOR} Please visit the project's website at: ${RED}https://github.com/cybernova/DNSaxfr${RCOLOR}\n"
	printf "${YELLOW}#${RCOLOR} Copyright (C) 2015-2018 ${GREEN}Andrea Dari${RCOLOR} (${RED}andreadari91@gmail.com${RCOLOR})\n"
	printf "${YELLOW}#${RCOLOR}\n"
	printf "${YELLOW}#${RCOLOR} This shell script is free software: you can redistribute it and/or modify\n"
	printf "${YELLOW}#${RCOLOR} it under the terms of the GNU General Public License as published by\n"
	printf "${YELLOW}#${RCOLOR} the Free Software Foundation, either version 3 of the License, or\n"
	printf "${YELLOW}#${RCOLOR} any later version.\n"
	printf "${YELLOW}#${RCOLOR}\n"
	printf "${YELLOW}#${RCOLOR} This program is distributed in the hope that it will be useful,\n"
	printf "${YELLOW}#${RCOLOR} but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
	printf "${YELLOW}#${RCOLOR} MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
	printf "${YELLOW}#${RCOLOR} GNU General Public License for more details.\n"
	printf "\n"
	printf "Insert the domain to test (Ctrl+d to terminate):\n"
	while read DOMAIN 
	do
		DOMAIN="$(echo $DOMAIN | tr '[:upper:]' '[:lower:]')"
		digSite $DOMAIN
		printf "Insert the domain to test (Ctrl+d to terminate):\n"
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
		[[ -n "$NOT_VULNERABLE" ]] && printf "${YELLOW}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${GREEN}NOT VULNERABLE!${RCOLOR}\n"
		[[ -n "$VULNERABLE" ]] && printf "${YELLOW}DOMAIN${RCOLOR} $1:$VULNERABLE ${RED}VULNERABLE!${RCOLOR}\n"
		return 
 	fi
		for i in $(seq 1 $(($LVLDIFF - 1)))
		do
				#When customizing the tree "|   " has to be replaced with the TREE2 value
				TREE1="|  $TREE1"
				TREE2="|  $TREE2"
		done
		[[ -n "$NOT_VULNERABLE" ]] && printf "${TREE1}${YELLOW}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${GREEN}NOT VULNERABLE!${RCOLOR}\n"
		if [[ ! -n "$NOT_VULNERABLE" ]]
		then
			printf "${TREE1}${YELLOW}DOMAIN${RCOLOR} $1:$VULNERABLE ${RED}VULNERABLE!${RCOLOR}\n"
		elif [[ -n "$VULNERABLE" ]]
		then
			printf "${TREE2}${YELLOW}DOMAIN${RCOLOR} $1:$VULNERABLE ${RED}VULNERABLE!${RCOLOR}\n"
		fi
}

digSite()
{
	#Do not test domains that match with regexp
	[[ "$OPTIONX" = 'y' && "$1" =~ $REGEXP ]] && return
	unset VULNERABLE NOT_VULNERABLE
	#$1 domain to test
	local FILE="${1}_axfr.log"
	local NS=""
	if [[ "$NUMERIC" = 'y' ]]
	then
		for NSERVER in $(dig $DIGOPT $1 ns | egrep '[[:space:]]NS[[:space:]]' | awk '{print $5}' )
		do
			NS="$(dig +short $DIGOPT $NSERVER a) $NS"
		done
	else
		NS="$(dig $DIGOPT $1 ns | egrep '[[:space:]]NS[[:space:]]' | awk '{print $5}')"
	fi 
	#Error control
	[[ ! -n $NS ]] && printf "${RED}ERROR:${RCOLOR} $1 is not a domain!${RCOLOR}\n" && return
	for NSERVER in $NS
	do
		if [[ "$ZONETRAN"  = 'y' ]]
		then
			if dig $DIGOPT @$NSERVER $1 axfr | tee /tmp/$FILE | grep "[[:space:]]NS[[:space:]]" > /dev/null 2>&1
			then
					[[ ! -d $DOMAIN ]] && mkdir $DOMAIN
					mv /tmp/$FILE $DOMAIN
					VULNERABLE="$VULNERABLE $NSERVER"
			else
				rm /tmp/$FILE
				NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
			fi
		else
			if dig $DIGOPT @$NSERVER $1 axfr | grep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
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
		[[ $MAXDEPTH -eq $LVLDIFF && $MAXDEPTH -ne 0 ]] && return
		(( LVLDIFF++ ))
		if [[ -f $DOMAIN/$FILE ]]
		then 
			for SDOMAIN in $(grep "[[:space:]]NS[[:space:]]" $DOMAIN/$FILE | egrep -v "^$1" | awk '{ print $1 }' | sort -u)
			do
				SDOMAIN="$(echo $SDOMAIN | tr '[:upper:]' '[:lower:]')"
				digSite $SDOMAIN
			done
		else
			for SDOMAIN in $(dig $DIGOPT @$(echo $VULNERABLE | awk '{ print $1 }') $1 axfr | grep '[[:space:]]NS[[:space:]]' | egrep -v "^$1" | awk '{ print $1 }' | sort -u)	
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
	while getopts ':bc:f:him:nr:x:z' OPTION
	do
		case $OPTION in
		b)unset GREEN YELLOW RED RCOLOR;;
		c)local ALEXA50='y'; COUNTRY="$(echo $OPTARG | tr '[:lower:]' '[:upper:]')";;
		f)ALEXAMFILE="$OPTARG";;
		h)usage; exit 0;;
		i)local IMODE='y';;
		m)local ALEXA1M='y'; RANGE="$OPTARG"
						#Simple error control
						if [[ "$RANGE" =~ [[:digit:]]+,[[:digit:]]+ ]]
						then
							RANGE1=$(echo "$RANGE" | cut -d , -f 1)
							RANGE2=$(echo "$RANGE" | cut -d , -f 2)	
							[[ ! $RANGE2 -ge $RANGE1 || ! $RANGE1 -ge 1 || ! $RANGE2 -le 1000000 ]] && printf "${RED}ERROR:${RCOLOR} Invalid range value\n" && exit 1
						else
							[[ ! $RANGE =~ [[:digit:]]+ || ! $RANGE -ge 1 || ! $RANGE -le 1000000 ]] && printf "${RED}ERROR:${RCOLOR} Invalid range value\n"  && exit 1
						fi ;;
		n)NUMERIC='y';;
		r)RECURSIVE='y'; MAXDEPTH="$OPTARG"
						#Simple error control
						[[ ! $MAXDEPTH =~ [[:digit:]]+ || $MAXDEPTH -lt 0 ]] && printf "${RED}ERROR:${RCOLOR} Invalid depth value\n" && exit 1
						;;
		x)OPTIONX='y'; REGEXP=$OPTARG;;
		z)ZONETRAN='y';;
		\?)
			printf "${RED}ERROR:${RCOLOR} Option -$OPTARG not reconized\n"
			exit 1;;
		:)  
			printf "${RED}ERROR:${RCOLOR} Option -$OPTARG requires an argument\n"
			exit 2;;
		esac
	done	
	shift $(($OPTIND - 1))

	[[ "$ALEXA1M" = 'y' ]] && alexaTop1M
	[[ "$ALEXA50" = 'y' ]] && alexaTop50
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
YELLOW='\033[1;93m'
RED='\033[1;91m'
RCOLOR='\033[1;00m'

LVLDIFF=0

#Dig's options
DIGOPT='+retry=1'

parse "$@"
exit 0
