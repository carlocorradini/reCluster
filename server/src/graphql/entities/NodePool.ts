/*
 * MIT License
 *
 * Copyright (c) 2022-2023 Carlo Corradini
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

import type * as Prisma from '@prisma/client';
import { GraphQLBoolean, GraphQLID, GraphQLInt, GraphQLString } from 'graphql';
import { Field, ObjectType } from 'type-graphql';
import { GraphQLTimestamp } from 'graphql-scalars';
// eslint-disable-next-line import/no-cycle
import { Node } from './Node';

@ObjectType({ description: 'Node pool' })
export class NodePool implements Prisma.NodePool {
  @Field(() => GraphQLID, { description: 'Node pool identifier' })
  id!: string;

  @Field(() => GraphQLString, { description: 'Node pool name' })
  name!: string;

  @Field(() => GraphQLBoolean, { description: 'Node pool auto scale flag' })
  autoScale!: boolean;

  @Field(() => GraphQLInt, {
    description: 'Node pool minimum number of nodes'
  })
  minNodes!: number;

  @Field(() => GraphQLTimestamp, { description: 'Creation timestamp' })
  createdAt!: Date;

  @Field(() => GraphQLTimestamp, { description: 'Up date timestamp' })
  updatedAt!: Date;

  /* Field resolvers */

  @Field(() => GraphQLInt, { description: 'Node pool node count' })
  count!: number;

  @Field(() => GraphQLInt, { description: 'Node pool maximum number of nodes' })
  maxNodes!: number;

  @Field(() => [Node], { description: 'Node pool nodes' })
  nodes!: Node[];
}
