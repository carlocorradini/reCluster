# Installation script

Installation script.

```sh
./install.sh
```

## Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](../scripts/README.md#commons-arguments) available

| **Name**                             | **Description**                                                                            | **Default**                                     | **Values**                |
| ------------------------------------ | ------------------------------------------------------------------------------------------ | ----------------------------------------------- | ------------------------- |
| `--admin-username <USERNAME>`        | Admin username                                                                             | `admin`                                         | Any valid username        |
| `--admin-password <PASSWORD>`        | Admin password                                                                             | `Password$0`                                    | Any valid password        |
| `--airgap`                           | Perform installation in Air-Gap environment                                                | `false`                                         |
| `--autoscaler-username <USERNAME>`   | Autoscaler username                                                                        | `autoscaler`                                    | Any valid username        |
| `--autoscaler-password <PASSWORD>`   | Autoscaler password                                                                        | `Password$0`                                    | Any valid password        |
| `--autoscaler-version <VERSION>`     | Autoscaler version                                                                         | `latest`                                        | Any Autoscaler version    |
| `--bench-time <TIME>`                | Benchmark execution time in seconds                                                        | `30`                                            | Any positive number       |
| `--certs-dir <DIR>`                  | Certificates directory                                                                     | `configs/certs`                                 | Any valid directory       |
| `--config-file <FILE>`               | Configuration file                                                                         | `configs/recluster/config.yaml`                 | Any valid file            |
| `--help`                             | Show help message and exit                                                                 |
| `--init-cluster`                     | Initialize cluster components and logic. Enable only when bootstrapping for the first time | `false`                                         |
| `--k3s-config-file <FILE>`           | K3s configuration file                                                                     | `configs/k3s/config.yaml`                       | Any valid file            |
| `--k3s-registry-config-file <FILE>`  | K3s registry configuration file                                                            | `configs/k3s/registries.yaml`                   | Any valid file            |
| `--k3s-version <VERSION>`            | K3s version                                                                                | `latest`                                        | Any K3s version           |
| `--node-exporter-config-file <FILE>` | Node exporter configuration file                                                           | `configs/node_exporter/config.yaml`             | Any valid file            |
| `--node-exporter-version <VERSION>`  | Node exporter version                                                                      | `latest`                                        | Any Node exporter version |
| `--pc-device-api <URL>`              | Power consumption device api url                                                           | `http://pc.recluster.local/cm?cmnd=status%2010` | Any valid URL             |
| `--pc-interval <TIME>`               | Power consumption read interval time in seconds                                            | `1`                                             | Any positive number       |
| `--pc-time <TIME>`                   | Power consumption execution time in seconds                                                | `30`                                            | Any positive number       |
| `--pc-warmup <TIME>`                 | Power consumption warmup time in seconds                                                   | `10`                                            | Any positive number       |
| `--server-env-file <FILE>`           | Server environment file                                                                    | `configs/recluster/server.env`                  | Any valid file            |
| `--ssh-authorized-keys-file <FILE>`  | SSH authorized keys file                                                                   | `configs/ssh/authorized_keys`                   | Any valid file            |
| `--ssh-config-file <FILE>`           | SSH configuration file                                                                     | `configs/ssh/ssh_config`                        | Any valid file            |
| `--sshd-config-file <FILE>`          | SSH server configuration file                                                              | `configs/ssh/sshd_config`                       | Any valid file            |
| `--user <USER>`                      | User                                                                                       | `root`                                          | Any valid user            |
