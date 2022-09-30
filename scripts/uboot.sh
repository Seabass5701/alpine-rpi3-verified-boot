#!/usr/bin/env sh


# This is a script to obtain the latest u-boot sources


# return error if script is ran independently
[ -z "$uboottdir" ] && {
  printf "%s\n" "Script must be sourced from another main script!"
  exit 1
}

# check for u-boot archive directory
[ -d "$uboottdir" ] || mkdir --parents "$uboottdir"


# set u-boot variables
ubootver="2022.07"
ubootdir="$projdir/uboot"
ubootbdir="$ubootdir/u-boot-v$ubootver"
uboottfile="$uboottdir/u-boot-v$ubootver.tar.gz"
ubooturl="https://source.denx.de/u-boot/u-boot/-/archive/v$ubootver/$(basename $uboottfile)"
ubootdefconfig="$basedir/u-boot-rpi3-$ubootver-defconfig"
ubootdtb="$ubootbdir/arch/arm/dts/bcm2837-rpi-3-b-plus.dtb"
fitdir="$ubootdir/fit"
ubootenv="$fitdir/uboot.env.txt"

# download u-boot sources
[ -s "$uboottfile" ] || (
  printf "%s" "Downloading latest u-boot sources.. "
  curl --silent --output "$uboottfile" "$ubooturl"
  printf "%s\n" ""
)

# check u-boot dir
[ -d "$ubootdir" ] || mkdir "$ubootdir"

# extract u-boot sources
[ -d "$ubootbdir" ] || ( tar -xzf "$uboottfile" -C "$ubootdir" )

# return error if default defconfig not found
[ -s "$ubootdefconfig" ] || {
  printf "%s\n" "Default u-boot defconfig file missing! ($(basename $ubootdefconfig))"
  exit 1
}

# apply patches for u-boot PSCI-compatibility
# (aarch64 only!)
patch_uboot() (
  printf "%s" "Patching u-boot for PSCI-support.. "
  sed -i '/enable-method = "brcm,bcm2836-smp"/d' "$ubootbdir/arch/arm/dts/bcm2837.dtsi"
  sed -i 's/enable-method = "spin-table";/enable-method = "psci";/g' "$ubootbdir/arch/arm/dts/bcm2837.dtsi"
  sed -i 's/cpu-release-addr \= .*/d-cache-size = <0x8000>;\n\t\t\td-cache-line-size = <64>;\n\t\t\td-cache-sets = <128>; \/\/ 32KiB(size)\/64(line-size)=512ways\/4-way set\n\t\t\ti-cache-size = <0x8000>;\n\t\t\ti-cache-line-size = <64>;\n\t\t\ti-cache-sets = <256>; \/\/ 32KiB(size)\/64(line-size)=512ways\/2-way set\n\t\t\tnext-level-cache = <\&l2>;/g' "$ubootbdir/arch/arm/dts/bcm2837.dtsi"
  sed -i '96a\\n\t\t\/* Source for cache-line-size + cache-sets\n\t\t * https:\/\/developer\.arm\.com\/documentation\/ddi0500\n\t\t * \/e\/level-2-memory-system\/about-the-l2-memory-system?lang=en\n\t\t * Source for cache-size\n\t\t * https:\/\/datasheets\.raspberrypi\.com\/cm\/cm1-and-cm3-datasheet\.pdf\n\t\t *\/\n\t\tl2: l2-cache0 {\n\t\t\tcompatible = "cache";\n\t\t\tcache-size = <0x80000>;\n\t\t\tcache-line-size = <64>;\n\t\t\tcache-sets = <512>; \/\/ 512KiB(size)\/64(line-size)=8192ways\/16-way set\n\t\t\tcache-level = <2>;\n\t\t};\n\t};\n\n\tpsci {\n\t\tcompatible = "arm,psci-1.0", "arm,psci-0.2";\n\t\tmethod = "smc";' "$ubootbdir/arch/arm/dts/bcm2837.dtsi"
  printf "%s\n" ""
)

