# Installation requirements

Installation requirements.

## Network

### :twisted_rightwards_arrows: Connectivity

All nodes must be within the same subnet.

Direct layer 2 connectivity between nodes.

## Node

### :hourglass: Timezone

Timezone must be set to `Etc/UTC`.

```sh
cp /usr/share/zoneinfo/Etc/UTC /etc/localtime
printf '%s\n' "Etc/UTC" > /etc/timezone
```

### :sleeping: Wake-on-Lan

_Wake-on-Lan_ must be enabled if it is supported.

- Check if supported

  > **Note**: If empty, _Wake-on-Lan_ is not supported

  ```sh
  _dev="eth0"
  
  sudo ethtool "$_dev" | grep 'Supports Wake-on'
  ```

- Check if enabled

  > **Note**: Value `d` indicates that it is disabled

  ```sh
  _dev="eth0"
  
  sudo ethtool "$_dev" | grep 'Wake-on' | grep --invert-match 'Supports Wake-on'
  ```

  1. Enable

     > **Warning**: _Wake-on-Lan_ must be enabled also in the _BIOS_

     > **Note**: Example device `eth0`

     Edit `/etc/network/interfaces`

     ```diff
       auto eth0
       iface eth0 inet dhcp
     +   pre-up /usr/sbin/ethtool -s eth0 wol g
     ```

  2. Reboot

     ```sh
     sudo reboot
     ```
