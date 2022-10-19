# reCluster Server

reCluster server.

## Development

### Preparation

1. Environment

   Copy `.env.example` and paste`.env` file. \
   Edit according to your configuration.

1. Database

   Start:

   ```console
   npm run db:start
   ```

   Synchronize:

   ```console
   npm run db:migrate
   ```

1. Server

   ```console
   npm run start:dev
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

| **Name**      | **Description**                                                                          |
| ------------- | ---------------------------------------------------------------------------------------- |
| `build`       | Compile server.                                                                          |
| `build:clean` | Clean compilation directory.                                                             |
| `build:watch` | Compile server every time a file is updated.                                             |
| `check`       | Check for errors.                                                                        |
| `check:db`    | Check for database errors.                                                               |
| `check:lint`  | Check for linting errors.                                                                |
| `db:format`   | Format database file.                                                                    |
| `db:generate` | Generate database assets.                                                                |
| `db:migrate`  | Updates database using migrations.                                                       |
| `db:reset`    | Deletes and recreates the database.                                                      |
| `db:seed`     | Seed database.                                                                           |
| `db:start`    | Start a local database.                                                                  |
| `db:studio`   | Start a local web server with a web app that allows to interact and manage the database. |
| `docker`      | Generate Docker image.                                                                   |
| `fix`         | Fix errors.                                                                              |
| `fix:db`      | Fix database errors.                                                                     |
| `fix:lint`    | Fix linting errors.                                                                      |
| `start`       | Start compiled server.                                                                   |
| `start:dev`   | Start development/uncompiled server.                                                     |
