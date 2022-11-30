<!-- markdownlint-disable MD033 -->

# [Arch Linux](https://archlinux.org) distribution

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

> **Note**: More information available at <https://wiki.archlinux.org/title/archinstall>

1. Uncomment all mirrors

   ```sh
   /usr/bin/sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
   ```

2. Install

   ```sh
   archinstall
   ```

---

<p align="center">
  <img src="./logo.png" alt="Arch Linux logo" width="50%" />
</p>
