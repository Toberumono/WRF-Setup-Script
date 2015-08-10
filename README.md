# <a name="Readme"></a><a name="readme"></a>WRF Setup Script
## <a name="wii"></a>What is it?
This is a pair of scripts that automate the process of configuring a computer to run a WRF model and automate the process of cleaning a WRF and WPS installation in order to change how they are built.

## <a name="wdtsd"></a>What do these scripts do?

+ WRFSetup.sh
	1. Installs the libraries that WRF requires (this requires sudo).
	2. Sets the environment variables needed for WRF to configure correctly.
	3. Calls the WPS and WRF configure and compile scripts in the order needed.  All you need to do is enter 3 numbers and pick the version of WRF you want.
	4. If it is run on an existing WRF and/or WPS installation, it backs up namelist files and restores them automatically.
+ WRFClean.sh
	1. Cleans WRF and WPS installations.
	2. Backs up namelist.input and namelist.wps files so that the WRFSetup.sh script can restore them.

## <a name="wdtsnd"></a>What do these scripts not do?

+ WRFSetup.sh
	1. Does *not* download the tarballs for WRF, WPS, or the GEOGRID data - that would require implicit license agreements or something, and, besides, you should really know what you're downloading.  It's safer that way.
	2. Does *not* run on Windows.  It runs on Linux and OSX *only*, and assumes the gcc/gfortran compilers.  If you want to use a different compiler, change the compiler variable in the 'variables' file, but do so at your own risk.
	3. Does *not* run WRF.  That's a whole different process.  However, my WRF Runner script, available at [https://github.com/toberumono/WRF-Runner](https://github.com/toberumono/WRF-Runner) automates running WRF.

+ WRFClean.sh
	1. This script does *not* uninstall the programs that were installed by WRFSetup.sh - that is too risky as some of them were almost certainly already installed on the system prior to running WRFSetup.sh

## <a name="owsiut"></a>Okay, why should I use this?

1. Installing WRF and WPS is a huge pain if you haven't found some miracle guide that doesn't give a bunch of outdated or incorrect information about WRF's requirements.  This eliminates that problem to a large extent.
2. Setting up WRF can require a lot of trial and error, so having a method of resetting your WRF and WPS installations that also backs up your namlist files is really helpful.
  1. Yes, the WRFSetup script detects if namelist files were backed up by the WRFCleanup script.
  2. Why?  Because I accidently deleted my namelist files a few times before I wrote that.
3. Overall, using these scripts is simply easier.

## <a name="wloediniotuts"></a>What level of experience do I need in order to use this script?
This guide does assume a basic level of comfort with a UNIX-based prompt. If you are new to working with Terminal, tutorial one at http://www.ee.surrey.ac.uk/Teaching/Unix/ will cover everything you need for this tutorial. (Its prompt likely looks a bit different, but those commands are effectively identical across UNIX shells)

## Okay, how do I use this?

1. Scroll down (or click [here](#Usage))

## <a name="Usage"></a><a name="usage"></a>Usage

### A few notes
1. This script **requires** that you have the tarballs for WRF and WPS in the same directory as the script.
2. Make sure you do **not** have *any* spaces in the path to your WRF directory.  *This is* **essential** *to successful compilation of WRF and WPS.*
3. You will need sudo privileges the first time you run this script, unless you previously installed all of the required software (which is unlikely).

### Preparation
1. Either download this script via git or via the Download Zip button right below the git url (scroll up to the top and look at the column on the right).
  + If you're using git, this command should help (make sure you've cd'd into the directory you want to set up WRF and WPS): `git init; git pull https://github.com/Toberumono/WRF-Setup-Script.git`.
2. Download the tarballs for WRF, WPS, WRF-Chem and the WPS geogrid data (Available from the WRF website, [www2.mmm.ucar.edu/wrf/users/download/get_source.html](www2.mmm.ucar.edu/wrf/users/download/get_source.html)).

### Running the script
1. In terminal, cd into the directory into which you downloaded the script and tarballs.
2. Run `sudo ./WRFSetup.sh` if you are not sure if all of the required software is installed.  Otherwise, run `./WRFSetup.sh` (sudo is not required to configure or compile WRF or WPS).
3. Due to the nature of the geogrid downloads, there isn't a consistent naming convention that we can use.  Therefore, you will need to unpack the geogrid data yourself.
