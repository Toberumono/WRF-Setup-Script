#!/usr/bin/env bash
script_path="$(pwd)"
#Grab variables
. variables
fet=$force_extract_tars #for convenience
verbose=false
retried=false
clean_brew=false
for param in "$@"; do
	if [ "$param" == "--verbose" ] || [ "$param" == "-v" ]; then
		verbose=true
	elif [ "$param" == "--retried" ]; then
		retried=true
	elif [ "$param" == "--clean-brew" ]; then
		clean_brew=true
	elif [ "$param" == "--help" ] || [ "$param" == "-h" ]; then
		echo "The help documentation is available online at https://github.com/Toberumono/WRF-Setup-Script"
		read -p "Would you like to open this page in your default browser? [Y/n]" yn
		yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]')
		[ "$yn" != "n" ] && open "https://github.com/Toberumono/WRF-Setup-Script#wrf-setup-script"
		unset yn
	fi
done

bash_upgrade() {
	if ( $retried ); then
		echo "Unable to fix the shell.  Please install Bash version 4.3+ and ensure that it is in your path."
		exit 1
	fi
	echo "The shell environment does not fully support redirection."
	if [ "$(uname -s)" == "Darwin" ]; then
		echo "This is due to Apple packaging a 8+ year-old version of Bash with their operating systems."
	fi
	if [ "$(which brew)" != "" ]; then
		if [ "$(brew info bash | grep '^Not installed')" != "" ]; then
			echo "Fortunately, because you have Homebrew installed, fixing this is incredibly quick."
			$brew install "bash"
			( $verbose ) && ./WRFSetup.sh "--retried" "--verbose" || ./WRFSetup.sh "--retried"
			exit $?
		else
			echo "Unable to fix the shell.  Please install Bash version 4.3+ and ensure that it is in your path."
			exit 1
		fi
	else
		echo "Unable to fix this without Homebrew.  Please install Homebrew or install Bash version 4.3+ manually."
		exit 1
	fi
}

if [ "${#BASH_VERSINFO[@]}" -gt "0" ]; then
	[ "${BASH_VERSINFO[0]}" -lt "4" ] && bash_upgrade
else
	echo "Unable to determine Bash version.  We are almost certainly not running in Bash."
	read -p "This is unsupported. [Press Enter to continue, any other key to quit] " yn
	[ "$yn" != "" ] && echo "" && exit 1 || echo "Continuing."
	unset yn
fi

( $verbose ) && brew="brew -v" || brew="brew" #Make brew verbose as needed

#Get the command to use when grabbing subscripts from GitHub.
if [ "$(which wget)" != "" ]; then
	wget_version="$(wget --version | grep -m 1 -oE '([0-9]+\.)*[0-9]+' | grep -m 1 -oE '^.*$')"
	if ( $verbose ); then
		pull_command="wget -O -"
	else
		[ "$(echo $wget_version | cut -d. -f1)" -gt "1" ] || [ "$(echo $wget_version | cut -d. -f2)" -ge "16" ] && \
			pull_command="wget --show-progress -qO -" || pull_command="wget -qO -"
	fi
else
	( $verbose ) && pull_command="curl -fL" || pull_command="curl -#fSL"
fi

#Download the get_profile.sh and unsudo.sh scripts from my repo and run their contents within the current shell via an anonymous file descriptor.
. <($pull_command "https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/common/get_profile.sh")
. <($pull_command "https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/common/unsudo.sh")

########################################################################
#####                       Support Functions                      #####
########################################################################

#Echoes the name of the tap if it was not already tapped
brew_tap() {
	if [ "$#" -gt "1" ]; then
		local tapped="$1"
		local tap="$2"
	else
		local tapped="$(brew tap)"
		local tap="$1"
	fi
	[ "$(echo $tapped | grep -F $tap)" == "" ] && $unsudo $brew tap "$tap"
}

brew_clean() {
	cmd="$unsudo $brew reinstall"
	for var in "$@"; do
		cmd="$cmd $(brew list | grep -oE $var)"
	done
	[ "$(brew list | grep -oE 'mpich')" != "" ] && $unsudo $brew uninstall --force mpich #mpich will be reinstalled momentarily
	[ "$cmd" != "" ] && $cmd
}

