import 'reflect-metadata';
import { ApolloServer } from 'apollo-server-fastify';
import { ApolloServerPluginDrainHttpServer } from 'apollo-server-core';
import { ApolloServerPlugin } from 'apollo-server-plugin-base';
import fastify, { FastifyInstance } from 'fastify';
import { schema } from './graphql';

function fastifyAppClosePlugin(app: FastifyInstance): ApolloServerPlugin {
  return {
    async serverWillStart() {
      return {
        async drainServer() {
          await app.close();
        }
      };
    }
  };
}

async function main() {
  const app = fastify();
  const server = new ApolloServer({
    schema,
    plugins: [
      fastifyAppClosePlugin(app),
      ApolloServerPluginDrainHttpServer({ httpServer: app.server })
    ]
  });

  await server.start();
  await app.register(server.createHandler());
  await app.listen(4000);
  console.log(`🚀 Server ready at http://localhost:4000${server.graphqlPath}`);
}

main()
  .then(() => {})
  .catch(() => {});
