# reCluster Server

reCluster server.

## Certificates

> **Note**: In development, _dummy_ certificates are automatically generated

### SSH

```console
filename="ssh"
passphrase="password"

ssh-keygen -b 2048 -t rsa -f "$filename" -N "$passphrase"
chmod 600 "$filename" "$filename.pub"
```

### Token

```console
filename="token"
passphrase="password"

ssh-keygen -b 4096 -t rsa -f "$filename" -N "$passphrase" -m PEM
ssh-keygen -e -m PEM -f "$filename" -P "$passphrase" > "$filename.pub"
chmod 600 "$filename" "$filename.pub"
```

## Development

### Requirements

| **Name**  | **Homepage**             |
| --------- | ------------------------ |
| `Docker`  | <https://www.docker.com> |
| `K3d`     | <https://k3d.io>         |
| `Node.js` | <https://nodejs.org>     |
| `npm`     | <https://www.npmjs.com>  |

### Environment

> **Note**: Copy `.env.example` and paste `.env`

| **Name**            | **Description**   | **Choices**                             | **Default**  |
| ------------------- | ----------------- | --------------------------------------- | ------------ |
| `NODE_ENV`          | Node environment  | `development` \| `production` \| `test` | `production` |
| `HOST`              | Server host       |                                         | `0.0.0.0`    |
| `PORT`              | Server port       |                                         | `80`         |
| `DATABASE_URL`      | Database URL      |                                         |              |
| `SSH_USERNAME`      | SSH username      |                                         | `root`       |
| `SSH_PRIVATE_KEY`   | SSH private key   |                                         |              |
| `TOKEN_PRIVATE_KEY` | Token private key |                                         |              |
| `TOKEN_PUBLIC_KEY`  | Token public key  |                                         |              |

### Preparation

1. Environment

   > **Note**: See [Environment](#environment) for more information

   Edit `.env` according to your configuration.

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
