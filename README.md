# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)
[![codeql](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml)

The reCluster is an architecture for a data center that actively reduces its impact and minimizes its resource utilization.

## Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)

## Getting Started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes.

1. Clone

   ```console
   git clone https://github.com/carlocorradini/reCluster.git
   cd reCluster
   ```

1. Scripts Permissions

   ```console
   chmod -R +x scripts/*.sh linux/*sh server/scripts/*.sh
   ```

1. Install Dependencies

   ```console
   npm ci
   ```

## Development

1. Vagrant

   ```console
   vagrant up controller
   ```

1. reCluster Controller node

    ```console
    vagrant ssh controller 
    /vagrant/server/scripts/database.sh &
    npm --prefix /vagrant/server run db:migrate
    /vagrant/linux/install.sh --bench-time 1 --log-level debug --config /vagrant/linux/config.server.yaml --init-cluster
    ```

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](LICENSE) file for details.
