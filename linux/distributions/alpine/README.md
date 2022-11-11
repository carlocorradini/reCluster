<!-- markdownlint-disable MD033 -->

# [Alpine Linux](https://www.alpinelinux.org) distribution

## :hammer_and_wrench: Build ISO image(s)

1. Build

   ```sh
   ./build.sh
   ```

2. ISO image(s) \
   Generated ISO image(s) available under [`iso`](./iso/) directory.

## :floppy_disk: Burn ISO image

1. Find device name

   ```sh
   fdisk -l
   ```

2. Burn ISO image

   ```sh
   _iso="path/to/file.iso"
   _dev="/dev/sdX"
   
   dd if="$_iso" of="$_dev" status=progress oflag=sync
   ```

## :gear: Installation

> **Note**: More information available at <https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html>

1. Patch `setup_partitions() { ... }` function from `setup-disk`

   > **Note**: Find `setup-disk` location with `command -v setup-disk`

   ```sh
   setup_partitions() {
     local diskdev="$1" start=1M line=
     shift
     supported_part_label "$DISKLABEL" || return 1
   
     # create clean disklabel
     echo "label: $DISKLABEL" | sfdisk --quiet $diskdev
   
     # initialize MBR for syslinux only
     if [ "$BOOTLOADER" = "syslinux" ] && [ -f "$MBR" ]; then
       cat "$MBR" > $diskdev
     fi
   
     # create new partitions
     (
       for line in "$@"; do
         case "$line" in
           0M*) ;;
           *)
             echo "$start,$line"
             start=
             ;;
         esac
       done
     ) | sfdisk --quiet -W always --label $DISKLABEL $diskdev || return 1
   
     # create device nodes if not exist
     mdev -s
   }
   ```

2. Install

   ```sh
   setup-alpine
   ```

---

<p align="center">
  <img src="./logo.png" alt="Alpine Linux logo" width="50%" />
</p>
