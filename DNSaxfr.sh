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
	NS="$(dig $1 ns | egrep "^$1" | awk '{ print $5 }')"
	for NSERVER in $(echo $NS)
	do
		if dig @$NSERVER $1 axfr | egrep '[[:space:]]NS[[:space:]]' > /dev/null 2>&1
		then
			VULNERABLE="$VULNERABLE $NSERVER"
		else
			NOT_VULNERABLE="$NOT_VULNERABLE $NSERVER"
		fi
	done
	[ -n "$VULNERABLE" ] && echo "DOMAIN $1:$VULNERABLE VULNERABLE!"
	[ -n "$NOT_VULNERABLE" ] && echo "DOMAIN $1:$NOT_VULNERABLE NOT VULNERABLE!"
	unset VULNERABLE NOT_VULNERABLE
}

default()
{
	while getopts ':c:i' OPTION
	do
		case $OPTION in
		c)
			alexaTop500 $OPTARG
			exit 0;;
		i)
			iMode
			exit 0;;
		\?)
			echo "Option not reconized...exiting"
			exit 1;;
		:)  
			echo "Option -$OPTARG requires an argument"
			exit 2;;
		esac
	done	
	shift $(($OPTIND - 1 ))
	for CONT in $(seq 1 $#)
	do
	digSite ${!CONT}
	done
}

#############
#SCRIPT START
#############

case $# in
0)
	filter;;
*)
	default "$@";;
esac

exit 0
