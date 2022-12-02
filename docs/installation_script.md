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
| `--airgap`                           | Perform installation in Air-Gap environment                                                | `false`                                         |
| `--bench-time <TIME>`                | Benchmark execution time in seconds                                                        | `30`                                            | Any positive number       |
| `--config-file <FILE>`               | Configuration file                                                                         | `configs/config.yaml`                           | Any valid file            |
| `--help`                             | Show help message and exit                                                                 |
| `--init-cluster`                     | Initialize cluster components and logic. Enable only when bootstrapping for the first time | `false`                                         |
| `--k3s-config-file <FILE>`           | K3s configuration file                                                                     | `configs/k3s.yaml`                              | Any valid file            |
| `--k3s-registry-config-file <FILE>`  | K3s registry configuration file                                                            | `configs/registries.yaml`                       | Any valid file            |
| `--k3s-version <VERSION>`            | K3s version                                                                                | `latest`                                        | Any K3s version           |
| `--node-exporter-config-file <FILE>` | Node exporter configuration file                                                           | `configs/node_exporter.yaml`                    | Any valid file            |
| `--node-exporter-version <VERSION>`  | Node exporter version                                                                      | `latest`                                        | Any Node exporter version |
| `--pc-device-api <URL>`              | Power consumption device api url                                                           | `http://pc.recluster.local/cm?cmnd=status%2010` | Any valid URL             |
| `--pc-interval <TIME>`               | Power consumption read interval time in seconds                                            | `1`                                             | Any positive number       |
| `--pc-time <TIME>`                   | Power consumption execution time in seconds                                                | `30`                                            | Any positive number       |
| `--pc-warmup <TIME>`                 | Power consumption warmup time in seconds                                                   | `10`                                            | Any positive number       |
| `--server-certs-dir <DIR>`           | Server certificates directory                                                              | `configs/certs`                                 | Any valid directory       |
| `--server-env-file <FILE>`           | Server environment file                                                                    | `configs/server.env`                            | Any valid file            |
| `--ssh-config-file <FILE>`           | SSH configuration file                                                                     | `configs/ssh_config`                            | Any valid file            |
| `--sshd-config-file <FILE>`          | SSH server configuration file                                                              | `configs/sshd_config`                           | Any valid file            |
| `--user <USER>`                      | User                                                                                       | `root`                                          | Any valid user            |
