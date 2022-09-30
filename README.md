# alpine-rpi3-verified-boot
**EXPERIMENTAL**<br>Shell scripts to automate the process of implementing verified-boot on the Raspberry Pi 3 (Model B+), for Alpine Linux


## Requirements
<i><b>Script MUST be run on an x86_64-based machine</b></i>

1) Create a FAT16 boot partition w/ 256M available
```shell
# assume device is 'sda'

# here, we create a bootable FAT16 partition on disk
fdisk /dev/sda1 <<EOF
o
n
p
1
2048
+256M
t
1
e
w
EOF
```

2) Format the boot partition as FAT16
```shell
# format the partition
mkfs.vfat -F16 -n "BOOT" /dev/sda1
```


## Usage
```shell
./sign_boot.sh
```


<b>Afterwards, COPY files from work/out/boot/* to BOOT storage device (i.e sda1 | mmcblk0p1 | etc...)</b>

## Important
<b>NOTE THAT:</b><br>This kind of verified-boot on the Raspberry Pi is not technically "secure", as there is no implementation of hardware-backed key attestation, or SRAM<br><b><i><br>For more info, see:</i></b><br><br>1) https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/plat/rpi3.rst<br>2) https://blog.crysys.hu/2018/06/verified-boot-on-the-raspberry-pi/
