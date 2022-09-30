#!/usr/bin/env sh


# Main variables
cpuarch="aarch64"
distro="alpine"
distrover="3.16.2"


# Main directories
basedir="$(pwd)"
projdir="$basedir/work"
archdir="$projdir/tar"
instdir="$projdir/out"
tcdir="$basedir/toolchain"
osdir="$basedir/os"


# Ensure existence of main directories
for maindir in $projdir $archdir $instdir ; do
  [ -d $maindir ] || mkdir $maindir
done


# Archive [Tar] directories
tctdir="$archdir/toolchain"
ostdir="$archdir/os"
uboottdir="$archdir/uboot"
armtftdir="$archdir/armtf"
rpifwtdir="$archdir/rpifw"



# Obtain a toolchain (if not found), and
# add it to the 'PATH' variable
. scripts/toolchain.sh
PATH="$tcpath:$PATH"


# Obtain os files (if not found), and set
# necessary variables for later on in the build
. scripts/os.sh


# Obtain u-boot sources (if not found), and source
# variables/functions for the build process
. scripts/uboot.sh
build_uboot


# Obtain arm-tf sources (if not found), and source
# variables/functions for the build process
. scripts/armtf.sh
build_armtf


# Obtain rpi-fw sources (if not found), and source
# variables/functions for the build process
. scripts/rpifw.sh


# Perform Installation
. scripts/install.sh
install

printf "%s\n\n" "Finished!"

printf "%s\n" "Make sure to copy the files from \"$instdir/boot\" to boot-partition!!"
