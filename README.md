# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)
[![codeql](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml)
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

reCluster is an architecture for a data center that actively reduces its impact and minimizes its resource utilization

## Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## Development

1. Clone

   ```console
   git clone https://github.com/carlocorradini/reCluster.git
   cd reCluster
   ```

1. Scripts permissions

   ```console
   chmod -R u+x scripts/*.sh linux/*sh server/scripts/*.sh
   ```

1. Install dependencies

   ```console
   npm ci && npm --prefix server ci
   ```

## Simulate Cluster

1. Install `vagrant-hosts` plugin:

   ```console
   vagrant plugin install vagrant-hosts
   ```

1. Creates and configures guest machines

   ```console
   vagrant up
   ```

### Master

1. SSH

   ```console
   vagrant ssh master
   ```

1. Install

   ```console
   ./linux/install.sh --config ./linux/config.master.yml --pc-device-api "http://192.168.0.61/cm?cmnd=status%2010" --init-cluster
   ```

### Worker

1. SSH

   ```console
   vagrant ssh worker
   ```

1. Install

   ```console
   ./linux/install.sh --config ./linux/config.worker.yml --pc-device-api "http://192.168.0.61/cm?cmnd=status%2010"
   ```

### Scripts

> **Note**: Execute with `npm run <NAME>`

| **Name** | **Description** |
| -------- | --------------- |
| `check` | Check for errors. |
| `check:format` | Check for format errors. |
| `check:license` | Check for license errors. |
| `check:markdown` | Check for markdown errors. |
| `check:spell` | Check for spelling errors. |
| `fix` | Fix errors. |
| `fix:format` | Fix format errors. |
| `fix:license` | Fix license errors. |
| `fix:markdown` | Fix markdown errors. |

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](LICENSE) file for details.
