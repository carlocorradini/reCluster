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

import type * as Prisma from '@prisma/client';
import { GraphQLBoolean, GraphQLID, GraphQLInt, GraphQLString } from 'graphql';
import { Field, ObjectType } from 'type-graphql';
import { GraphQLBigInt, GraphQLIP, GraphQLTimestamp } from 'graphql-scalars';
import { NodeRoleEnum, NodePermissionEnum } from '~/db';

@ObjectType({ description: 'Node' })
export class Node implements Prisma.Node {
  @Field(() => GraphQLID, { description: 'Node identifier' })
  id!: string;

  @Field(() => GraphQLString, { description: 'Node name' })
  name!: string;

  @Field(() => [NodeRoleEnum], { description: 'Node roles' })
  roles!: NodeRoleEnum[];

  @Field(() => [NodePermissionEnum], { description: 'Node permissions' })
  permissions!: NodePermissionEnum[];

  @Field(() => GraphQLIP, { description: 'Node IP address' })
  address!: string;

  @Field(() => GraphQLString, { description: 'Node hostname' })
  hostname!: string;

  @Field(() => GraphQLBigInt, { description: 'Node memory' })
  memory!: bigint;

  cpuId!: string;

  nodePoolId!: string;

  @Field(() => GraphQLBoolean, { description: 'Node assigned to Node pool' })
  nodePoolAssigned!: boolean;

  @Field(() => GraphQLInt, { description: 'Minimum power consumption' })
  minPowerConsumption!: number;

  @Field(() => GraphQLInt, {
    nullable: true,
    description: 'Maximum efficiency power consumption'
  })
  maxEfficiencyPowerConsumption!: number | null;

  @Field(() => GraphQLInt, {
    nullable: true,
    description: 'Minimum performance power consumption'
  })
  minPerformancePowerConsumption!: number | null;

  @Field(() => GraphQLInt, { description: 'Maximum power consumption' })
  maxPowerConsumption!: number;

  @Field(() => GraphQLTimestamp, { description: 'Creation timestamp' })
  createdAt!: Date;

  @Field(() => GraphQLTimestamp, { description: 'Update timestamp' })
  updatedAt!: Date;
}
