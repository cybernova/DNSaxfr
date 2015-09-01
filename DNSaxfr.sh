#!/bin/bash

########
#LICENSE                                                   
########

# DNS axfr vulnerability testing script. Please visit the project's website at: https://github.com/cybernova/DNSaxfr
# Copyright (C) 2015 Andrea 'cybernova' Dari (andreadari91@gmail.com)                                   
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
	#Only the characters found in $IFS are recognized as word delimiters.
	while read DOMAIN
	do
		DOMAINLVL=$(echo $DOMAIN | sed -e 's/\.$//' | awk -F . '{ print NF }')
		digSite $DOMAIN
	done
}

alexaTop500()
{
	for VAL in $(seq 0 19)
	do
		for DOMAIN in $(wget -qO- "http://www.alexa.com/topsites/countries;${VAL}/$1" | cat - | grep site-listing | cut -d ">" -f 7 | cut -d "<" -f 1)
		do
			DOMAINLVL=$(echo $DOMAIN | sed -e 's/\.$//' | awk -F . '{ print NF }')
			digSite $DOMAIN
		done
	done
}

usage()
{
	echo "Usage: DNSaxfr.sh [OPTION...][DOMAIN...]"
	echo -e  "Shell script for testing DNS AXFR vulnerability\n"
	echo "0 ARGUMENTS:"
	echo "The script acts like a filter, reads from stdin and writes on stdout, useful for using it in a pipeline."
	echo "NOTE: It takes one domain to test per line"
	echo "1+ ARGUMENTS:"
	echo "The script tests every domain specified as argument, writing the output on stdout."
	echo "OPTIONS:"
	echo "-c COUNTRY_CODE Test Alexa top 500 sites by country"
	echo "-h              Display the help and exit"
	echo "-i              Interactive mode"
	echo "-p              Use proxychains to safely query name servers"
	echo "-q 							Quiet mode when using proxychains (all proxychains' output is discarded)"
	echo "-r							Test recursively every subdomain of a vulnerable domain"
	echo "-z              Save the zone transfer in the wd in the following form: domain_axfr.log" 
}

iMode()
{
	echo -e "########\n#LICENSE\n########\n"
	echo "# DNS axfr vulnerability testing script. Please visit the project's website at: https://github.com/cybernova/DNSaxfr"
	echo "# Copyright (C) 2015 Andrea 'cybernova' Dari (andreadari91@gmail.com)"
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
		DOMAINLVL=$(echo $DOMAIN | sed -e 's/\.$//' | awk -F . '{ print NF }')
		digSite $DOMAIN
		echo "Insert the domain you want to test (Ctrl+d to terminate):"
	done
}

drawTree()
{
	unset TREE1 TREE2
	TREE1="|--"
	TREE2="|  "
	if [ "$DOMAIN" = "$1" ]
	then
		[ -n "$VULNERABLE" ] && printf "DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		[ -n "$NOT_VULNERABLE" ] && printf "DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		return 
 	fi
	LVLDIFF=$(( $(echo $1 | sed -e 's/\.$//' | awk -F . '{ print NF }') - $DOMAINLVL))
	if [ $LVLDIFF -eq 1 ]
	then
		[ -n "$VULNERABLE" ] && printf "${TREE1}DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [ ! -n "$VULNERABLE" ]
		then
			printf "${TREE1}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[ -n "$NOT_VULNERABLE" ] && printf "${TREE2}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	else
		for i in $(seq 1 $LVLDIFF)
		do
			TREE1=" $TREE1"
			TREE2=" $TREE2"
		done
		[ -n "$VULNERABLE" ] && printf "|${TREE1}DOMAIN $1:$VULNERABLE ${GREEN}VULNERABLE!${RCOLOR}\n"
		if [ ! -n "$VULNERABLE" ]
		then
			printf "|${TREE1}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		else
			[ -n "$NOT_VULNERABLE" ] && printf "|${TREE2}DOMAIN $1:$NOT_VULNERABLE ${RED}NOT VULNERABLE!${RCOLOR}\n"
		fi
	fi
}

digSite()
{
	unset VULNERABLE NOT_VULNERABLE
	#$1 domain to test
	FILE="${1}_axfr.log"
	NS="$($QUIET1 $PROXY dig $1 ns $QUIET2 | egrep "^$1" | awk '{ print $5 }')"
	for NSERVER in $(echo $NS)
	do
		if [ "$ZONETRAN"  = 'enabled' -a ! -f $FILE ]
		then
			if $QUIET1 $PROXY dig @$NSERVER $1 axfr $QUIET2 | tee /tmp/$FILE | egrep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
			then
				mv /tmp/$FILE .
				VULNERABLE="$VULNERABLE $NSERVER"
			else
				rm /tmp/$FILE
				NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
			fi
		else
			if $QUIET1 $PROXY dig @$NSERVER $1 axfr $QUIET2 | egrep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
			then
				VULNERABLE="$VULNERABLE $NSERVER"
			else
				NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
			fi
		fi
	done
	[ -n "$VULNERABLE" -o -n "$NOT_VULNERABLE" ] && drawTree $1
	if [ "$RECURSIVE" = 'enabled' -a -n "$VULNERABLE" ]
	then
		if [ -f $FILE ]
		then
			for SDOMAIN in $(egrep '[[:space:]]NS[[:space:]]' $FILE | egrep -vi "^$1" | awk '{ print $1 }' | sort -u)
			do
				digSite $SDOMAIN
			done
		else
			for SDOMAIN in $($QUIET1 $PROXY dig @$(echo $VULNERABLE | awk '{ print $1 }') $1 axfr $QUIET2 | egrep '[[:space:]]NS[[:space:]]' | egrep -vi "^$1" | awk '{ print $1 }' | sort -u)	
			do
				digSite $SDOMAIN
			done
		fi
	fi
}

parse()
{
	while getopts ':c:hipqrz' OPTION
	do
		case $OPTION in
		c)ALEXA500='enabled'; COUNTRY="$OPTARG";;
		h)usage && exit 0;;
		i)IMODE='enabled';;
		p)[ ! -x $(which proxychains) ] && echo "Proxychains is not installed...exiting" && exit 3 || PROXY='proxychains';;
		q)QUIET1='eval'; QUIET2='2>/dev/null';;
		r)RECURSIVE='enabled';;
		z)ZONETRAN='enabled';;
		\?)
			echo "Option not reconized...exiting"
			exit 1;;
		:)  
			echo "Option -$OPTARG requires an argument"
			exit 2;;
		esac
	done	
	shift $(($OPTIND - 1))

	[ "$ALEXA500" = 'enabled' ] && alexaTop500 $COUNTRY && exit 0
	[ "$IMODE" = 'enabled' ] && iMode && exit 0

	#No arguments
	[ $# -eq 0 ] && usage && exit 0

	#Every site specified as argument is tested
	for CONT in $(seq 1 $#)
	do
	DOMAIN=${!CONT}
	DOMAINLVL=$(echo $DOMAIN | sed -e 's/\.$//' | awk -F . '{ print NF }')
	digSite $DOMAIN
	done
}

#############
#SCRIPT START
#############
GREEN='\033[1;92m'
RED='\033[1;91m'
RCOLOR='\033[1;00m'

parse "$@"
exit 0
