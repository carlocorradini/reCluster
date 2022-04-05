import { buildFederatedSchema } from '@recluster/helpers';
import { NodeResolver, resolveNodeReference } from './resolvers';
import { Node } from './types';

export const schema = buildFederatedSchema(
  {
    resolvers: [NodeResolver],
    orphanedTypes: [Node]
  },
  {
    Node: { __resolveReference: resolveNodeReference }
  }
);
