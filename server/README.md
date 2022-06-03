# reCluster Server

reCluster server

## Build

```console
npm run build
```

## Development

### Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)
- [Docker](https://www.docker.com)

### Preparation

1. Environment

   Copy & paste `.env.example` file, name it `.env` and edit it according to your configuration

1. Database

   Start:

   ```console
   scripts/database.sh
   ```

   Synchronize:

   ```console
   npm run db:migrate
   ```

1. Server

   ```console
   npm run watch
   ```

1. Execute Queries

   - Apollo Sandbox \
     Visit <http://localhost:8080> in your browser

   - Manually

   ```console
   curl --request POST \
       --header 'content-type: application/json' \
       --url 'http://localhost:8080/graphql' \
       --data '{ "query": "{ nodes { id cpu { name } } }" }'
   ```
