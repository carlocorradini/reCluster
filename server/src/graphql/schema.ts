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

import { GraphQLSchema } from 'graphql';
import { buildSchemaSync } from 'type-graphql';
import { mergeSchemas } from '@graphql-tools/schema';
import { container } from 'tsyringe';
import {
  CpuNodeResolver,
  CpuResolver,
  StorageNodeResolver,
  StorageResolver,
  InterfaceNodeResolver,
  InterfaceResolver,
  NodeCpuResolver,
  NodeStorageResolver,
  NodeInterfaceResolver,
  NodeNodePoolResolver,
  NodeStatusResolver,
  NodeResolver,
  NodePoolNodeResolver,
  NodePoolResolver,
  StatusNodeResolver,
  StatusResolver,
  UserResolver
} from './resolvers';
import { authDirective } from './directives';

// Directives
const directives = [authDirective] as const;

const schemaSimple = buildSchemaSync({
  resolvers: [
    CpuResolver,
    CpuNodeResolver,
    StorageResolver,
    StorageNodeResolver,
    InterfaceResolver,
    InterfaceNodeResolver,
    NodeResolver,
    NodeCpuResolver,
    NodeStorageResolver,
    NodeInterfaceResolver,
    NodeNodePoolResolver,
    NodeStatusResolver,
    NodePoolResolver,
    NodePoolNodeResolver,
    StatusResolver,
    StatusNodeResolver,
    UserResolver
  ],
  container: { get: (cls) => container.resolve(cls) },
  // FIXME forbidUnknownValues must be set to true
  validate: { forbidUnknownValues: false }
});

const schemaMerged = mergeSchemas({
  schemas: [schemaSimple],
  typeDefs: directives.map((directive) => directive.typeDefs)
});

export const schema: GraphQLSchema = directives.reduce(
  (newSchema, directive) => directive.transformer(newSchema),
  schemaMerged
);
