# <a name="Readme"></a><a name="readme"></a>WRF Setup Script
## <a name="wii"></a>What is it?
This is a pair of scripts that automate the process of configuring a computer to run a WRF model and automate the process of cleaning a WRF and WPS installation in order to change how they are built.

## <a name="wdtsd"></a>What do these scripts do?

+ WRFSetup.sh
	- Installs the libraries that WRF requires (this requires sudo on Linux).
	- Sets the environment variables needed for WRF to configure correctly.
	- Calls the WPS and WRF configure and compile scripts in the order needed.  All you need to do is enter 3 numbers and pick the version of WRF you want.
	- If it is run on an existing WRF and/or WPS installation, it backs up namelist files and restores them automatically.
+ WRFClean.sh
	- Cleans WRF and WPS installations.
	- Backs up namelist.input and namelist.wps files so that the WRFSetup.sh script can restore them.

## <a name="wdtsnd"></a>What do these scripts not do?

* Do not run on Windows.  They are Bash scripts, and therefore run on Linux and OSX *only*.<br>
	Furthermore, they assume gcc/gfortran compilers.
	+ If you want to use a different compiler, then you can change the compiler variable in the variables file; however, it has only been tested with gcc/gfortran.
* WRFSetup.sh
	+ Does not download the tarballs for WRF, WPS, or the GEOGRID data - that would require circumventing UCAR's login system.
	+ Does not run WRF.  My [WRF Runner](https://github.com/toberumono/WRF-Runner) project handles that.
* WRFClean.sh
	+ Does not uninstall the libraries and support programs that were installed by WRFSetup.sh - that is far too risky because some of them are almost certainly used by other programs.

## <a name-"wsiut"></a>Why should I use this?

* Manually setting up WRF and WPS requires setting a decent number of environment variables and executing commands that may not be familiar to an average user.
	- Both of these can be intimidating, and some of them require information that can be difficult for a user to look up, but trivial for a script to find.
* Setting up WRF and WPS entails a decent amount of trial and error to figure out which configuration works best for you.
	- These scripts automatically back up the important configuration files so that you don't have to worry about it.

## <a name="wloediniotuts"></a>What level of experience do I need in order to use this script?
This guide does assume a basic level of comfort with a UNIX-based prompt. If you are new to working with Terminal, tutorial one at [http://www.ee.surrey.ac.uk/Teaching/Unix/](http://www.ee.surrey.ac.uk/Teaching/Unix/) will cover everything you need for this tutorial. (Its prompt likely looks a bit different, but those commands are effectively identical across UNIX shells)

## Okay, how do I use this?

1. Scroll down to the [Usage](#Usage) section.

## <a name="Usage"></a><a name="usage"></a>Usage
### A few notes

1. This script **requires** that you have the tarballs for WRF, WPS, WRF-Chem, and your preferred GEOGRID data (either the minimum set or the complete set) in the same directory as the script.
2. Make sure you do **not** have *any* spaces in the path to the directory containing the script and tarballs.  *This is* **essential** *to successful compilation of WRF and WPS.*
3. Unless you have previously installed [Homebrew](http://brew.sh) or [Linuxbrew](https://github.com/Homebrew/linuxbrew) (as appropriate for your operating system), you will need sudo privileges the first time you run this script.

### Preparation
1. Either download this script via git or via the Download Zip button right below the git url (scroll up to the top and look at the column on the right).
  + If you're using git, cd into the directory you want to set up WRF and WPS and run:<br>
    `git clone https://github.com/Toberumono/WRF-Setup-Script.git .`
2. Download the tarballs for WRF, WPS, WRF-Chem and the WPS GEOGRID data (Available from the WRF website, [www2.mmm.ucar.edu/wrf/users/download/get_source.html](www2.mmm.ucar.edu/wrf/users/download/get_source.html)).

### Running the script
1. In terminal, cd into the directory into which you downloaded the script and tarballs.
2. Run `sudo ./WRFSetup.sh` if you are not sure if all of the required software is installed and you do not have [Homebrew](http://brew.sh) or [Linuxbrew](https://github.com/Homebrew/linuxbrew) installed.  Otherwise, run `./WRFSetup.sh` (sudo is not required to configure or compile WRF or WPS and Homebrew/Linuxbrew do not require sudo in order to install the support software).
	+ Depending on how many libraries need to be installed, this could take a *long* time.
	+ There may be a bunch of warnings about things already being tapped or installed.  This is normal - it just means that 'brew has detected that some of the requirements were already installed.
