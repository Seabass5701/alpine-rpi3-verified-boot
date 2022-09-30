#!/usr/bin/env sh
# vim: set ts=2 sw=2:


# This is a script to obtain the latest armtf sources


# return error if script is ran independently
[ -z "$armtftdir" ] && {
  printf "%s\n" "Script must be sourced from another main script!"
  exit 1
}

# check for armtf archive directory
[ -d "$armtftdir" ] || mkdir --parents "$armtftdir"


# set armtf variables
armtfver="2.7.0"
armtfdir="$projdir/armtf"
armtfbdir="$armtfdir/trusted-firmware-a-$armtfver"
armtftfile="$armtftdir/trusted-firmware-a-$armtfver.tar.gz"
armtfurl="https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/snapshot/$(basename $armtftfile)"
armtfstub="$armtfbdir/build/rpi3/release/armstub8.bin"


# download armtf sources
[ -s "$armtftfile" ] || (
  printf "%s\n" "Downloading latest arm-tf sources.."
  curl --silent --output "$armtftfile" "$armtfurl"
)

# check armtf dir
[ -d "$armtfdir" ] || mkdir "$armtfdir"

# extract armtf sources
[ -d "$armtfbdir" ] || ( tar -xzf "$armtftfile" -C "$armtfdir" )

armtf_make() (
  CROSS_COMPILE=$target- make -C "$armtfbdir" -j$(($(nproc) + 2)) "${@}" >/dev/null 2>&1
)

armtf_build_stage1() (
  printf "%s" "Performing armtf build.. "

  [ -s "$armtfstub" ] && armtf_make distclean

  armtf_make BL33="$ubootbin" ENABLE_STACK_PROTECTOR=strong PLAT=rpi3

  printf "%s\n" ""
)

build_armtf() ( armtf_build_stage1 )
