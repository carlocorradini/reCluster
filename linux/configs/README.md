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

> **Note**: [commons arguments](../../scripts/README.md#arguments-2) available

| **Name**          | **Description**             | **Default**         | **Values**     |
| ----------------- | --------------------------- | ------------------- | -------------- |
| `--common <FILE>` | Common configuration file   | `common.config.yml` | Any valid file |
| `--help`          | Show help message and exit  |
| `--merge <FILE>`  | Configuration file to merge | `config.yml`        | Any valid file |
| `--output <FILE>` | Output configuration file   | `output.yml`        | Any valid file |
