+++
author = "ziprandom"
tags = ["debian", "security", "arm"]
title = "Single Board Computers As Fully Encrypted Homeservers"
date = "2019-01-05T11:00:00-03:00"
draft = false
+++

Set up arm boards supported by armbian / raspbian with fully encrypted root / home partition and all unencrypted data (kernel+initramfs+passwordless_keys) on an external (micro)sd card that can be removed after boot.

<!--more-->


**tl;dr** *using debian based prebuild os images as a basis to setup single board computers with full disk encryption. luks encrypted root resides on a usb drive while unencrypted  partes (initramfs, kernel and encryption key) are stored on an sd card that functions like a physical key to unlock the disk on startup and get removed for secure storage afterwards.*

Motivation
==========

Many tutorials on linux (full) disk encryption assume an unencrypted boot partition on the same drive as the encrypted root. In the home server scenario this cannot be considered secure as an intruder can freely temper with the crucial initramfs and kernel to make them steal the key material (possibly a keyfile and/or password) on the next reboot. To adequately protect data on a raspberry (or other board) based system that cannot be as physically secured as a server in a server room we need to make sure to leave nothing behind than encrypted partition. This can be achieved by separating the `/boot` partition from the encryptied `/root` partition and removing the device that holds the `/boot` partition after the system has booted.

The device (micro-sd card) that holds the unencrypted `/boot` partition and unencrypted keyfile (for passwordless --> monitor + keyboardless boot) can then be considered the key to the system and stored away in a secure location until the next (re)boot becomes necessary.

