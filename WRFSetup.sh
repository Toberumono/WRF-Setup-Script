#!/bin/bash
. variables
fet=$force_extract_tars #for convenience

#In order to run the WRF and WPS configure and compile scripts as the user that called this script
#(so that the files can be edited without sudo) when this script is called with sudo, we have to use sudo to
#specifically switch back to that user for the duration of the command.
#If we aren't running as sudo, then we don't need this command, so it is set to ""
. <(wget -qO - "https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/general/unsudo.sh")
[ "$unsudo" != "" ] && unsudo=$unsudo" WRFIO_NCD_LARGE_FILE_SUPPORT=1 NETCDF=$netcdf_prefix $mpich_compilers" || unsudo=""

#echos 1 if the directory exists and has files in it
unpacked_test() {
	[ -d "$1" ] && [ "$(ls -A $1)" != "" ] && echo "1" || echo "0"
}

#Takes folder to test, tarball name, tar parameters, should it add '../' to the test path for the -C component
#The last two arguments are optional,
unpack_wrf_tarball() {
	[ "$#" -gt "2" ] && local params="$3" || local params="zxvf"
	if ( ! $fet ) && [ "$(unpacked_test $1)" -eq "1" ]; then
		echo "Already unpacked the $2 tarball.  Skipping."
	else
		if [ ! -e "$2" ]; then
			return 1
		fi
		( [ "$#" -lt "4" ] || ( $4 ) ) && local outpath="$1/../" || local outpath="$1"
		mkdir -p "$1"
		$unsudo tar "$params" "$2" "-C" "$outpath"
		echo "Unpacked the $2 tarball"
	fi
	return 0
}

unpack_fail() {
	read -n1 -p "$1 has not been unpacked and no $1 tarball was found. [Press Enter to continue, any other key to quit] " yn
	[ "$yn" != "" ] && echo "" && exit 1 || echo "Continuing"
	unset yn
}

if ( ! $keep_namelists ); then
	read -p "keep_namelists in 'variables' is currently set to false. If you proceed, you will loose any existing namelist files. Is this okay? [y/N] " yn
	yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
	if [ "$yn" != "y" ]; then
		keep_namelists=true
		echo "Changed keep_namelists to true for this run. Please change the value in 'variables' if you wish to avoid this prompt."
	else
		read -p "Leaving keep_namelists false. Some existing namelists may be deleted. Press [Enter] to continue."
	fi
	unset yn
fi

set -o nounset

#This command installs all of the required libraries.
installation="$compilers git wget libjasper-dev jasper zlib1g zlib1g-dev libncarg0 libpng12-0 libpng12-dev"
installation=$installation" libx11-dev libcairo2-dev libpixman-1-dev csh m4 doxygen libhdf5-dev libnetcdf-dev netcdf-bin ncl-ncarg mpich"
if [ "$(which brew)" != "" ]; then #Homebrew or Linuxbrew was detected.
	$unsudo brew tap homebrew/science
	$unsudo brew tap homebrew/dupes
	[ "$(which git)" == "" ] && installation="git "$installation
	installation="wget ncurses cairo libpng szip lzlib pixman doxygen mpich2 tcsh hdf5 ncl jasper"
	if [ "$(which gfortran)" == "" ]; then
		(wget -qO - https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/general/brew_gcc.sh) | $unsudo bash
	fi
	[ "$(which m4)" == "" ] && installation="m4 "$installation
	$unsudo brew install "netcdf" "--with-fortran"
	$unsudo brew install $installation
elif [ "$unsudo" != "" ]; then
	if [ "$(which apt-get)" != "" ]; then #apt-get was detected.
		apt-get install "build-essential "$installation
	elif [ "$(which yum)" != "" ]; then #yum was detected.
		yum groupinstall 'Development Tools' && yum install $installation
	else
		echo "Error: Unable to find Homebrew/Linuxbrew, apt-get, or yum."
		read -p "Please install $installation before continuing. [Press Enter to continue]"
	fi
fi
if [ "$(which wget)" == "" ]; then
	echo "Error: Support software failed to install."
	read -p "Please install $installation before continuing."
	exit 1
fi

netcdf_prefix="$(nc-config --prefix)" #This way the user doesn't have to enter the netcdf prefix

#These next three commands rename the WRF files so that they don't have a capitalized tar component (otherwise the tar command fails)
[ -e "WRFV$wrf_version.TAR.gz" ] && $unsudo mv WRFV$wrf_version.TAR.gz WRFV$wrf_version.tar.gz
[ -e "WPSV$wrf_version.TAR.gz" ] && $unsudo mv WPSV$wrf_version.TAR.gz WPSV$wrf_version.tar.gz
[ -e "WRFV$wrf_major_version-Chem-$wrf_version.TAR.gz" ] && $unsudo mv WRFV$wrf_major_version-Chem-$wrf_version.TAR.gz WRFV$wrf_major_version-Chem-$wrf_version.tar.gz

unpack_wrf_tarball "$wrf_path" "WRFV$wrf_version.tar.gz" 'zxvf' true
[ $? != 0 ] && unpack_fail "WRF"
unpack_wrf_tarball "$wrf_chem_path" "WRFV$wrf_major_version-Chem-$wrf_version.tar.gz" 'zxvf' true
[ $? != 0 ] && unpack_fail "WRF-Chem"
unpack_wrf_tarball "$wps_path" "WPSV$wrf_version.tar.gz" 'zxvf' true
[ $? != 0 ] && unpack_fail "WPS"
unpack_wrf_tarball "$geog_path" "geog_complete.tar.bz2" 'xjvf' false
if [ $? != 0 ]; then
	unpack_wrf_tarball "$geog_path" "geog_minimum.tar.bz2" 'xjvf' false
	[ $? != 0 ] && unpack_fail "GEOGRID"
