# :penguin: Linux

Linux.

## :warning: Requirements

### :hourglass: Timezone

Timezone must be set to `Etc/UTC`.

```sh
cp /usr/share/zoneinfo/Etc/UTC /etc/localtime
echo "Etc/UTC" > /etc/timezone
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

     > **Warning**: *Wake-on-Lan* must be enabled also in the _BIOS_

     > **Note**: Example device `eth0`

     Edit `/etc/network/interfaces`.

     ```diff
       auto eth0
       iface eth0 inet dhcp
     +   pre-up /usr/sbin/ethtool -s eth0 wol g
     ```

  2. Reboot

     ```sh
     sudo reboot
     ```

## :file_folder: Directories

> **Note**: Refer to the `README.md` of each directory for more information

| **Name**                            | **Description** |
| ----------------------------------- | --------------- |
| [`configs`](./configs/)             | Configurations  |
| [`dependencies`](./dependencies/)   | Dependencies    |
| [`distributions`](./distributions/) | Distributions   |

## :bookmark_tabs: [`install.sh`](./install.sh)

reCluster installation script.

```sh
./install.sh
```

### Arguments

> **Note**: Type `--help` for more information

| **Name**                            | **Description**                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------------ |
| `--airgap`                          | Perform installation in Air-Gap environment                                                |
| `--bench-time <TIME>`               | Benchmark execution time in seconds                                                        |
| `--config <PATH>`                   | Configuration file                                                                         |
| `--disable-color`                   | Disable color                                                                              |
| `--disable-spinner`                 | Disable spinner                                                                            |
| `--help`                            | Show help message and exit                                                                 |
| `--init-cluster`                    | Initialize cluster components and logic. Enable only when bootstrapping for the first time |
| `--k3s-version <VERSION>`           | K3s version                                                                                |
| `--log-level <LEVEL>`               | Logger level                                                                               |
| `--node-exporter-version <VERSION>` | Node exporter version                                                                      |
| `--pc-device-api <URL>`             | Power consumption device api url                                                           |
| `--pc-interval <TIME>`              | Power consumption read interval time in seconds                                            |
| `--pc-time <TIME>`                  | Power consumption execution time in seconds                                                |
| `--pc-warmup <TIME>`                | Power consumption warmup time in seconds                                                   |
| `--spinner <SPINNER>`               | Spinner symbols                                                                            |
