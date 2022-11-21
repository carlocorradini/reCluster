<!-- markdownlint-disable MD033 -->

# [Alpine Linux](https://www.alpinelinux.org) distribution

## :hammer_and_wrench: Build ISO image(s)

1. Build

   ```sh
   ./build.sh
   ```

   - Arguments

     > **Note**: Type `--help` for more information

     > **Note**: [commons arguments](../../../scripts/README.md#commons-arguments) available

     | **Name** | **Description**            | **Default** | **Values** |
     | -------- | -------------------------- | ----------- | ---------- |
     | `--help` | Show help message and exit |

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

1. Patch `setup-disk`

   > **Note**: Find `setup-disk` location with `command -v setup-disk`

   - `select_firmware_pkgs` function

     ```diff
       # detect which firmware packages to install, if any
       select_firmware_pkgs() {
         local firmware_pkgs="$( (cd "$ROOT"/sys/module/ && echo *) \
           | xargs modinfo -F firmware 2> /dev/null \
           | awk -F/ '{print $1 == $0 ? "linux-firmware-other" : "linux-firmware-"$1}' \
           | sort -u)"
     -   echo ${firmware_pkgs:-linux-firmware-none}
     +   # filter out non-existing packages like linux-firmware-b43
     +   # https://gitlab.alpinelinux.org/alpine/alpine-conf/-/issues/10530
     +   apk search --quiet --exact ${firmware_pkgs:-linux-firmware-none}
       }
     ```

   - `setup_partitions` function

     ```diff
       # setup partitions on given disk dev in $1.
       # usage: setup_partitions <diskdev> size1,type1 [size2,type2 ...]
       setup_partitions() {
         local diskdev="$1" start=1M line=
         shift
         supported_part_label "$DISKLABEL" || return 1

         # initialize MBR for syslinux only
         if [ "$BOOTLOADER" = "syslinux" ] && [ -f "$MBR" ]; then
           cat "$MBR" > $diskdev
         fi

     +   # create clean disk label
     +   echo "label: $DISKLABEL" | sfdisk --quiet $diskdev

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
     -   ) | sfdisk --quiet --label $DISKLABEL $diskdev || return 1
     +   ) | sfdisk --quiet --wipe-partitions always --label $DISKLABEL $diskdev || return 1

         # create device nodes if not exist
         $MOCK mdev -s
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