# generate a u-boot environment file
generate_ubootenv() (
  printf "%s" "Generating a u-boot environment file.. "

  printf "%s\n%s\n\n%s\n%s\n%s\n%s\n\n%s\n" '# Required delay before loading' \
                                            'bootdelay=2.5' \
                                            '# I/O' \
                                            'stderr=serial,vidconsole' \
                                            'stdin=serial,usbkbd' \
                                            'stdout=serial,vidconsole' \
                                            '# CPU settings' \
                                            > "$ubootenv"

  case "$cpuarch" in
    "aarch64")
      printf "%s\n%s\n\n" 'cpu=armv8' \
                          'smp=on' \
                          >> "$ubootenv"
      ;;
    "arm")
      printf "%s\n%s\n\n" 'cpu=armv7' \
                          'smp=on' \
                          >> "$ubootenv"
      ;;
  esac

  printf "%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n" '# Serial' \
                                                'baudrate=115200' \
                                                'sttyconsole=ttyAMA0' \
                                                'ttyconsole=tty1' \
                                                '# Allowed high address' \
                                                'fdt_high=0xffffffffffffffff' \
                                                'initrd_high=0xffffffffffffffff' \
                                                '# Placement in memory' \
                                                >> "$ubootenv"

  case "$distro" in
    "alpine")
      printf "%s\n%s\n%s\n%s\n\n" 'fit_addr_r=0x05200000' \
                                  'fdt_addr_r=0x01000000' \
                                  'kernel_addr_r=0x02000000' \
                                  'ramdisk_addr_r=0x03400000' \
                                  >> "$ubootenv"
      ;;
  esac

  printf "%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n" '# load/boot commands' \
                                            'load_fit=fatload mmc 0:1 ${fit_addr_r} image.fit' \
                                            'boot_fit=bootm ${fit_addr_r}' \
                                            '# auto-boot command' \
                                            'bootcmd=run mmcboot' \
                                            'mmcboot=run load_fit; run set_bootargs_tty set_common_args; run boot_fit' \
                                            '# boot arguments' \
                                            >> "$ubootenv"

  case "$distro" in
    "alpine")
      printf "%s\n%s\n" 'set_bootargs_tty=setenv bootargs console=${ttyconsole} console=${sttyconsole},${baudrate}' \
                        'set_common_args=setenv bootargs ${bootargs} smsc95xx.macaddr=${ethaddr} '\''dma.dmachans=0x7f35 8250.nr_uarts=1 rootwait bcm2708_fb.fbwidth=1920 bcm2708_fb.fbheight=1080 vc_mem.mem_base=0x3ec00000 vc_mem.mem_size=0x40000000 slub_debug=P slab_nomerge quiet init_on_alloc=1'\' \
                        >> "$ubootenv"
      ;;
  esac
  printf "%s\n" ""
)

# u-boot `make` function
uboot_make() (
  ARCH=arm CROSS_COMPILE=$target- make -C "$ubootbdir" -j$(($(nproc) + 2)) "${@}" >/dev/null 2>&1
)

uboot_build_stage1() (
  # preparations made before stage 1 build
  printf "%s\n" "Performing 1st stage u-boot build.."

  [ -s "$ubootbdir/.config" ] && uboot_make distclean

  cp "$ubootdefconfig" "$ubootbdir/.config"

  # apply patches (if necessary)
  ( sed -n 41p "$ubootbdir/arch/arm/dts/bcm2837.dtsi" | grep "enable-method = \"brcm,bcm2836-smp\"; // for ARM 32-bit" ) >/dev/null 2>&1 && \
      [ "$cpuarch" = "aarch64" ] && \
      patch_uboot

  # check for fit dir
  [ -d "$fitdir" ] || mkdir "$fitdir"

  # copy os files to fit dir
  cp "$kernel" "$dtb" "$fitdir"

  # include ramdisk (if necessary)
  [ -n "$ramdisk" ] && cp "$ramdisk" "$fitdir"

  # generate uboot environment file
  generate_ubootenv

  # include env file in config
  sed -i "/^CONFIG_USE_DEFAULT_ENV_FILE=y$/aCONFIG_DEFAULT_ENV_FILE=\"$ubootenv\"" "$ubootbdir/.config"

  # check if dependencies are installed
  for pkg in build-essential flex bison libssl-dev device-tree-compiler bc ; do
    dpkg -s $pkg >/dev/null 2>&1 || (
      printf "%s" "Installing required package: "$pkg".."
      sudo apt-get install --assume-yes $pkg >/dev/null 2>&1
      printf "%s\n" ""
    )
  done

  printf "%s" "Compiling.. "

  uboot_make && printf "%s\n" ""
)

