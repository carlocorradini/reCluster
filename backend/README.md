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

   Copy & paste each `.env.example` file, name it `.env` and edit it according to your configuration.

   Here is the location of each `.env.example`:

   - `.env.example`

   - `subgraphs/nodes/.env.example`

   - `subgraphs/nodes-res/.env.example`

1. Database

   Start:

   ```console
   scripts/database.sh
   ```

   Synchronize:

   ```console
   npm run db:migrate
   ```

1. Subgraphs

   - Nodes

     ```console
     npm run watch --workspace=subgraphs/nodes
     ```

   - Cpus

     ```console
     npm run watch --workspace=subgraphs/nodes-res
     ```

1. Router

   ```console
   scripts/router.sh
   ```

1. Execute Queries

   - Apollo Sandbox \
     Visit <http://localhost:4000> in your browser.

   - Manually

     ```console
     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:4000/graphql' \
         --data '{ "query": "mutation { addNode(node: { name: \"Test\" }) { id, name } }" }'

     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:4000/graphql' \
         --data '{ "query": "{ nodes { id, name } }" }'
     ```
