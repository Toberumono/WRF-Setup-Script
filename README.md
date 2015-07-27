#<a name="Readme"></a><a name="readme"></a>WRF Setup Script

##<a name="wdtsd"></a>What does this script do?

1. Installs the libraries that WRF requires (this requires sudo).
2. Sets the environment variables needed for WRF to configure correctly.
3. Calls the WPS and WRF configure and compile scripts in the order needed.  All you need to do is enter 3 numbers and pick the version of WRF you want.
4. If run on an existing WRF and/or WPS installation, it backs up namelist files and restores them automatically.

##<a name="wdtsnd"></a>What does this script not do?

1. This script does *not* download the tarballs for WRF, WPS, or the GEOGRID data - that would require implicit license agreements or something, and, besides, you should really know what you're downloading.  It's safer that way.
2. This script runs on Linux and OSX, and assumes the gcc/gfortran compilers.  If you want to use a different compiler, change the compiler variable in the 'variables' file, but do so at your own risk.
3. This script *does not* run WRF.  That's a whole different process.  Check out my WRF Runner script at [https://github.com/toberumono/WRF-Runner](https://github.com/toberumono/WRF-Runner) for a program that automates that rather confusing process.

##<a name="owsiut"></a>Okay, why should I use this?

1. Installing WRF and WPS is a huge pain if you haven't found some miracle guide that doesn't give a bunch of outdated or incorrect information about WRF's requirements.  This eliminates that problem to a large extent.
2. Setting up WRF can require a lot of trial and error, so having a method of resetting your WRF and WPS installations that also backs up your namlist files is really helpful.
  1. Yes, the WRFSetup script detects if namelist files were backed up by the WRFCleanup script.
  2. Why?  Because I accidently deleted my namelist files a few times before I wrote that.
3. Overall, using these scripts is simply easier.

##<a name="wloediniotuts"></a>What level of experience do I need in order to use this script?
1. You need to be able to intelligently select downloads (aka read the instructions)
2. You need to be familiar with a few terminal commands:
  1. 'cd' (You will have to change directories a couple times)
  2. 'mkdir' (Probably - having a good directory structure is important)
  3. 'sudo' (You will need admin privelidges in order to run this script the first time)
3. That's it, really.

##Okay, how do I use this?
1. Scroll down (or click [here](#Usage))

##<a name="Usage"></a><a name="usage"></a>Usage

###A few notes
1. This script **requires** that you have the tarballs for WRF and WPS in the same directory as the script.
2. Make sure you do **not** have *any* spaces in the path to your WRF directory.  *This is **essential** to successful compilation of WRF and WPS.*
3. You will need sudo privliges the first time you run this script, unless you previously installed all of the required software (which is unlikely).

###Preparation
1. Either download this script via git or via the Download Zip button right below the git url (scroll up to the top and look at the column on the right).
  1. If you're using git, this command should help (make sure you've cd'd into the directory you want to set up WRF and WPS): `git init; git pull https://github.com/Toberumono/WRF-Setup-Script.git`.
2. Download the tarballs for WRF, WPS, WRF-Chem and the WPS geogrid data (Available from the WRF website, [www2.mmm.ucar.edu/wrf/users/download/get_source.html](www2.mmm.ucar.edu/wrf/users/download/get_source.html)).

###Running the script
1. In terminal, cd into the directory into which you downloaded the script and tarballs.
2. Run `sudo ./WRFSetup.sh`
3. That's it.