#echos 1 if the directory exists and has files in it
unpacked_test() {
	[ -d "$1" ] && [ "$(ls $1)" != "" ] && echo "1" || echo "0"
}

#Takes folder to test, tarball name, tar parameters, should it add '../' to the test path for the -C component
#The last two arguments are optional,
unpack_wrf_tarball() {
	[ "$#" -gt "2" ] && local params="$3" || local params="-xz"
	if ( ! $fet ) && [ "$(unpacked_test $1)" -eq "1" ]; then
		echo "Already unpacked the $2 tarball.  Skipping."
	else
		[ ! -e "$2" ] && return 1
		( [ "$#" -lt "4" ] || ( $4 ) ) && local outpath="$1/../" || local outpath="$1"
		$unsudo mkdir -p "$1"
		echo "Unpacking the $2 tarball."
		$unsudo pv "$2" | $unsudo tar $params "-C" "$outpath"
		echo "Unpacked the $2 tarball."
	fi
	return 0
}

unpack_fail() {
	read -n1 -p "$1 has not been unpacked and no $1 tarball was found. [Press Enter to continue, any other key to quit] " yn
	[ "$yn" != "" ] && echo "" && exit 1 || echo "Continuing"
	unset yn
}

#name of the component, name of namelist file, is it a backup or a restore (must equal "back up" or "restore"), path to folder with namelist file relative to directory (without a trailing '/') (optional)
backup_restore_namelist() {
	[ "$#" -gt "3" ] && [ "$4" != "" ] && local np="$4" || local np="."
	if [ -e "$np/$2" ]; then
		local backup_name="$backup_dir/$1.namelist.back"
		[ "$3" == "back up" ] && $unsudo cp "$np/$2" "$backup_name" || $unsudo cp "$backup_name" "$np/$2"
	else
		echo "No $2 to $3."
	fi
}

#########################################################################
#####            Unusual Variable Settings Confirmations            #####
#########################################################################

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

#########################################################################
#####                       Installation Logic                      #####
#########################################################################

use_pm=""
if [ "$force_package_manager" != "auto" ]; then use_pm="$force_package_manager";
elif [ "$(uname -s)" == "Darwin" ]; then use_pm="brew";
elif [ "$(which apt)" != "" ]; then use_pm="apt";
elif [ "$(which yum)" != "" ]; then use_pm="yum";
elif [ "$(which brew)" != "" ]; then use_pm="brew"; fi

checkable="pv git wget gcc gfortran ncl csh m4 doxygen"
#Install necessary software
if [ "$use_pm" == "apt" ]; then
	echo "Using apt."
	if [ "$unsudo" == "" ]; then
		echo "No sudo.  Skipping installation."
	else
		installation="build-essential pv gcc gfortran git wget curl libjasper-dev jasper zlib1g zlib1g-dev libncarg0 libpng12-0 libpng12-dev libx11-dev"
		installation=$installation" libcairo2-dev libpixman-1-dev csh m4 doxygen libhdf5-dev libnetcdf-dev netcdf-bin ncl-ncarg mpich"
		apt-get install $installation
	fi
elif [ "$use_pm" == "yum" ]; then
	echo "Using yum."
	if [ "$unsudo" == "" ]; then
		echo "No sudo.  Skipping installation."
	else
		installation="git wget jasper jasper-libs jasper-devel zlib zlib-devel libpng12 libpng12-devel libX11 libX11-devel"
		installation=$installation" cairo cairo-devel pixman pixman-devel m4 doxygen hdf5 hdf5-devel netcdf netcdf-fortran"
		installation=$installation" netcdf-devel netcdf-fortran-devel mpich tcsh"
		yum groupinstall 'Development Tools' && yum install $installation
	fi
