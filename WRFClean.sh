#!/bin/bash
. variables
print_help() {
	echo "This script cleans WRF and WPS installations and (optionally) backs up their namelist files."
	echo "This script does NOT require sudo and should not be run as sudo, root, etc."
	echo "Usage: ./WRFClean.sh [([wrf] [wps] [-a]|-h|--help)] (in any order, case insensitive)"
	echo "wrf -> clean WRF"
	echo "wps -> clean WPS"
	echo "-a -> appends -a to the clean calls"
	echo "-h -> display this help text"
	echo "--help -> -h"
	echo "If 'wrf' or 'wps' is provided, it will only clean the ones that are provided"
	echo "\t(so, './WRFClean.sh' is equivalent to './WRFClean.sh wrf wps')"
}

#In order to run the WRF and WPS clean scripts as the user that called this script
#(so that the files can be edited without sudo) when this script is called, we have to use sudo to
#specifically switch back to that user for the duration of the command.
#If we aren't running as sudo, then we don't need this command, so it is set to ""
[ $SUDO_USER ] && unsudo="sudo -u $SUDO_USER" || unsudo=""
if [ "$unsudo" != "" ]; then
	echo "This script should NOT be run as sudo."
	echo "Therefore, each command will call $unsudo first"
fi


clean_wrf=false
clean_wps=false
use_a=false

for var in "$@"
do
	var=$(echo "$var" | tr '[:upper:]' '[:lower:]')
	if [ "$var" == "-a" ]; then
		use_a=true
	elif [ "$var" == "wrf" ]; then
		clean_wrf=true
	elif [ "$var" == "wps" ]; then
		clean_wps=true
	else
		print_help
		if [ "$var" != "--help" ] && [ "$var" != "-h" ]; then
			exit 1
		else
			exit 0
		fi
	fi
done
text="wrf and wps installations"
if ( $clean_wrf ); then
	text="wrf"
	if ( $clean_wps ); then
		text=$text" and wps installations"
	else
		text=$text" installation"
	fi
elif ( $clean_wps ); then
	text="wps installation"
else
	clean_wrf=true
	clean_wps=true
fi
text=$text" with ./clean"
if ( $use_a ); then
	text=$text" -a"
fi

read -n1 -p "This script will clean your $text.  Press [Enter] to continue, any other key to quit. " cont
if [ "$cont" != "" ]; then
	echo ""; echo "Canceled.";
	exit 1
fi

if ( ! $keep_namelists ); then
	read -p "keep_namelists in 'variables' is currently set to false. If you proceed, you will loose any existing namelist files. Is this okay? [y/N] " yn
	yn=$(echo "$yn" | tr '[:upper:]' '[:lower:]')
	if [ "$yn" != "y" ]; then
		keep_namelists=true
		echo "Changed keep_namelists to true for this run. Please change the value in 'variables' if you wish to avoid this prompt."
	else
		read -n1 -p "Leaving keep_namelists false. Some existing namelists may be deleted. Press any key to continue."
	fi
fi

set -e
set -o nounset

#Takes path to directory, name of namelist file, path to folder with namelist file relative to directory (without a trailing '/')
clean_wrf() {
	if [ ! -e "$1" ]; then
		echo "Could not find $1.  Skipping."
	else
		cd "$1"
		[ "$#" -gt "3" ] && [ "$3" != "" ] && local np="$3" || local np="."
		if ( $keep_namelists ) && [ -e "$np/$2" ]; then
			$unsudo cp "$np/$2" "$backup_dir/$2.back"
		fi
		( $use_a ) && $unsudo ./clean -a || $unsudo ./clean
		cd ../
	fi
}

if ( $clean_wrf ); then
	clean_wrf "$wrf_path" "namelist.input" "./run"
fi

if ( $clean_wps ); then
	clean_wrf "$wps_path" "namelist.wps"
fi
