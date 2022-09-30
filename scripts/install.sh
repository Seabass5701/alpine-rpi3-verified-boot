#!/usr/bin/env sh


# This script installs the generated files necessary
# for verified boot on the Raspberry Pi

install() (
  # check installation dir
  [ -d "$instdir/boot" ] || mkdir "$instdir/boot"

  # perform install
  cp "$armtfstub" "$fitimg" "$startfile" "$fixupfile" "$bootlfile" "$instdir/boot"
  cp -Rf "$overlays" "$apks" "$instdir/boot"

  case "$distro" in
      "alpine") cp "$modloop" "$instdir/boot" ;;
  esac

  # generate config.txt
  printf "%s\n\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n\n%s\n%s\n" '[pi3+]' \
                                                            '# main configuration' \
                                                            'enable_uart=1' \
                                                            '# required for booting ATF (BL1 starts at 0x128)' \
                                                            '# stop "start.elf" from filling in ATAGS (memory from 0x100)' \
                                                            'disable_commandline_tags=1' \
                                                            '# load ATF armstub file (armstub8.bin)' \
                                                            'armstub=armstub8.bin' \
                                                            '# enable aarch64 execution state' \
                                                            'arm_64bit=1' \
                                                            > "$instdir/boot/config.txt"
)
