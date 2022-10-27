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
import { GraphQLID } from 'graphql';
import { Field, ObjectType } from 'type-graphql';
import {
  GraphQLNonEmptyString,
  GraphQLNonNegativeInt,
  GraphQLPositiveInt,
  GraphQLTimestamp
} from 'graphql-scalars';
import { CpuArchitectureEnum, CpuVendorEnum } from '~/db';

@ObjectType({ description: 'Cpu' })
export class Cpu implements Prisma.Cpu {
  @Field(() => GraphQLID, { description: 'Cpu identifier' })
  id!: string;

  @Field(() => CpuArchitectureEnum, { description: 'Cpu architecture' })
  architecture!: CpuArchitectureEnum;

  @Field(() => [GraphQLNonEmptyString], { description: 'Cpu flags' })
  flags!: string[];

  @Field(() => GraphQLPositiveInt, { description: 'Cpu cores' })
  cores!: number;

  @Field(() => CpuVendorEnum, { description: 'Cpu vendor' })
  vendor!: CpuVendorEnum;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu family' })
  family!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu model' })
  model!: number;

  @Field(() => GraphQLNonEmptyString, { description: 'Cpu name' })
  name!: string;

  @Field(() => GraphQLNonNegativeInt, { description: 'Cpu L1d cache' })
  cacheL1d!: number;

  @Field(() => GraphQLNonNegativeInt, { description: 'Cpu L1i cache' })
  cacheL1i!: number;

  @Field(() => GraphQLNonNegativeInt, { description: 'Cpu L2 cache' })
  cacheL2!: number;

  @Field(() => GraphQLNonNegativeInt, { description: 'Cpu L3 cache' })
  cacheL3!: number;

  @Field(() => [GraphQLNonEmptyString], { description: 'Cpu vulnerabilities' })
  vulnerabilities!: string[];

  @Field(() => GraphQLPositiveInt, { description: 'Cpu single-thread score' })
  singleThreadScore!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu multi-thread score' })
  multiThreadScore!: number;

  @Field(() => GraphQLPositiveInt, {
    nullable: true,
    description: 'Cpu efficiency threshold'
  })
  efficiencyThreshold!: number | null;

  @Field(() => GraphQLPositiveInt, {
    nullable: true,
    description: 'Cpu performance threshold'
  })
  performanceThreshold!: number | null;

  @Field(() => GraphQLTimestamp, { description: 'Creation timestamp' })
  createdAt!: Date;

  @Field(() => GraphQLTimestamp, { description: 'Update timestamp' })
  updatedAt!: Date;
}