# more variables
ubootbin="$ubootbdir/u-boot.bin"
fitits="$fitdir/u-boot-rpi3-fit.its"
fitimg="$fitdir/image.fit"
ubootcdtb="$fitdir/$(echo $(basename $ubootdtb) | sed 's/.dtb$/-pubkey.dtb/')"
: ${mkimg:="$ubootbdir/tools/mkimage"}


# generate fit its-file
generate_fitits() (
  printf "%s" "Generating u-boot image tree source file.. "

  printf "%s\n\n%s\n\t%s\n\t%s\n\t%s\n\t\t%s\n\t\t\t%s\n\t\t\t%s\n\t\t\t%s\n" '/dts-v1/;' \
                                                                              '/ {' \
                                                                              "description = \"U-Boot FIT Image (RPI-$cpuarch)\";" \
                                                                              '#address-cells = <2>;' \
                                                                              'images {' \
                                                                              'kernel-1 {' \
                                                                              'description = "Kernel";' \
                                                                              "data = /incbin/(\"$(basename $kernel)\");" \
                                                                              'type = "kernel";' \
                                                                              > "$fitits"
  case "$cpuarch" in
    "aarch64")
      printf "\t\t\t%s\n" 'arch = "arm64";' \
                          >> "$fitits"
      ;;
    "arm")
      printf "\t\t\t%s\n" 'arch = "arm";' \
                          >> "$fitits"
      ;;
  esac

  printf "\t\t\t%s\n\t\t\t%s\n" 'os = "linux";' \
                                'compression = "none";' \
                                >> "$fitits"

  case "$distro" in
    "alpine")
      printf "\t\t\t%s\n\t\t\t%s\n" 'load = <0x02000000>;' \
                                    'entry = <0x02000000>;' \
                                    >> "$fitits"
      ;;
  esac

  printf "\t\t\t%s\n\t\t\t\t%s\n\t\t\t%s\n\t\t%s\n\t\t%s\n\t\t\t%s\n\t\t\t%s\n\t\t\t%s\n\t\t\t%s" 'hash-1 {' \
                                                                                                  'algo = "sha512";' \
                                                                                                  '};' \
                                                                                                  '};' \
                                                                                                  'fdt-1 {' \
                                                                                                  'description = "Device-Tree-Blob (DTB)";' \
                                                                                                  "data = /incbin/(\"$(basename $dtb)\");" \
                                                                                                  'type = "flat_dt";' \
                                                                                                  >> "$fitits"
  case "$cpuarch" in
    "aarch64")
      printf "%s\n" 'arch = "arm64";' \
                    >> "$fitits"
      ;;
    "arm")
      printf "%s\n" 'arch = "arm";' \
                    >> "$fitits"
      ;;
  esac

  printf "\t\t\t%s\n" 'compression = "none";' \
                      >> "$fitits"
  case "$distro" in
    "alpine")
      printf "\t\t\t%s\n\t\t\t%s\n" 'load = <0x01000000>;' \
                                    'entry = <0x01000000>;' \
                                    >> "$fitits"
      ;;
  esac

  printf "\t\t\t%s\n\t\t\t\t%s\n\t\t\t%s\n\t\t%s\n" 'hash-1 {' \
                                                    'algo = "sha512";' \
                                                    '};' \
                                                    '};' \
                                                    >> "$fitits"

  [ -n "$ramdisk" ] && (
    printf "\t\t%s\n\t\t\t%s\n\t\t\t%s\n\t\t\t%s\n" 'ramdisk-1 {' \
                                                    'description = "Ramdisk (Initramfs)";' \
                                                    "data = /incbin/(\"$(basename $ramdisk)\");" \
                                                    'type = "ramdisk";' \
                                                    >> "$fitits"

    case "$cpuarch" in
      "aarch64")
        printf "\t\t\t%s\n" 'arch = "arm64";' \
                            >> "$fitits"
        ;;
      "arm")
        printf "\t\t\t%s\n" 'arch = "arm";' \
                            >> "$fitits"
        ;;
    esac

    printf "\t\t\t%s\n\t\t\t%s\n" 'os = "linux";' \
                                  'compression = "none";' \
                                  >> "$fitits"

    case "$distro" in
      "alpine")
        printf "\t\t\t%s\n\t\t\t%s\n" 'load = <0x03400000>;' \
                                      'entry = <0x03400000>;' \
                                      >> "$fitits"
        ;;
    esac

    printf "\t\t\t%s\n\t\t\t\t%s\n\t\t\t%s\n\t\t%s\n\t%s\n" 'hash-1 {' \
                                                            'algo = "sha512";' \
                                                            '};' \
                                                            '};' \
                                                            '};' \
                                                            >> "$fitits"
    )

  printf "\t%s\n\t\t%s\n\t\t%s\n\t\t\t%s\n\t\t\t%s\n\t\t\t%s\n" 'configurations {' \
                                                                'default = "config-1";' \
                                                                'config-1 {' \
                                                                'description = "FIT-configuration";' \
                                                                'kernel = "kernel-1";' \
                                                                'fdt = "fdt-1";' \
                                                                >> "$fitits"

  [ -n "$ramdisk" ] && (
    printf "\t\t\t%s\n" 'ramdisk = "ramdisk-1";' \
                        >> "$fitits"
  )

  printf "\t\t\t%s\n\t\t\t\t%s\n\t\t\t\t%s\n" 'signature-1 {' \
                                              'algo = "sha512,rsa2048";' \
                                              'key-name-hint = "sign";' \
                                              >> "$fitits"

  [ -n "$ramdisk" ] && (
    printf "\t\t\t\t%s\n" 'sign-images = "kernel", "fdt", "ramdisk";' \
                          >> "$fitits"
  ) || (
    printf "\t\t\t\t%s\n" 'sign-images = "kernel", "fdt";' \
                          >> "$fitits"
  )
 
  printf "\t\t\t%s\n\t\t%s\n\t%s\n%s\n" '};' \
                                        '};' \
                                        '};' \
                                        '};' \
                                        >> "$fitits"

  printf "%s\n" ""
)

