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

     > **Warning**: _Wake-on-Lan_ must be enabled also in the _BIOS_

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

> **Note**: [commons arguments](../scripts/README.md#commons-arguments) available

| **Name**                            | **Description**                                                                            | **Default**                                     | **Values**                |
| ----------------------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------- | ------------------------- |
| `--airgap`                          | Perform installation in Air-Gap environment                                                | `false`                                         |
| `--bench-time <TIME>`               | Benchmark execution time in seconds                                                        | `30`                                            | Any positive number       |
| `--config-file <FILE>`              | Configuration file                                                                         | `configs/recluster.yml`                         | Any valid file            |
| `--help`                            | Show help message and exit                                                                 |
| `--init-cluster`                    | Initialize cluster components and logic. Enable only when bootstrapping for the first time | `false`                                         |
| `--k3s-version <VERSION>`           | K3s version                                                                                | `latest`                                        | Any K3s version           |
| `--node-exporter-version <VERSION>` | Node exporter version                                                                      | `latest`                                        | Any Node exporter version |
| `--pc-device-api <URL>`             | Power consumption device api url                                                           | `http://pc.recluster.local/cm?cmnd=status%2010` | Any valid URL             |
| `--pc-interval <TIME>`              | Power consumption read interval time in seconds                                            | `1`                                             | Any positive number       |
| `--pc-time <TIME>`                  | Power consumption execution time in seconds                                                | `30`                                            | Any positive number       |
| `--pc-warmup <TIME>`                | Power consumption warmup time in seconds                                                   | `10`                                            | Any positive number       |
| `--ssh-authorized-keys-file <FILE>` | SSH authorized keys file                                                                   | `/root/.ssh/authorized_keys`                    | Any valid file            |
| `--ssh-config-file <FILE>`          | SSH configuration file                                                                     | `configs/ssh_config`                            | Any valid file            |
| `--sshd-config-file <FILE>`         | SSH server configuration file                                                              | `configs/sshd_config`                           | Any valid file            |
