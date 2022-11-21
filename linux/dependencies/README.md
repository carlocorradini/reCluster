# reCluster dependencies

reCluster dependencies.

## :bookmark_tabs: [`dependencies.yml`](./dependencies.yml)

Dependencies file.

## :bookmark_tabs: [`dependencies.sh`](./dependencies.sh)

Dependencies script.

```sh
./dependencies.sh \
  --sync
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](../../scripts/README.md#commons-arguments) available

| **Name**               | **Description**                                                    | **Default**               | **Values**     |
| ---------------------- | ------------------------------------------------------------------ | ------------------------- | -------------- |
| `--config-file <FILE>` | Configuration file                                                 | `dependencies.config.yml` | Any valid file |
| `--help`               | Show help message and exit                                         |
| `--sync`               | Synchronize dependencies                                           | `false`                   |
| `--sync-force`         | Synchronize dependencies replacing assets that are already present | `false`                   |