uboot_build_stage2() (
  # preparations before second stage build
  printf "%s\n" "Performing 2nd stage u-boot build.."

  cp "$ubootdtb" "$ubootcdtb"

  # generate fit signing keys
  [ -d "$fitdir/keys" ] || mkdir "$fitdir/keys"
  printf "%s" "Generating FIT Signing Keys.. "
  openssl genrsa -F4 -out "$fitdir/keys/sign.key" >/dev/null 2>&1
  openssl req -batch -new -x509 -key "$fitdir/keys/sign.key" -out "$fitdir/keys/sign.crt" >/dev/null 2>&1
  printf "%s\n" ""

  # generate fit its file
  generate_fitits


  # create the fit image, and sign it with newly-generated keys
  ${mkimg} \
    -f "$fitits" \
    -K "$ubootcdtb" \
    -k "$fitdir/keys" \
    -r "$fitimg" \
    >/dev/null 2>&1

  # clean, then re-build u-boot
  # (to include control dtb for verifying fit signature)
  printf "%s" "Cleaning u-boot build directory.. "
  uboot_make clean
  printf "%s\n" ""
  printf "%s" "Recompiling.. "
  uboot_make EXT_DTB="$ubootcdtb"
  printf "%s\n" ""
)

build_uboot() ( uboot_build_stage1 && uboot_build_stage2 )
