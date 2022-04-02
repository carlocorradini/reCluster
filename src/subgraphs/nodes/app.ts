import 'reflect-metadata';
import { ApolloServer } from 'apollo-server';
import { schema } from './graphql';

const server = new ApolloServer({
  schema
});

server
  .listen({ port: 4000, host: '0.0.0.0' })
  .then(({ url }) => console.log(`🚀 Server ready at ${url}`));
