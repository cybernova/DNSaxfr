#!/bin/bash

########
#LICENSE                                                   
########

# DNS axfr misconfiguration testing script VERSION 1.0.5b Please visit the project's website at: https://github.com/cybernova/DNSaxfr
# Copyright (C) 2017 Andrea Dari (andreadari91@gmail.com)                                   
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

usage()
{
	echo "Usage: DNSaxfr.sh [OPTION...][DOMAIN...]"
	echo -e  "Shell script for testing DNS AXFR misconfiguration\n"
	echo "0 ARGUMENTS:"
	echo "The script reads from stdin and writes on stdout, it takes one domain to test per line"
	echo "1+ ARGUMENTS:"
	echo "The script tests every domain specified as argument"
	echo "OPTIONS:"
	echo "-b              Batch mode, makes the output readable when saved in a file"
	echo "-h              Display the help and exit"
	echo "-i              Interactive mode"
	echo "-r              Test recursively every subdomain of a vulnerable domain"
	echo "-v              Print DNSaxfr version and exit"
	echo "-z              Save the zone transfer in a directory named as the vulnerable domain" 
}

iMode()
{
	echo -e "########\n#LICENSE\n########\n"
	echo "# DNS axfr misconfiguration testing script VERSION 1.0.5b Please visit the project's website at: https://github.com/cybernova/DNSaxfr"
	echo "# Copyright (C) 2017 Andrea Dari (andreadari91@gmail.com)"
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
		[[ -n "$VULNERABLE" ]] && printf "${BGREEN}DOMAIN${RCOLOR} $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		[[ -n "$NOT_VULNERABLE" ]] && printf "${BGREEN}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		return 
 	fi
	if [[ $LVLDIFF -eq 1 ]]
	then
		[[ -n "$VULNERABLE" ]] && printf "${TREE1}${BGREEN}DOMAIN${RCOLOR} $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [[ ! -n "$VULNERABLE" ]]
		then
			printf "${TREE1}${BGREEN}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[[ -n "$NOT_VULNERABLE" ]] && printf "${TREE2}${BGREEN}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	else
		for i in $(seq 1 $(($LVLDIFF - 1)))
		do
				#When customizing the tree "|   " has to be replaced with the TREE2 value
				TREE1="|  $TREE1"
				TREE2="|  $TREE2"
		done
		[[ -n "$VULNERABLE" ]] && printf "${TREE1}${BGREEN}DOMAIN${RCOLOR} $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [[ ! -n "$VULNERABLE" ]]
		then
			printf "${TREE1}${BGREEN}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[[ -n "$NOT_VULNERABLE" ]] && printf "${TREE2}${BGREEN}DOMAIN${RCOLOR} $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	fi
}

digSite()
{
	unset VULNERABLE NOT_VULNERABLE
	#$1 domain to test
	local FILE="${1}_axfr.log"
	local NS="$(dig $DIGOPT $1 ns | egrep "^$1" | awk '{ print $5 }')"
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
	while getopts ':bhirvz' OPTION
	do
		case $OPTION in
		b)unset GREEN RED RCOLOR;;
		h)usage; exit 0;;
		i)local IMODE='y';;
		r)RECURSIVE='y';;
		v)printf "$VERSION\n"; exit 0;;
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
VERSION='DNSaxfr v1.0.5b Copyright (C) 2017 Andrea Dari (andreadari91@gmail.com)'

GREEN='\033[1;92m'
BGREEN='\033[32m'
RED='\033[1;91m'
RCOLOR='\033[1;00m'

LVLDIFF=0

#Dig's options
DIGOPT='+retry=1'

parse "$@"
exit 0
