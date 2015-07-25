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
	while read SITE
	do
		digSite $SITE
	done
}

alexaTop500()
{
	for VAL in $(seq 0 19)
	do
		for SITE in $(wget -qO- "http://www.alexa.com/topsites/countries;${VAL}/$1" | cat - | grep site-listing | cut -d ">" -f 7 | cut -d "<" -f 1)
		do
			digSite $SITE
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
	echo "-z              Save the zone transfer in the wd in this form: domain_axfr.log" 
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
	while read SITE
	do
		digSite $SITE
		echo "Insert the domain you want to test (Ctrl+d to terminate):"
	done
}

digSite()
{
	#$1 domain to test
	FILE="${1}_axfr.log"
	NS="$(dig $1 ns | egrep "^$1" | awk '{ print $5 }')"
	for NSERVER in $(echo $NS)
	do
		if $PROXY dig @$NSERVER $1 axfr | egrep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
		then
			VULNERABLE="$VULNERABLE $NSERVER"
			[ "$ZONETRAN"  = 'enabled' -a ! -f $FILE ] && $PROXY dig @$NSERVER $1 axfr > $FILE
		else
			NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
		fi
	done
	[ -n "$VULNERABLE" ] && echo "DOMAIN $1:$VULNERABLE VULNERABLE!"
	[ -n "$NOT_VULNERABLE" ] && echo "DOMAIN $1:$NOT_VULNERABLE NOT VULNERABLE!"
	unset VULNERABLE NOT_VULNERABLE
}

parse()
{
	while getopts ':c:hipz' OPTION
	do
		case $OPTION in
		c)ALEXA500='enabled'; COUNTRY="$OPTARG";;
		h)usage && exit 0;;
		i)IMODE='enabled';;
		p)[ ! -f /usr/bin/proxychains ] && echo "Proxychains is not installed...exiting" && exit 3 || PROXY='proxychains';;
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

	for CONT in $(seq 1 $#)
	do
	digSite ${!CONT}
	done
}

#############
#SCRIPT START
#############

parse "$@"
exit 0
