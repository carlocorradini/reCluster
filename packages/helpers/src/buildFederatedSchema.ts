/*
 * MIT License
 *
 * Copyright (c) 2022-2022 Carlo Corradini
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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