elif [ "$use_pm" == "brew" ]; then
	echo "Using brew."
	( $clean_brew ) && brew_clean 'cairo' 'doxygen' 'fontconfig' 'freetype' 'gettext' 'glib' 'gmp' 'hdf5' 'isl' \
		'jasper' 'jpeg' 'libffi' 'libmpc' 'libpng' 'lzlib' 'mpfr' 'ncurses' 'netcdf' 'pixman' 'pkg-config' 'szip' 'tcsh' 'xz'
	fortran_flag="--default-fortran-flags"
	installation="pv ncurses cairo libpng szip lzlib pixman doxygen tcsh hdf5 jasper"
	#Tap stuff
	taps="$(brew tap)"
	brew_tap "$taps" 'homebrew/science'
	brew_tap "$taps" 'homebrew/dupes'
	brew_tap "$taps" 'caskroom/cask'
	#Install prep software
	[ "$(which git)" == "" ] && $unsudo $brew install "git"		|| echo "Found git"
	[ "$(which wget)" == "" ] && $unsudo $brew install "wget"	|| echo "Found wget"
	#If any of gcc, g++, or gfortran is not installed, install one via Homebrew.
	if [ "$(which gcc)" == "" ] || [ "$(which gfortran)" == "" ] || [ "$(which g++)" == "" ]; then
		($pull_command "https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/common/brew_gcc.sh") | $unsudo bash
		source "$profile"
	fi
	$unsudo $brew install brew-cask
	$unsudo $brew cask install ncar-ncl
	ncl_current="$(brew --prefix)/ncl-current"
	ncl_cask="$(ls -td1 $(brew --prefix)/ncl-* | grep -E '([0-9]+\.)*[0-9]+' | sort -g)"
	ln -sf "$ncl_cask" "$ncl_current"
	bash <($pull_command https://raw.githubusercontent.com/Toberumono/Miscellaneous/master/ncl-ncarg/brewed_path_fix.sh)
	source "$profile"
	[ "$(which m4)" == "" ] && installation="m4 "$installation || echo "Found m4"
	installation="$installation netcdf"' --with-fortran --with-cxx-compat'
	$unsudo $brew install $fortran_flag $installation
	export HOMEBREW_CC=gcc-5
	export HOMEBREW_CXX=g++-5
	$unsudo $brew install $fortran_flag 'mpich' '--build-from-source'
	unset HOMEBREW_CC HOMEBREW_CXX
else
	echo -n "Could not find "
	[ "$force_package_manager" != "auto" ] && echo -n "$use_pm." || echo -n "apt, yum, or brew."
	echo "  Proceed without attempting to install support software and libraries?"
	read -n1 -p "Press Enter to continue, any other key to quit." yn
	if [ "$yn" != "" ]; then
		echo ""
		echo "Setup Canceled.  Quitting."
		exit 1;
	else
		echo "Continuing without attempting to install support software and libraries."
	fi
fi

failed=""
for item in $checkable; do
	[ "$(which $item)" == "" ] && failed="$failed $item"
done
[ "$(which mpicc)" == "" ] || [ "$(which mpif90)" == "" ] && failed="$failed mpich"
[ "$(which nc-config)" == "" ] && failed="$failed netcdf"

if [ "$failed" != "" ]; then
	echo "Failed to install:${failed}."
	echo "Please install these items manually or try running this again with sudo privileges."
	exit 1
fi

#Rename .tars to correct capitalization
wrf_tar="WRFV$wrf_version"
wps_tar="WPSV$wrf_version"
obs_tar="OBSGRID"
chm_tar="WRFV$wrf_major_version-Chem-$wrf_version"

[ -e "$wrf_tar.TAR.gz" ] && $unsudo mv "$wrf_tar.TAR.gz" "$wrf_tar.tar.gz"
[ -e "$wps_tar.TAR.gz" ] && $unsudo mv "$wps_tar.TAR.gz" "$wps_tar.tar.gz"
[ -e "$obs_tar.TAR.gz" ] && $unsudo mv "$obs_tar.TAR.gz" "$obs_tar.tar.gz"
[ -e "$chm_tar.TAR.gz" ] && $unsudo mv "$chm_tar.TAR.gz" "$chm_tar.tar.gz"

#Unpack tars if needed
( $verbose ) && verbose_unpack="v" || verbose_unpack=""
unpack_wrf_tarball "$wrf_path" "$wrf_tar.tar.gz" "-xz${verbose_unpack}"
[ $? != 0 ] && unpack_fail "WRF"

unpack_wrf_tarball "$wps_path" "$wps_tar.tar.gz" "-xz${verbose_unpack}"
[ $? != 0 ] && unpack_fail "WPS"

if ( $build_obsgrid ); then
	unpack_wrf_tarball "$obsgrid_path" "$obs_tar.tar.gz" "-xz${verbose_unpack}"
	[ $? != 0 ] && unpack_fail "OBSGRID"
fi

unpack_wrf_tarball "$wrf_chem_path" "$chm_tar.tar.gz" "-xz${verbose_unpack}"
[ $? != 0 ] && unpack_fail "WRF-Chem"

unpack_wrf_tarball "$geog_path" "geog_complete.tar.bz2" "-xj${verbose_unpack}" false
if [ $? != 0 ]; then
	unpack_wrf_tarball "$geog_path" "geog_minimum.tar.bz2" "-xj${verbose_unpack}" false
	[ $? != 0 ] && unpack_fail "GEOGRID"
fi

netcdf_prefix="$(nc-config --prefix)"

#Set environment variables
if [ "$unsudo" == "" ]; then #Export variables for when this script is not run with sudo.
	export WRFIO_NCD_LARGE_FILE_SUPPORT=1
	export NETCDF=$netcdf_prefix
	export $mpich_compilers
else #Add the environment variables to $unsudo
	unsudo=$unsudo" WRFIO_NCD_LARGE_FILE_SUPPORT=1 NETCDF=$netcdf_prefix $mpich_compilers"
fi

#Takes the following arguments: module name, path to unpacked files, name of the namelist file, path to the namelist file relative to the path to unpacked files
#function to call with module-specific commands (should configure and compile the module as well as perform any other steps unique to the module)
#message to display if the unpacked files cannot be located
#paths to the built executables relative to the unpacked files. (This is used to test for whether the module is already compiled)
general_wrf_component_setup() {
	local mod_name="$1" && shift
	local mod_path="$1" && shift
	local nl_name="$1" && shift
	local nl_path="$1" && shift
	local function_call="$1" && shift
	local locate_error_message="$1" && shift

	if [ ! -e "$mod_path" ] || [ ! -d "$mod_path" ]; then
		echo "$locate_error_message"
		return 1
	fi

	cd "$mod_path"

	local built=false
	if [ "$#" -gt "0" ]; then
		built=true
		for file in "$@"; do
			[ ! -e "$file" ] && built=false
		done
	fi

	local yn="y"
	if ( $built ); then #Test for the executables that will always be built
		read -p "$mod_name has already been compiled. Would you like to recompile it? [y/N] " yn
		yn=$(echo "${yn:0:1}" | tr '[:upper:]' '[:lower:]') #Convert the user's response to lowercase and keep only the first letter.  This way, yes and no will also work.
	fi
	if [ "$yn" == "y" ]; then
		#Back up namelist
		( $keep_namelists ) && ( backup_restore_namelist "$mod_name" "$nl_name" "back up" "$nl_path" ) || echo "Skipping backing up the $mod_name Namelist file."

		$function_call

		#Restore namelist
		( $keep_namelists ) && ( backup_restore_namelist "$mod_name" "$nl_name" "restore" "$nl_path" ) || echo "Skipping restoring the $mod_name Namelist file."
	else
		echo "Skipping reconfiguring and recompiling $mod_name."
	fi
	cd "$script_path"
}

gfortran_version="$(gfortran -dumpversion | cut -d. -f1)"
gfortran_major_version="$gfortran_version"
if [ "$gfortran_version" -lt "5" ]; then
	gfortran_version="$(gfortran -dumpversion | cut -d. -f1,2)"
fi

#Configure and Compile
wrf_setup() {
	$unsudo ./configure 2>&1 | $unsudo tee ./configure.log #Configure WRF, and output to both a log file and the terminal.

	#Run the WRF regex fixes if they are enabled in 'variables'
	#This just adds -lgomp to the LIB_EXTERNAL variable.
	replacement='s/gcc/gcc-'"$gfortran_version"'/igs'
	( $use_wrf_regex_fixes ) && [ "$gfortran_major_version" -ge "5" ] && $unsudo perl -0777 -i -pe $replacement ./configure.wrf
	( $use_wrf_regex_fixes ) && $unsudo perl -0777 -i -pe 's/(LIB_EXTERNAL[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lgomp\n/is' ./configure.wrf || echo "Skipping WRF regex fixes."

	#$unsudo ./compile wrf 2>&1 | $unsudo tee ./compile_wrf.log #Compile WRF, and output to both a log file and the terminal.
	$unsudo ./compile #Calling compile without arguments causes a list of valid test cases and such to be printed to the terminal.

	echo "Please enter the test case you would like to run (this can include the '-j n' part) or wrf [Default: wrf]:"
	local test_case=""
	local b="wrf"
	read test_case
	test_case=$(echo "$test_case" | tr '[:upper:]' '[:lower:]')
	[ "$test_case" != "" ] && b="$test_case"
	$unsudo ./compile "$b" 2>&1 | $unsudo tee ./compile_"$b".log
}

general_wrf_component_setup "WRF" "$wrf_path" "namelist.input" "./run" "wrf_setup" \
"Unable to locate the $wrf_path directory.  Unable compile or configure WRF.  This will likely cause WPS to fail." \
"./run/wrf.exe"

wps_setup() {
	$unsudo ./configure #2>&1 | $unsudo tee ./configure.log #The WPS configure does something that messes with logging, so this is disabled for now.
	echo "For reasons unknown, WPS's configure sometimes adds invalid command line options to DM_FC and DM_CC and neglects to add some required links to NCARG_LIBS."
	echo "However, this script fixes those problems, so... No need to worry about it."
	if ( $use_wps_regex_fixes ); then
		#Replace gcc with gcc-5 if needed in the configure.wps file
		( "$gfortran_major_version" -ge "5" ) && $unsudo perl -0777 -i -pe 's/gcc/gcc-'"$gfortran_version"'/igs' ./configure.wps
		#Add -lcairo, -lfontconfig, -lpixman-1, and -lfreetype to NCARG_LIBS
		$unsudo perl -0777 -i -pe 's/(NCARG_LIBS[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lcairo -lfontconfig -lpixman-1 -lfreetype\n/is' ./configure.wps
		#Add -lgomp to WRF_LIBS
		$unsudo perl -0777 -i -pe 's/(WRF_LIB[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lgomp\n/is' ./configure.wps
	else
		echo "Skipping WPS regex fixes."
	fi
	$unsudo ./compile 2>&1 | $unsudo tee ./compile.log
	$unsudo ./compile plotgrids 2>&1 | $unsudo tee ./compile_plotgrids.log
}

general_wrf_component_setup "WPS" "$wps_path" "namelist.wps" "." "wps_setup" \
"Unable to locate the $wps_path directory.  Unable compile or configure WPS." \
"./geogrid.exe" "./metgrid.exe" "./ungrib.exe"

obsgrid_setup() {
	$unsudo ./configure #2>&1 | $unsudo tee ./configure.log #The WPS configure does something that messes with logging, so this is disabled for now.
	if ( $use_obsgrid_regex_fixes ); then
		#Replace g95 with gfortran in the configure.oa file
		$unsudo perl -0777 -i -pe 's/g95/gfortran/igs' ./configure.oa
		#Remove -fendian from the configure.oa file
		$unsudo perl -0777 -i -pe 's/[ \t]*(-fendian=($\([^\(]*\))|[^ \t\n]*))[ \t]*//igs' ./configure.oa
		#Add -lcairo, -lfontconfig, -lpixman-1, and -lfreetype to NCARG_LIBS
		$unsudo perl -0777 -i -pe 's/(NCARG_LIBS[ \t]*=([^\\\n]*\\\n)*[^\n]*)\n/$1 -lcairo -lfontconfig -lpixman-1 -lfreetype\n/is' ./configure.oa
	fi
	$unsudo ./compile 2>&1 | $unsudo tee ./compile.log
}

if ( $build_obsgrid ); then
	general_wrf_component_setup "OBSGRID" "$obsgrid_path" "namelist.oa" "." "obsgrid_setup" \
	"Unable to locate the $obsgrid_path directory.  Unable compile or configure OBSGRID." \
	"./obsgrid.exe"
fi

echo "Please confirm that all of the executables have been appropriately created in the WRFV$wrf_major_version and WPS directories."
echo "You will still need to get boundary data for your simulations.  If you want an automated script to do this, see my WRF-Runner project at github.com/Toberumono/WRF-Runner"
