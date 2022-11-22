# reCluster configurations

reCluster configurations.

## :bookmark_tabs: [`common.config.yml`](./common.config.yml)

Common configuration.

## :bookmark_tabs: [`controller.config.yml`](./controller.config.yml)

Controller configuration.

## :bookmark_tabs: [`worker.config.yml`](./worker.config.yml)

Worker configuration.

## :bookmark_tabs: [`configs.sh`](./configs.sh)

reCluster configurations script.

```sh
_merge="./controller.config.yml"

./configs.sh \
  --merge "$_merge"
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](../../scripts/README.md#commons-arguments) available

| **Name**               | **Description**            | **Default**         | **Values**     |
| ---------------------- | -------------------------- | ------------------- | -------------- |
| `--common-file <FILE>` | Common file                | `common.config.yml` | Any valid file |
| `--help`               | Show help message and exit |
| `--merge-file <FILE>`  | Merge file                 | `config.yml`        | Any valid file |
| `--out-file <FILE>`    | Output file                | `output.yml`        | Any valid file |
| `--overwrite`          | Overwrite merge file       | `false`             |

## :bookmark_tabs: [`ssh_config`](./ssh_config)

Visit <https://www.ssh.com/academy/ssh/config> for more information.

## :bookmark_tabs: [`sshd_config`](./sshd_config)

Visit <https://www.ssh.com/academy/ssh/sshd_config> for more information.
