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

| **Name**               | **Description**            | **Default**         | **Values**     |
| ---------------------- | -------------------------- | ------------------- | -------------- |
| `--config-file <FILE>` | Configuration file         | `bundle.config.yml` | Any valid file |
| `--help`               | Show help message and exit |
| `--out-file <FILE>`    | Output file                | `bundle.tar.gz`     | Any valid file |
| `--skip-run`           | Skip run                   | `false`             |

## :bookmark_tabs: [`certificates.sh`](./certificates.sh)

reCluster certificates script.

```sh
_ssh_passphrase="password"
_token_passphrase="password"

./certificates.sh \
  --ssh-passphrase "$_ssh_passphrase" \
  --token-passphrase "$_token_passphrase"
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](#commons-arguments) available

| **Name**                          | **Description**                 | **Default** | **Values**               |
| --------------------------------- | ------------------------------- | ----------- | ------------------------ |
| `--help`                          | Show help message and exit      |
| `--out-dir <DIRECTORY>`           | Output directory                | `./`        | Any valid directory      |
| `--ssh-bits <BITS>`               | Number of bits in the SSH key   | `2048`      | Any valid number of bits |
| `--ssh-name <NAME>`               | SSH key name                    | `ssh`       | Any valid name           |
| `--ssh-passphrase <PASSPHRASE>`   | SSH passphrase                  |             | Any valid passphrase     |
| `--token-bits <BITS>`             | Number of bits in the Token key | `4096`      | Any valid number of bits |
| `--token-name <NAME>`             | Token key name                  | `token`     | Any valid name           |
| `--token-passphrase <PASSPHRASE>` | Token passphrase                |             | Any valid passphrase     |

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