fi
unset yn

#Export variables for when this script is not run with sudo.
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export NETCDF=$netcdf_prefix
export $mpich_compilers

skip=false
if [ -e "$wrf_path/run/wrf.exe" ]; then
	read -p "WRF has already been compiled. Would you like to recompile it? [y/N] " yn
	yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
	[ "$yn" == "y" ] && skip=false || skip=true
	unset yn
fi
if ( ! $skip ); then
	cd $wrf_path #Starting WRF

	#Back up namelist.input
	if ( $keep_namelists ) && [ -e "./run/namelist.input" ]; then
		$unsudo cp "./run/namelist.input" "$backup_dir/namelist.input.back"
		echo "Backed up namelist.input."
	elif ( $keep_namelists ); then
		echo "No namelist.input to back up."
	fi
	$unsudo ./configure 2>&1 | $unsudo tee ./configure.log #Configure WRF, and output to both a log file and the terminal.

	#Run the WRF regex fixes if they are enabled in 'variables'
	#This just adds -lgomp to the LIB_EXTERNAL variable.
	( $use_wrf_regex_fixes ) && $unsudo perl -0777 -i -pe 's/(LIB_EXTERNAL[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lgomp\n/is' ./configure.wrf || echo "Skipping WRF regex fixes."

	#$unsudo ./compile wrf 2>&1 | $unsudo tee ./compile_wrf.log #Compile WRF, and output to both a log file and the terminal.
	$unsudo ./compile #Calling compile without arguments causes a list of valid test cases and such to be printed to the terminal.

	echo "Please enter the test case you would like to run (this can include the '-j n' part) or wrf [Default: wrf]:"
	read test_case
	test_case=$(echo "$test_case" | tr '[:upper:]' '[:lower:]')
	[ "$test_case" == "" ] && b="wrf" || b="$test_case"
	$unsudo ./compile "$b" 2>&1 | $unsudo tee ./compile_test_case.log
	
	#Restore namelist.input.
	if ( $keep_namelists ) && [ -e "$backup_dir/namelist.input.back" ]; then
		$unsudo mv "$backup_dir/namelist.input.back" "./run/namelist.input"
		echo "Restored namelist.input."
	elif ( $keep_namelists ); then
		echo "No namelist.input to restore."
	fi

	cd ../ #Finished WRF
fi

skip=false
if [ -e "$wps_path/geogrid.exe" ] && [ -e "$wps_path/metgrid.exe" ] && [ -e "$wps_path/ungrib.exe" ]; then
	read -p "WPS has already been compiled. Would you like to recompile it? [y/N] " yn
	yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
	[ "$yn" == "y" ] && skip=false || skip=true
	unset yn
fi

if ( ! $skip ); then
	cd $wps_path #Starting WPS

	#Back up namelist.wps
	if ( $keep_namelists ) && [ -e "./namelist.wps" ]; then
		$unsudo cp "./namelist.wps" "$backup_dir/namelist.wps.back"
		echo "Backed up namelist.wps."
	elif ( $keep_namelists ); then
		echo "No namelist.wps to back up."
	fi

	$unsudo ./configure #2>&1 | $unsudo tee ./configure.log #The WPS configure does something that messes with logging, so this is disabled for now.
	echo "For reasons unknown, WPS's configure sometimes adds invalid command line options to DM_FC and DM_CC and neglects to add some required links to NCARG_LIBS."
	echo "However, this script fixes those problems, so... No need to worry about it."
	if ( $use_wps_regex_fixes ); then
		#Remove -f90 and -cc from the configure.wps file
		$unsudo perl -0777 -i -pe 's/[ \t]*(-f90=($\([^\(]*\))|[^ \t\n]*)|-cc=($\([^\(]*\))|[^ \t\n]*)*)[ \t]*//igs' ./configure.wps
		#Add -lcairo, -lfontconfig, -lpixman-1, and -lfreetype to NCARG_LIBS
		$unsudo perl -0777 -i -pe 's/(NCARG_LIBS[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lcairo -lfontconfig -lpixman-1 -lfreetype\n/is' ./configure.wps
		#Add -lgomp to WRF_LIBS
		$unsudo perl -0777 -i -pe 's/(WRF_LIB[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lgomp\n/is' ./configure.wps
	else
		echo "Skipping WPS regex fixes."
	fi
	$unsudo ./compile 2>&1 | $unsudo tee ./compile.log
	$unsudo ./compile plotgrids 2>&1 | $unsudo tee ./compile_plotgrids.log

	#Restore namelist.wps
	if ( $keep_namelists ) && [ -e "$backup_dir/namelist.wps.back" ]; then
		$unsudo mv "$backup_dir/namelist.wps.back" "./namelist.wps"
		echo "Restored namelist.wps."
	elif ( $keep_namelists ); then
		echo "No namelist.wps to restore."
	fi

	cd ../ #Finished WPS
fi

echo "Please confirm that all of the executables have been appropriately created in the WRFV$wrf_major_version and WPS directories."
echo "You will still need to get boundary data for your simulations.  If you want an automated script to do this, see my WRF-Runner project at github.com/Toberumono/WRF-Runner"
