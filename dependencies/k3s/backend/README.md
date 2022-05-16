# reCluster Backend

reCluster backend.

## Requirements

- [Node.js](https://nodejs.org)
- [npm](https://www.npmjs.com)
- [Docker](https://www.docker.com)

## Build

```bash
npm run build
```

## Development

1. Environment

   Copy & paste each `.env.example` file, name it `.env` and edit it according to your configuration.

   Here is the location of each `.env.example`:

   - `.env.example`

   - `subgraphs/nodes/.env.example`

   - `subgraphs/cpus/.env.example`

1. Database

   Start:

   ```bash
   scripts/database.sh
   ```

   Synchronize:

   ```bash
   npm run db:migrate
   ```

1. Subgraphs

   - Nodes

     ```bash
     npm run watch --workspace=subgraphs/nodes
     ```

   - Cpus

     ```bash
     npm run watch --workspace=subgraphs/cpus
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
         --url 'http://localhost:4000/graphql' \
         --data '{ "query": "mutation { addNode(node: { name: \"Test\" }) { id, name } }" }'

     curl --request POST \
         --header 'content-type: application/json' \
         --url 'http://localhost:4000/graphql' \
         --data '{ "query": "{ nodes { id, name } }" }'
     ```
