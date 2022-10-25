# :penguin: Linux

## :file_folder: Directories

> **Note**: Refer to the `README.md` of each directory for more information

| **Name**                           | **Description** |
| ---------------------------------- | --------------- |
| [`configs`](./configs)             | Configurations  |
| [`dependencies`](./dependencies)   | Dependencies    |
| [`distributions`](./distributions) | Distributions   |

## `install.sh`

Recluster installation script.

### Flags

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
| `--node_exporter-version <VERSION>` | Node exporter version                                                                      |
| `--pc-device-api <URL>`             | Power consumption device api url                                                           |
| `--pc-interval <TIME>`              | Power consumption read interval time in seconds                                            |
| `--pc-time <TIME>`                  | Power consumption execution time in seconds                                                |
| `--pc-warmup <TIME>`                | Power consumption warmup time in seconds                                                   |
| `--spinner <SPINNER>`               | Spinner symbols                                                                            |
