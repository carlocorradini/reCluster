import fs from 'fs';
import path from 'path';
import { ApolloServer } from 'apollo-server';
import { ApolloGateway } from '@apollo/gateway';

const supergraphSdl = fs
  .readFileSync(path.join(__dirname, './supergraph.graphql'))
  .toString();
const gateway = new ApolloGateway({ supergraphSdl });
const server = new ApolloServer({ gateway, debug: true });

server
  .listen({ port: 8080 })
  .then(({ url }) => console.log(`🚀 Gateway ready at ${url}`));
