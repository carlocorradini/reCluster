# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)

The reCluster is an architecture for a data centre that actively reduces its impact and minimizes its resource utilization.

## Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)
- [Docker](https://www.docker.com)

## Getting Started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes.

1. Clone

   ```bash
   git clone https://github.com/carlocorradini/reCluster.git
   cd reCluster
   ```

1. Scripts Permissions

   ```bash
   chmod -R +x scripts
   ```

1. Install Dependencies

   ```bash
   npm install
   ```

1. Build

   ```bash
   npm run build
   ```

## Development

1. Services

   - Nodes

     ```bash
     npm run watch --workspace=subgraphs/nodes
     ```

1. Router

   ```bash
   scripts/router.sh
   ```

1. Execute Queries

   - Apollo Sandbox \
     Visit <http://localhost:4000> in your browser.

   - Manually

     ```bash
     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:4000' \
         --data '{"query": "{ nodes { id, name } }"}'
     ```

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](LICENSE) file for details.
