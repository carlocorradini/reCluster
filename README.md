# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)
[![codeql](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml)

reCluster is an architecture for a data center that actively reduces its impact and minimizes its resource utilization

## Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## Development

### Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)
- [Docker](https://www.docker.com)
- [Vagrant](https://www.vagrantup.com)

### Preparation

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
   npm ci
   ```

## Simulate Cluster

> Simulate cluster with Vagrant
>
> Same procedures as in a real cluster except for Vagrant commands

1. Start nodes

   ```console
   vagrant up
   ```

1. Controller node

   > 3 terminals are required

   ```console
   vagrant ssh controller
   ```

   1. PostgreSQL database

      1. Start

         > Terminal 1

         ```console
         /vagrant/server/scripts/database.sh
         ```

      1. Synchronize

         > Terminal 2

         ```console
         npm --prefix /vagrant/server run db:migrate
         ```

   1. Install script

      > Terminal 2
      >
      > Wait until it is asked to start reCluster server and go to the next step

      ```console
      /vagrant/linux/install.sh \
        --init-cluster \
        --config /vagrant/linux/config.controller.yaml
      ```

   1. reCluster server

      > Terminal 3

      1. Build

         ```console
         npm --prefix /vagrant/server run build
         ```

      1. Start

         ```console
         env \
           NODE_ENV=development \
           PORT=8080 \
           DATABASE_URL="postgresql://recluster:password@localhost:5432/recluster?schema=public" \
           node /vagrant/server/build/main.js
         ```

1. Worker 0 node

   ```console
   vagrant ssh worker-0
   ```

   1. Install script

      > Terminal 2
      >
      > Wait until it is asked to start reCluster server and go to the next step

      ```console
      /vagrant/linux/install.sh \
        --config /vagrant/linux/config.worker.yaml
      ```

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](LICENSE) file for details.
