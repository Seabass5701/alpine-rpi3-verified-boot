#!/usr/bin/env sh


# This is a script to obtain a toolchain, extract it,
# and add it to the local 'PATH' variable.


# return error if script is ran independently
[ -z "$tcdir" ] && {
  printf "%s\n" "Script must be sourced from another main script!"
  exit 1
}

# check for toolchain archive directory
[ -d "$tctdir" ] || mkdir $tctdir

# check for toolchain directory
[ -d "$tcdir" ] || mkdir $tcdir

# check whether architecture is compatible
case "$(arch)" in
   "x86_64") ;;
          *) printf "%s\n" "Unsupported architecture: $(arch)"; exit 1 ;;
esac

# set compiler
tcver="11.3.rel1"
target="$cpuarch-none-elf"
tctfile="$tctdir/arm-gnu-toolchain-$tcver-$(arch)-$target.tar.xz"
tcsigfile="$tctdir/$tctfile.asc"
tchashfile="$tctdir/$tctfile.sha256asc"
tcrepo="https://developer.arm.com/-/media/Files/downloads/gnu/$tcver/binrel"
tcurl="$tcrepo/$(basename $tctfile)"


# download the toolchain and verify hashes
[ -s "$tctfile" ] || (
  printf "%s" "Downloading latest toolchain release files.. "
  curl --silent --location --output "$tctfile" "$tcurl"
  curl --silent --location --output "$tctfile.sha256asc" "$tcurl.sha256asc"
  printf "%s\n" "OK!"
  printf "%s" "Verifying toolchain hash.. "
  [ "$(sha256sum $tctfile|cut -d ' ' -f1)" = "$(cat "$tctfile.sha256asc"|cut -d ' ' -f1)" ] && printf "%s\n" "OK!" || {
    printf "%s\n" "Toolchain hash-verification failed!"
    exit 1
  };
);


# extract the toolchain (once successfully downloaded)
[ -d "$tcdir/arm-gnu-toolchain-$tcver-$(arch)-$target" ] || (
  printf "%s\n" "Toolchain will be placed in: \"$tcdir\"";
  tar -xJf "$tctfile" -C "$tcdir";
);

tcpath="$tcdir/arm-gnu-toolchain-$tcver-$(arch)-$target/bin"
