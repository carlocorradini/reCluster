<!-- markdownlint-disable MD024 -->
<!-- markdownlint-disable MD033 -->

# reCluster scripts

reCluster scripts.

## :bookmark_tabs: [`bundle.sh`](./bundle.sh)

reCluster bundle script.

```sh
./bundle.sh
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](#commons-arguments) available

| **Name**               | **Description**            | **Default**          | **Values**     |
| ---------------------- | -------------------------- | -------------------- | -------------- |
| `--config-file <FILE>` | Configuration file         | `bundle.config.yaml` | Any valid file |
| `--help`               | Show help message and exit |
| `--out-file <FILE>`    | Output file                | `bundle.tar.gz`      | Any valid file |
| `--skip-run`           | Skip run                   | `false`              |

## :bookmark_tabs: [`certs.sh`](./certs.sh)

reCluster certificates script.

```sh
./certs.sh
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](#commons-arguments) available

| **Name**                          | **Description**            | **Default**       | **Values**                 |
| --------------------------------- | -------------------------- | ----------------- | -------------------------- |
| `--help`                          | Show help message and exit |
| `--out-dir <DIRECTORY>`           | Output directory           | `./`              | Any valid directory        |
| `--registry-bits <BITS>`          | Registry bits              | `4096`            | Any valid number of bits   |
| `--registry-domain <DOMAIN>`      | Registry domain            | `recluster.local` | Any valid domain           |
| `--registry-ip <IP>`              | Registry IP address        | `10.0.0.100`      | Any valid IP address       |
| `--registry-name <NAME>`          | Registry key name          | `registry`        | Any valid name             |
| `--ssh-comment <COMMENT>`         | SSH comment                |                   | Any valid comment          |
| `--ssh-name <NAME>`               | SSH key name               | `ssh`             | Any valid name             |
| `--ssh-passphrase <PASSPHRASE>`   | SSH passphrase             |                   | Any valid passphrase       |
| `--ssh-rounds <ROUNDS>`           | SSH rounds                 | `256`             | Any valid number of rounds |
| `--token-bits <BITS>`             | Token bits                 | `4096`            | Any valid number of bits   |
| `--token-name <NAME>`             | Token key name             | `token`           | Any valid name             |
| `--token-passphrase <PASSPHRASE>` | Token passphrase           |                   | Any valid passphrase       |

## :bookmark_tabs: [`configs.sh`](./configs.sh)

reCluster configurations script.

```sh
./configs.sh
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](#commons-arguments) available

| **Name**               | **Description**            | **Default**           | **Values**          |
| ---------------------- | -------------------------- | --------------------- | ------------------- |
| `--config-file <FILE>` | Configuration file         | `configs.config.yaml` | Configuration file  |
| `--help`               | Show help message and exit |
| `--in-dir <DIR>`       | Input directory            | `configs`             | Any valid directory |
| `--out-dir <DIR>`      | Output directory           | `./`                  | Any valid directory |
| `--overwrite`          | Overwrite input directory  | `false`               |

## :bookmark_tabs: [`init.sh`](./init.sh)

reCluster initialization script.

```sh
./init.sh
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](#commons-arguments) available

| **Name** | **Description**            | **Default** | **Values** |
| -------- | -------------------------- | ----------- | ---------- |
| `--help` | Show help message and exit |

## :bookmark_tabs: [`__commons.sh`](./__commons.sh)

> **Warning**: Included (`. path/to/__commons.sh`) by other scripts

Common functions and helpers.

<h3 id="commons-arguments">Arguments</h3>

| **Name**              | **Description** | **Default** | **Values**                                                                                                                          |
| --------------------- | --------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `--disable-color`     | Disable color   | `false`     |
| `--disable-spinner`   | Disable spinner | `false`     |
| `--log-level <LEVEL>` | Logger level    | `info`      | `fatal` Fatal level <br/> `error` Error level <br/> `warn` Warning level <br/> `info` Informational level <br/> `debug` Debug level |
| `--spinner <SPINNER>` | Spinner         | `propeller` | `dots` Dots spinner <br/> `grayscale` Grayscale spinner <br/> `propeller` Propeller spinner                                         |
