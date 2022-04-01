import { buildSchemaSync } from 'type-graphql';
import { NodeResolver } from './resolvers';

export const schema = buildSchemaSync({ resolvers: [NodeResolver] });