In this article I will give a general description of the steps necessary for setting up such a system based on prebuild [armbian](https://www.armbian.com/download/) / [raspbian](https://www.raspbian.org) images.

Requirements
============

- a supported board
- the corresponding os image _see [armbian](https://www.armbian.com/download/) or [raspbian for raspberry pis](https://www.raspbian.org/RaspbianImages)_
- a sd or microsd card with at least 2GB of storage
- a usb usb drive (stick, hdd or ssd) with at least 5GB _to use as the encrypted disk_
- a usb -> micro usb cable to connect the board to electricity
- an ethernet cable to connect the board to you computer or a router in your network
- on your computer you will need
  - an sd slot _compatible to the sd card you intend to use_
  - a disk flashing software. _this comes preinstalled on Linux/OSX on windows refer to [this](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md) page for image flashing_
  - an ssh client _also preinstalled on Linux/OSX for windows see [here](https://www.putty.org/)_


Big Picture
===========

The process works as follows:

1. download the os image for our board, unpack it and flash it to the sd card
2. boot the board with from the sd card and connect to the system via ssh
3. attach the usb drive to the board, format it as a luks encrypted storage with a keyfile and prepare a lvm2 volume-group and volumes.
4. configure system to boot from the encrypted drive and rebuild initramfs and the bootloader on the sd card
5. finally copy the contents of the root partition over to the encrpyted root volume


Example Raspberry Pi I B
========================

In this walkthrough we will assume a fairly old RasperryPi I B board. As Armbian is not available for this board we will use raspian instead.

I assume you are working from a linux system. If you happen to be on windows you will need to figure out how to flash the image to the sd card and connect to the ssh server on the board yourself using the links given above.

1\. Download image and flash to sd card
---------------------------------------

the raspberry images can be retrieved directly from the raspberry website: https://www.raspberrypi.org/downloads/raspbian

```sh
# insert the sdcard into your computer
# and use a tool like dmesg to figure
# out its name in the device file system
# in my case it's /dev/mmcblk0

wget -O raspbian_lite_latest.zip https://downloads.raspberrypi.org/raspbian_lite_latest
unzip -p raspbian_lite_latest.zip | sudo dd of=/dev/mmcblk0 bs=4MB
```


Unfortunately the raspbian system will not start an ssh server automatically. to make it do, we have to place a file called `ssh` on the boot partition. to do so we mount the ssd cards boot partition.

```sh
mount /dev/mmcblk0p1 /mnt
touch /mnt/ssh
umount /dev/mmcbl0p1
```

you can also do this with the normal file manager and any editor on Linux/OSX and Windows as the `/boot` partition is a fat32 system that gets recognized automatically by all oses.

2\. Boot the board and ssh into the system
-------------------------------------------

A nice way to connect the board to your computer is by directly connecting the devices via an ethernet cable. therefore your network card needs to be configured to [share it's connection](https://help.ubuntu.com/community/Internet/ConnectionSharing#GUI_Method_via_Network_Manager_.28Ubuntu_14.04.2C_16.04.29).

Now put the sd card into your board, attach the ethernetcable to your computer and the board and finally connect the microusb power supply.

After a few seconds you should be able to discover the plugs IP address via your attached network cable:

```sh
<linux $> arp -na-i eth0
? (192.168.137.68) auf b8:27:eb:xx:xx:xx [ether] auf eth0
< win  $> arp -a
```

now it's time to log into the system via ssh:

```sh
# raspbian uses user 'pi' password 'raspberry'
ssh pi@192.168.137.68

# armbian uses user 'root' password '1234'
ssh root@192.168.137.68
```


3\. Prepare encrypted lvm on usb drive
--------------------------------------

In order to prepare the encrypted storage we need to install some tools on the system:

```sh
sudo aptitude update
sudo aptitude safe-upgrade
sudo aptitude install busybox cryptsetup lvm2
```


Now attach the usb storage that you want to use as the encrypted root to the board. use dmesg to figure out it's device name and initialze the encrypted storage and the lvm volume group.

```sh
# create a keyfile
sudo dd if=/dev/urandom of=/boot/keyfile bs=1024 count=4
# create encrypted device
sudo cryptsetup -c aes-xts-plain -s 512 --key-file /boot/keyfile -y luksFormat /dev/sda
# open encrypted device
sudo cryptsetup luksOpen --key-file /boot/keyfile /dev/sda cryptroot
```

now proceed to create the lvm volume group and the volumes. for the swap partition allocate as much memory as you have ram on your board

```sh
sudo pvcreate /dev/mapper/cryptroot
sudo vgcreate cryptrootvg /dev/mapper/cryptroot
sudo lvcreate -L 5G -n root_lv cryptrootvg
sudo lvcreate -L 512MB -n swap_lv cryptrootvg
sudo lvcreate -l 100%FREE -n home_lv cryptrootvg
sudo mkfs.ext4 /dev/mapper/cryptrootvg-root_lv
sudo mkfs.ext4 /dev/mapper/cryptrootvg-home_lv
sudo mkswap -f /dev/mapper/cryptrootvg-swap_lv
```

before we copy the contents of our root partition to the encrypted root we setup the system to use the encrypted drive on the next boot. this way we make sure the changed configuration files will be present on the encrypted root partition as well.

4\. Configure System to boot from Cryptroot, rebuild initramfs and u-bootloader
-------------------------------------------------------------------------------

**/etc/fstab**

edit the `/etc/fstab` file on the board. comment out the line for the root partition and add the new entries for the encrypted partitions using an editor like `sudo vi /etc/fstab` or `sudo nano /etc/fstab`

find the line for the `/` mount point
```sh
PARTUUID=5424bc2d-02  /               ext4    defaults,noatime  0       1
```

and comment it out:

```sh
# PARTUUID=5424bc2d-02  /               ext4    defaults,noatime  0       1
```

leave the other lines untouched.

now add the new lines for the encrypted partitions:

```sh
/dev/mapper/cryptrootvg-root_lv / ext4 defaults,errors=remount-ro 0 1
/dev/mapper/cryptrootvg-home_lv /home ext4 defaults,errors=remount-ro 0 1
/dev/mapper/cryptrootvg-swap_lv none swap sw 0 0
```

**/etc/crypttab**

now find the uuid that corresponds to your usb drive. if your usb device was named `sda` run:

```sh
ls -la /dev/disk/by-uuid/ | sda
lrwxrwxrwx 1 root root   9 Jan  5 23:20 cc0d9912-ec41-427b-89f7-7e7032ce1e79 -> ../../sda
```

and add or edit the file named `/etc/crypttab` and add your cryptdevice with the uuid:
```sh
cryptroot	UUID=cc0d9912-ec41-427b-89f7-7e7032ce1e79	/boot/keyfile	luks
```

**/etc/cryptsetup-initramfs/conf-hook**

edit `/etc/cryptsetup-initramfs/conf-hook` to make sure it includes the following lines:

```sh
CRYPTSETUP=y
KEYFILE_PATTERN="/boot/keyfile"
```

**(re)build initramfs**

now that the necessary configurations have been set up it's time to rebuild the initramfs on the `/boot` partition:

if you used the raspbian image for raspberry pi then your system is configured to not build and use an initramfs. in this case make sure the file `/etc/default/raspberrypi-kernel` includes the following line:

```sh
INITRD=Yes
```


and run:

```sh
sudo update-initramfs -c -k `uname -r`
```

to create your initramfs. now we need to tell the bootloader to use that image by adding a line to `/boot/config.txt`:

```sh
echo "initramfs $(cd /boot; find init* | tail -n1 )" | sudo tee -a /boot/config.txt
```

there is a comment on how to automate this to run everytime the initramfs gets updated [here](https://raspberrypi.stackexchange.com/questions/92557/how-can-i-use-an-init-ramdisk-initramfs-on-boot-up-raspberry-pi)


if your using armbian then simply run:

```sh
sudo update-initramfs -k all -u
```

**Raspbian: adjust `/boot/cmdline.txt`**

after we change `root=` to our new encrypted root partition the boot loader is setup:

```sh
root=/dev/mapper/
```

**Armbian: adjust `/boot/boot.cmd` and rebuild uboat:**

```sh
replace:

setenv rootdev "/dev/mmcblk0p1"

with:

setenv rootdev "/dev/mapper/cryptrootvg-root_lv"
```

and recompile with:

```
mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/bootspbian extra: enable sshd**
```

**Raspbian: start ssh server on boot**

```sh
sudo systemctl enable ssh.socket
```

5\. populate the encrypted partitions and reboot
------------------------------------------------

now that we set up the system to use the encrypted partitions we need to copy the unencrypted root partition over. first we mount `/dev/mapper/cryptrootvg-rootlv` and `/dev/mapper/cryptrootvg-homelv` under `/mnt`

```sh
sudo mount /dev/mapper/cryptrootvg-root_lv /mnt
sudo mkdir /mnt/home
sudo mount /dev/mapper/cryptrootvg-home_lv /mnt/home
```

now we sync the files using rsync:

```sh
sudo rsync -avrltD --delete --exclude boot/* --exclude dev/* --exclude proc/* --exclude sys/* --exclude media/* --exclude mnt/* --exclude run/* --exclude tmp/* / /mnt
```

finally we unmount the encrypted partitions:

```sh
sudo umount /mnt/home
sudo umount /mnt
```

and reboot:

```sh
sudo reboot
```

If all went well the board reboots and we can log in via ssh again. we can check that the encrypted partitions are used with:

```sh
mount
```

now we can remove the sd card and hide it somewhere safe. the data on the plug is now a lot safer.