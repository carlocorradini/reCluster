import {
  BuildSchemaOptions,
  buildSchemaSync,
  createResolversMap
} from 'type-graphql';
import { specifiedDirectives } from 'graphql';
import { buildSubgraphSchema } from '@apollo/subgraph';
import { addResolversToSchema } from '@graphql-tools/schema';
import { IResolvers, printSchemaWithDirectives } from '@graphql-tools/utils';
import gql from 'graphql-tag';

export function buildFederatedSchema(
  options: Omit<BuildSchemaOptions, 'skipCheck'>,
  referenceResolvers?: IResolvers
) {
  const schema = buildSchemaSync({
    ...options,
    directives: [...specifiedDirectives, ...(options.directives || [])],
    skipCheck: true
  });

  const federatedSchema = buildSubgraphSchema({
    typeDefs: gql(printSchemaWithDirectives(schema)),
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    resolvers: createResolversMap(schema) as any
  });

  if (referenceResolvers) {
    addResolversToSchema(federatedSchema, referenceResolvers);
  }

  return federatedSchema;
}
