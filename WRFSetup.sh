#!/bin/bash
. variables
fet=$force_extract_tars #for convenience

#In order to run the WRF and WPS configure and compile scripts as the user that called this script
#(so that the files can be edited without sudo) when this script is called with sudo, we have to use sudo to
#specifically switch back to that user for the duration of the command.
#If we aren't running as sudo, then we don't need this command, so it is set to ""
[ $SUDO_USER ] && unsudo="sudo -u $SUDO_USER WRFIO_NCD_LARGE_FILE_SUPPORT=1 NETCDF=$netcdf_prefix $mpich_compilers" || unsudo=""

if ( ! $keep_namelists ); then
	read -p "keep_namelists in 'variables' is currently set to false. If you proceed, you will loose any existing namelist files. Is this okay? [y/N] " yn
	declare -l yn
	if [ "$yn" != "y" ]; then
		keep_namelists=true
		echo "Changed keep_namelists to true for this run. Please change the value in 'variables' if you wish to avoid this prompt."
	else
		read -p "Leaving keep_namelists false. Some existing namelists may be deleted. Press [Enter] to continue."
	fi
fi

set -e
set -o nounset

#This command installs all of the required libraries.
installation="build-essential $compilers git wget libjasper-dev jasper zlib1g zlib1g-dev libncarg0 libpng12-0 libpng12-dev libx11-dev libcairo2-dev libpixman-1-dev csh m4 doxygen libhdf5-dev libnetcdf-dev netcdf-bin ncl-ncarg mpich"
if [ "$unsudo" != "" ]; then
	if [ "$(which apt-get)" != "" ]; then
		apt-get install $installation
	elif [ "$(which yum)" != "" ]; then
		yum install $installation
	elif [ "$(which brew)" != "" ]; then #We are running on Mac OSX and will be using Homebrew.  THIS IS EXPERIMENTAL.
		$unsudo brew install $installation
	else
		echo "Error: Unable to find apt-get or yum."
		read -p "Please install $installation before continuing."
	fi
elif [ "$(which wget)" == "" ]; then
	echo "Error: Support software failed to install."
	read -p "Please install $installation before continuing."
fi

#These next three commands rename the WRF files so that they don't have a capitalized tar component (otherwise the tar command fails)
[ -e "WRFV$wrf_version.TAR.gz" ] && $unsudo mv WRFV$wrf_version.TAR.gz WRFV$wrf_version.tar.gz
[ -e "WPSV$wrf_version.TAR.gz" ] && $unsudo mv WPSV$wrf_version.TAR.gz WPSV$wrf_version.tar.gz
[ -e "WRFV$wrf_major_version-Chem-$wrf_version.TAR.gz" ] && $unsudo mv WRFV$wrf_major_version-Chem-$wrf_version.TAR.gz WRFV$wrf_major_version-Chem-$wrf_version.tar.gz

#The [ ! -d "<path>" ] && <action> form only performs <action> if <path> does not exist or is not a directory
$fet || [ ! -d "$WRF_path" ]		&& $unsudo tar zxvf WRFV$wrf_version.tar.gz || echo "Already extracted WRF"
$fet || [ ! -d "$WRF_Chem_path" ]	&& $unsudo tar zxvf WRFV$wrf_major_version-Chem-$wrf_version.tar.gz -C $WRF_path || echo "Already extracted WRF-Chem"
$fet || [ ! -d "$WPS_path" ]		&& $unsudo tar zxvf WPSV$wrf_version.tar.gz || echo "Already extracted WPS"

#Export variables for when this script is not run with sudo.
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export NETCDF=$netcdf_prefix
export $mpich_compilers

cd $WRF_path #Starting WRF

#Back up namelist.input
if ( $keep_namelists ) && [ -e "./run/namelist.input" ]; then
	$unsudo cp "./run/namelist.input" "$DIR/namelist.input.back"
	echo "Backed up namelist.input."
elif ( $keep_namelists ); then
	echo "No namelist.input to back up."
fi

$unsudo ./configure 2>&1 | $unsudo tee ./configure.log #Configure WRF, and output to both a log file and the terminal.

#Run the WRF regex fixes if they are enabled in 'variables'
#This jsut adds -lgomp to the LIB_EXTERNAL variable.
( $use_wrf_regex_fixes ) && $unsudo perl -0777 -i -pe 's/(LIB_EXTERNAL[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lgomp\n/is' ./configure.wrf || echo "Skipping WRF regex fixes."

$unsudo ./compile wrf 2>&1 | $unsudo tee ./compile_wrf.log #Compile WRF, and output to both a log file and the terminal.
$unsudo ./compile #Calling compile without arguments causes a list of valid test cases and such to be printed to the terminal.

echo "Please enter the test case you would like to run (this can include the '-j n' part) or none [Default: none]:"
read test_case
declare -l test_case
if [ $(echo ${#test_case}) -gt 4 ] && [ "$test_case" != "" -a "$test_case" != "none" ]; then
	$unsudo ./compile "$test_case" 2>&1 | $unsudo tee ./compile_test_case.log
else
	echo "Skipping compiling a test case."
fi

#Restore namelist.input.
if ( $keep_namelists ) && [ -e "$DIR/namelist.input.back" ]; then
	$unsudo mv "$DIR/namelist.input.back" "./run/namelist.input"
	echo "Restored namelist.input."
elif ( $keep_namelists ); then
	echo "No namelist.input to restore."
fi

cd ../ #Finished WRF

cd $WPS_path #Starting WPS

#Back up namelist.wps
if ( $keep_namelists ) && [ -e "./run/namelist.wps" ]; then
	$unsudo cp "./run/namelist.wps" "$DIR/namelist.wps.back"
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
if ( $keep_namelists ) && [ -e "$DIR/namelist.wps.back" ]; then
	$unsudo mv "$DIR/namelist.wps.back" "./run/namelist.wps"
	echo "Restored namelist.wps."
elif ( $keep_namelists ); then
	echo "No namelist.wps to restore."
fi

cd ../ #Finished WPS

echo "Please confirm that all of the executables have been appropriately created in the WRFV$wrf_major_version and WPS directories."
echo "You will still need to extract your Geogrid data and get GFS data relevant to the times you are interested in simulating."
