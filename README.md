#WRF Setup Script
##What is it?
This is a pair of scripts that automate the process of configuring a computer to run a WRF model and automate the process of cleaning a WRF and WPS installation in order to change how they are built.

##What do these scripts do?

+ WRFSetup.sh
	- Installs the libraries that WRF requires (this requires sudo on Linux).
	- Sets the environment variables needed for WRF to configure correctly.
	- Calls the WPS and WRF configure and compile scripts in the order needed.  All you need to do is enter 3 numbers and pick the version of WRF you want.
	- If it is run on an existing WRF and/or WPS installation, it backs up namelist files and restores them automatically.
+ WRFClean.sh
	- Cleans WRF and WPS installations.
	- Backs up namelist.input and namelist.wps files so that the WRFSetup.sh script can restore them.

##What do these scripts not do?
* Both
	+ Do not run on Windows.  They are Bash scripts, and therefore run on Linux and OSX *only*.<br>
	Furthermore, they assume gcc/gfortran compilers.
		- If you want to use a different compiler, then you can change the compiler variable in the variables file; however, it has only been tested with gcc/gfortran.
* WRFSetup.sh
	+ Does not download the tarballs for WRF, WPS, or the GEOGRID data - that would require circumventing UCAR's login system.
	+ Does not run WRF.  My [WRF Runner](https://github.com/toberumono/WRF-Runner) project handles that.
* WRFClean.sh
	+ Does not uninstall the libraries and support programs that were installed by WRFSetup.sh - that is far too risky because some of them are almost certainly used by other programs.

##Why should I use this?

* Manually setting up WRF and WPS requires setting a decent number of environment variables and executing commands that may not be familiar to an average user.
	- Both of these can be intimidating, and some of them require information that can be difficult for a user to look up, but trivial for a script to find.
* Setting up WRF and WPS entails a decent amount of trial and error to figure out which configuration works best for you.
	- These scripts automatically back up the important configuration files so that you don't have to worry about it.

##What level of experience do I need in order to use this script?
This guide does assume a basic level of comfort with a UNIX-based prompt. If you are new to working with Terminal, tutorial one at [http://www.ee.surrey.ac.uk/Teaching/Unix/](http://www.ee.surrey.ac.uk/Teaching/Unix/) will cover everything you need for this tutorial. (Its prompt likely looks a bit different, but those commands are effectively identical across UNIX shells)

##Okay, how do I use this?

1. Scroll down to the [Usage](#usage) section.

##Usage
###A few notes

1. This script must be run in the same directory as the downloaded WRF, WPS, WRF-Chem, and GEOGRID tarballs.
2. The path to the downloaded files *cannot* contain *any* spaces - WRF will not compile if the path has spaces.
3. This script uses [Homebrew](http://brew.sh) on Macs and either Apt or [Linuxbrew](https://github.com/Homebrew/linuxbrew) on Linux.

###Permissions Needed

+ Mac OSX
	+ `WRFSetup.sh`
		- This script will require sudo privileges to set up [Caskroom](https://github.com/caskroom).
		- Once [Caskroom](https://github.com/caskroom) has been set up, it does not need sudo privileges.
	+ `WRFClean.sh`
		- This script only interacts with WRF and WPS, and does not, therefore, require sudo.
+ Linux
	+ `WRFSetup.sh`
		- This script will require sudo privileges when it is first run because it uses apt.
		- Once the support software has been installed, it does not need sudo privileges.
	+ `WRFClean.sh`
		- This script only interacts with WRF and WPS, and does not, therefore, require sudo.

###Preparation

1. On Mac, install [Homebrew](http://brew.sh).
2. If your system does not have Git (run `which git` in Terminal, if a path shows up, your system has Git), run:
	+ Debian Linux (e.g. Ubuntu):
		- `sudo apt-get install git`
	+ Mac OSX
		- `brew install git`
3. Create an empty directory.
4. In Terminal, cd into that directory and run:

	```bash
	git clone -b "$(git ls-remote --tags https://github.com/Toberumono/WRF-Setup-Script.git | grep -o -E '([0-9]+\.)*[0-9]+$' | sort -g | tail -1)" --depth=1 "https://github.com/Toberumono/WRF-Setup-Script.git" .
	```
	+ This command grabs the latest tagged version of the scripts from GitHub and downloads them into the newly-created directory.
5. Download the tarballs (tar files) for WRF-ARW, WPS, WRF-Chem and the WPS GEOGRID data (Available from the UCAR website, [http://www2.mmm.ucar.edu/wrf/users/download/get_source.html](http://www2.mmm.ucar.edu/wrf/users/download/get_source.html)).
6. Move the downloaded tar files into the directory containing the scripts.
7. As of this writing, WRF Version 3.7.1 is the latest stable release.  You may need to change the version numbers in the variables file to match the version that you downloaded.

###Running the Script
1. In terminal, cd into the directory into which you downloaded the script and tarballs.
2. Run `sudo ./WRFSetup.sh` if you have sudo privileges and are not certain that all of the required support software and libraries have been installed and you are not using [Homebrew](http://brew.sh).
	+ Depending on how many libraries need to be installed, this could take a *long* time.
	+ If you have not already installed gcc/gfortran on your system, this can take a *very long* time and will likely look like it is hanging.  Give it time (sometimes over an hour), and it will complete.
	+ There may be multiple warnings about things already being tapped or installed.  This is normal - it just means that 'brew has detected that some of the requirements were already installed.
3. In subsequent runs, the script can be run without sudo regardless of operating system.