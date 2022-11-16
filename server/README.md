# reCluster Server

reCluster server.

## Development

> **Note**: _dummy_ certificates are automatically generated

### Requirements

| **Name**  | **Homepage**             |
| --------- | ------------------------ |
| `Docker`  | <https://www.docker.com> |
| `K3d`     | <https://k3d.io>         |
| `Node.js` | <https://nodejs.org>     |
| `npm`     | <https://www.npmjs.com>  |

### Environment

> **Note**: Copy `.env.example` and paste `.env`

| **Name**            | **Description**   | **Default**  | **Values**                              |
| ------------------- | ----------------- | ------------ | --------------------------------------- |
| `NODE_ENV`          | Node environment  | `production` | `development` \| `production` \| `test` |
| `HOST`              | Server host       | `0.0.0.0`    | Any valid host                          |
| `PORT`              | Server port       | `80`         | Any valid port                          |
| `DATABASE_URL`      | Database URL      |              |
| `SSH_USERNAME`      | SSH username      | `root`       | Any valid username                      |
| `SSH_PRIVATE_KEY`   | SSH private key   |              |
| `TOKEN_PRIVATE_KEY` | Token private key |              |
| `TOKEN_PUBLIC_KEY`  | Token public key  |              |

### Preparation

1. Environment

   > **Note**: See [Environment](#environment) for more information

   Edit `.env` according to your configuration.

1. Start

   > **Note**: Type `-- --help` for more information

   ```sh
   npm run dev
   ```

1. Execute Queries

   - Apollo Studio \
     Visit <http://localhost:8080> in your browser

   - Manually

   ```sh
   curl --request POST \
     --header 'content-type: application/json' \
     --url 'http://localhost:8080' \
     --data '{ "query": "query { __typename }" }'
   ```

### Scripts

> **Note**: Execute with `npm run <NAME>`

> **Warning**: On _Windows_, a script may fail to execute. Run it directly from `scripts` directory

| **Name**         | **Description**                                                                          |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `build`          | Compile server.                                                                          |
| `build:clean`    | Clean compilation directory.                                                             |
| `build:watch`    | Compile server every time a file is updated.                                             |
| `check`          | Check for errors.                                                                        |
| `dev`            | Prepare and start development environment.                                               |
| `db:generate`    | Generate database assets.                                                                |
| `db:reset`       | Deletes and recreates the database.                                                      |
| `db:seed`        | Seed database.                                                                           |
| `db:studio`      | Start a local web server with a web app that allows to interact and manage the database. |
| `db:sync`        | Synchronize database using migrations.                                                   |
| `dockerize`      | Generate Docker image.                                                                   |
| `fix`            | Fix errors.                                                                              |
| `graphql:schema` | Save GraphQL schema to file.                                                             |
| `start`          | Start compiled server.                                                                   |
| `start:dev`      | Start development/uncompiled server.                                                     |
