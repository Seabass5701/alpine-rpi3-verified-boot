#!/usr/bin/env sh


# This is a script to obtain the latest rpi-fw sources


# return error if script is ran independently
[ -z "$rpifwtdir" ] && {
  printf "%s\n" "Script must be sourced from another main script!"
  exit 1
}

# check for rpi-fw archive directory
[ -d "$rpifwtdir" ] || mkdir --parents "$rpifwtdir"


# set rpi-fw variables
rpifwver="1.20220830"
rpifwdir="$projdir/rpifw"
rpifwbdir="$rpifwdir/firmware-$rpifwver"
rpifwtfile="$rpifwtdir/$rpifwver.tar.gz"
rpifwurl="https://github.com/raspberrypi/firmware/archive/refs/tags/$(basename $rpifwtfile)"
startfile="$rpifwbdir/boot/start.elf"
fixupfile="$rpifwbdir/boot/fixup.dat"
bootlfile="$rpifwbdir/boot/bootcode.bin"

# download rpi-fw sources
[ -s "$rpifwtfile" ] || (
  printf "%s" "Downloading latest rpi-fw sources.. "
        curl --silent --location --output "$rpifwtfile" "$rpifwurl"
  printf "%s\n" ""
)

# check rpi-fw dir
[ -d "$rpifwdir" ] || mkdir "$rpifwdir"

# extract rpi-fw sources
[ -d "$rpifwbdir" ] || ( tar -xzf "$rpifwtfile" -C "$rpifwdir" )
