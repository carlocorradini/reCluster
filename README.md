# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)
[![codeql](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml)
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

reCluster is an architecture for a data center that actively reduces its impact and minimizes its resource utilization.

## Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## :file_folder: Directories

> **Note**: Refer to the `README.md` of each directory for more information

| **Name**                | **Description**                                                   |
| ----------------------- | ----------------------------------------------------------------- |
| [`.github`](./.github/) | [GitHub](https://github.com) configuration                        |
| [`.husky`](./.husky/)   | [husky](https://typicode.github.io/husky) configuration           |
| [`.vscode`](./.vscode/) | [Visual Studio Code](https://code.visualstudio.com) configuration |
| [`linux`](./.linux/)    | `Linux`-related resources                                         |
| [`scripts`](./scripts/) | `Shell` scripts                                                   |
| [`server`](./server/)   | `reCluster` server                                                |

## Development

> **Warning**: All components must have their timezone set to `Etc/UTC`

### Requirements

| **Name**  | **Homepage**                |
| --------- | --------------------------- |
| `Docker`  | <https://www.docker.com>    |
| `K3d`     | <https://k3d.io>            |
| `Node.js` | <https://nodejs.org>        |
| `npm`     | <https://www.npmjs.com>     |
| `Vagrant` | <https://www.vagrantup.com> |

### Preparation

1. Clone

   ```sh
   git clone https://github.com/carlocorradini/reCluster.git
   cd reCluster
   ```

1. Scripts permissions

   ```sh
   chmod -R u+x scripts/*.sh linux/*sh server/scripts/*.sh
   ```

1. Install dependencies

   ```sh
   npm ci && npm --prefix server install
   ```

## Simulate Cluster

> **Note**: Destroy machines with `vagrant destroy --graceful --force`

1. Install `vagrant-hosts` plugin:

   ```sh
   vagrant plugin install vagrant-hosts
   ```

1. Creates and configures machines

   ```sh
   vagrant up
   ```

### Controller

1. SSH

   ```sh
   vagrant ssh controller
   ```

1. Install

   ```sh
   ./linux/install.sh --config ./linux/configs/controller.config.yml --pc-device-api "http://192.168.0.61/cm?cmnd=status%2010" --init-cluster
   ```

### Worker

1. SSH

   ```sh
   vagrant ssh worker
   ```

1. Install

   ```sh
   ./linux/install.sh --config ./linux/configs/worker.config.yml --pc-device-api "http://192.168.0.61/cm?cmnd=status%2010"
   ```

### Scripts

> **Note**: Execute with `npm run <NAME>`

| **Name** | **Description**   |
| -------- | ----------------- |
| `check`  | Check for errors. |
| `fix`    | Fix errors.       |

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](./LICENSE) file for details.
