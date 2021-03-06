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

import { GraphQLID } from 'graphql';
import { Node as NodePrisma } from '@prisma/client';
import { Field, ObjectType, registerEnumType } from 'type-graphql';
import { GraphQLBigInt, GraphQLTimestamp } from 'graphql-scalars';

export enum NodeStatus {
  ACTIVE = 'ACTIVE',
  ACTIVE_TO_WORKING = 'ACTIVE_TO_WORKING',
  ACTIVE_TO_INACTIVE = 'ACTIVE_TO_INACTIVE',
  WORKING = 'WORKING',
  WORKING_TO_ACTIVE = 'WORKING_TO_ACTIVE',
  INACTIVE = 'INACTIVE',
  INACTIVE_TO_ACTIVE = 'INACTIVE_TO_ACTIVE',
  ERROR = 'ERROR'
}
registerEnumType(NodeStatus, {
  name: 'NodeStatus',
  description: 'Node status'
});

@ObjectType({ description: 'Node' })
export class Node implements NodePrisma {
  @Field(() => GraphQLID, { description: 'Node identifier' })
  id!: string;

  @Field(() => GraphQLBigInt, { description: 'Node ram' })
  ram!: bigint;

  cpuId!: string;

  @Field(() => NodeStatus, { description: 'Node status' })
  status!: NodeStatus;

  @Field(() => GraphQLTimestamp, { description: 'Creation timestamp' })
  createdAt!: Date;

  @Field(() => GraphQLTimestamp, { description: 'Update timestamp' })
  updatedAt!: Date;
}
