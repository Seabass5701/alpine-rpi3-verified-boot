#!/usr/bin/env sh


# This is a script to obtain the latest os files of
# the desired distro, which we will patch later on.


# return error if script is ran independently
[ -z "$ostdir" ] && {
  printf "%s\n" "Script must be sourced from another main script!"
  exit 1
}

# check for os archive directory
[ -d "$ostdir" ] || mkdir "$ostdir"

# check for os dir
[ -d "$osdir" ] || mkdir "$osdir"

# set distro variables
case "$distro" in
  "alpine")
    ostfile="$ostdir/$distro-rpi-$distrover-$cpuarch.tar.gz"
    osrepo="https://dl-cdn."$distro"linux.org/$distro/v$(echo $distrover|sed 's/\.\{1\}[0-9]\+$//')/releases/$cpuarch"
    osurl="$osrepo/$(basename $ostfile)"
    dtb="$osdir/bcm2710-rpi-3-b-plus.dtb"
    kernel="$osdir/boot/vmlinuz-rpi"
    ramdisk="$osdir/boot/initramfs-rpi"
    modloop="$osdir/boot/modloop-rpi"
    overlays="$osdir/overlays"
    apks="$osdir/apks"
    ;;
esac

# download and verify distro os files
[ -s "$ostfile" ] || (
  printf "%s" "Downloading latest os release files.. "

  case "$distro" in
    "alpine")
      curl --silent --output "$ostfile" "$osurl"
      curl --silent --output "$ostfile.sha256" "$osurl.sha256"
      verify_hash() ( [ "$(sha256sum $ostfile|cut -d ' ' -f1)" = "$(cat "$ostfile.sha256"|cut -d ' ' -f1)" ] )
      ;;
  esac

  printf "%s\n" ""

  printf "%s" "Verifying os hash.. "

  verify_hash && printf "%s\n" "OK!" || {
    printf "%s\n" "OS hash-verification failed!"
    exit 1
  };
)

# extract distro os files
[ -n "$(ls -A "$osdir")" ] || (
  case "$distro" in
    "alpine") tar -xzf "$ostfile" -C "$osdir";;
  esac
)
