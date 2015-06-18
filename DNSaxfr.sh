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

iMode()
{
	echo -e "########\n#LICENSE\n########\n"
	echo "# POSIX_Backup script. Please visit the project's website at: https://github.com/cybernova/POSIX_Backup"
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
	echo "DOMAIN $1:"	
	[ -n "$VULNERABLE" ] && echo "$VULNERABLE VULNERABLE!"
	[ -n "$NOT_VULNERABLE" ] && echo "$NOT_VULNERABLE NOT VULNERABLE!"
	unset VULNERABLE NOT_VULNERABLE
}

default()
{
	while getopts ':if:' OPTION
	do
		case $OPTION in
		i)
			iMode;;
		\?)
			echo "Option not reconized...exiting"
			exit 1;;
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
