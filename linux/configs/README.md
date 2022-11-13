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

| **Name**          | **Description**             |
| ----------------- | --------------------------- |
| `--common <PATH>` | Common configuration file   |
| `--help`          | Show help message and exit  |
| `--merge <PATH>`  | Configuration file to merge |
| `--output <PATH>` | Output configuration file   |
