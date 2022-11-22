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
