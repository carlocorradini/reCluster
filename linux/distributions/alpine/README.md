<!-- markdownlint-disable MD033 -->

# Alpine Linux distribution

## :hammer: Build ISO image(s)

1. Build

   ```sh
   ./build.sh
   ```

2. ISO image(s) \
   Generated ISO image(s) available under [`iso`](./iso/) directory

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

---

<p align="center">
  <img src="./logo.png" alt="Alpine Linux logo" width="50%" />
</p>
