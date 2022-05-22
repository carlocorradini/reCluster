# reCluster Backend

reCluster backend.

## Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)
- [Docker](https://www.docker.com)

## Build

```console
npm run build
```

## Development

1. Environment

   Copy & paste `.env.example` file, name it `.env` and edit it according to your configuration.

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
     Visit <http://localhost:8080> in your browser.

   - Manually

   TODO

     ```console
     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:8080/graphql' \
         --data '{ "query": "mutation { addNode(node: { name: \"Test\" }) { id, name } }" }'

     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:8080/graphql' \
         --data '{ "query": "{ nodes { id, name } }" }'
     ```
