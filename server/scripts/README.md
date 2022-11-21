<!-- markdownlint-disable MD024 -->

# reCluster server scripts

reCluster server scripts.

## :bookmark_tabs: [`dev.sh`](./dev.sh)

reCluster dev script.

```sh
./dev.sh
```

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](../../scripts/README.md#commons-arguments) available

| **Name**                   | **Description**            | **Default**      | **Values**     |
| -------------------------- | -------------------------- | ---------------- | -------------- |
| `--help`                   | Show help message and exit |
| `--k3d-config-file <FILE>` | K3d configuration file     | `k3d.config.yml` | Any valid file |
| `--skip-certs`             | Skip certificates          | `false`          |
| `--skip-cluster`           | Skip cluster               | `false`          |
| `--skip-db`                | Skip database              | `false`          |
| `--skip-db-seed`           | Skip database seed         | `false`          |
| `--skip-server`            | Skip server                | `false`          |

## :bookmark_tabs: [`dockerize.sh`](./dockerize.sh)

reCluster Dockerize script.

### Arguments

> **Note**: Type `--help` for more information

> **Note**: [commons arguments](../../scripts/README.md#commons-arguments) available

| **Name** | **Description**            | **Default** | **Values** |
| -------- | -------------------------- | ----------- | ---------- |
| `--help` | Show help message and exit |
