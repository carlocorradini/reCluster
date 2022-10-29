# reCluster Server

reCluster server.

## Development

### Requirements

| **Name**  | **Homepage**             |
| --------- | ------------------------ |
| `Docker`  | <https://www.docker.com> |
| `K3d`     | <https://k3d.io>         |
| `Node.js` | <https://nodejs.org>     |
| `npm`     | <https://www.npmjs.com>  |

### Preparation

1. Environment

   Copy `.env.example` and paste`.env` file. \
   Edit according to your configuration.

1. Start

   > **Note**: Type `-- --help` for more information

   ```console
   npm run dev
   ```

1. Execute Queries

   - Apollo Studio \
     Visit <http://localhost:8080> in your browser

   - Manually

   ```console
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
| `check:db`       | Check for database errors.                                                               |
| `check:lint`     | Check for linting errors.                                                                |
| `dev`            | Prepare and start development environment.                                               |
| `db:format`      | Format database file.                                                                    |
| `db:generate`    | Generate database assets.                                                                |
| `db:reset`       | Deletes and recreates the database.                                                      |
| `db:seed`        | Seed database.                                                                           |
| `db:studio`      | Start a local web server with a web app that allows to interact and manage the database. |
| `db:sync`        | Synchronize database using migrations.                                                   |
| `dockerize`      | Generate Docker image.                                                                   |
| `fix`            | Fix errors.                                                                              |
| `fix:db`         | Fix database errors.                                                                     |
| `fix:lint`       | Fix linting errors.                                                                      |
| `graphql:schema` | Save GraphQL schema to file.                                                             |
| `start`          | Start compiled server.                                                                   |
| `start:dev`      | Start development/uncompiled server.                                                     |
