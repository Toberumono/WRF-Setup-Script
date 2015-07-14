This script will help you configure and install some of the more complicated components of WRF and WPS.

This script is broken into two parts.  The first part performs the installation steps that cannot be automated through apt-get.  The second part configures and builds WRF and WPS.
Due to the nature of WRF and WPS, their configuration files are fairly out of date and, as a result, have an annoying tendency to insert invalid compiler arguments, or forget to add linker arguments.  Therefore, the second part of this script also uses perl regex to modify the configure files so that the build process will go smoothly.
In order to allow this script to be run more than once (so that you can quickly and relatively painlessly reconfigure WRF and WPS (by automatically running the aforementioned regexes) as needed), it will automatically detect whether each component is already installed prior to installing it.  This behavior can be changed via the variables file (see below).

In order to use this script, first make sure that you have the following packages installed:
gcc
g++
gfortran
jasper
lam-runtime
libcairo2-dev
libjasper-dev
libncarg-dev
libx11-dev
perl
pkg-config
zlibc
zlib-bin

2) Make sure that you have removed all existing versions of MPICH, Hydra, NetCDF, and HDF5.

3) Download the tarballs pf appropriate versions of MPICH, Hydra, NetCDF, NetCDF fortran, and HDF5, and place the tarballs in the same directory as the WRFSetup script.

4) Update the version numbers in the variables file and set use_ld to true if appropriate.
5) The first time you run the script, it must be run as sudo.  It will automatically unpack all of the tarballs, and then configure, test, and install everything, as well as print the output of all of the steps to appropriate log files.  Make sure to be careful when selecting the WRF configuration options.  However, if you mess up, you can always run this script again (and it'll run faster because it'll be able to skip all of the installations.
6) Once all of the installations are successful, you can run the script without sudo privileges.
