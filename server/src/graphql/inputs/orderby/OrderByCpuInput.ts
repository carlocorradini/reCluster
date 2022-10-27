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

import type { Prisma } from '@prisma/client';
import { Field, InputType } from 'type-graphql';
import { SortOrderEnum } from '../../enums';

@InputType({ isAbstract: true, description: 'Cpu order by input' })
export class OrderByCpuInput
  implements Partial<Omit<Prisma.CpuOrderByWithRelationInput, 'nodes'>>
{
  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu identifier' })
  id?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Cpu architecture'
  })
  architecture?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu flags' })
  flags?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu cores' })
  cores?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu vendor' })
  vendor?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu family' })
  family?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu model' })
  model?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu name' })
  name?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu L1d cache' })
  cacheL1d?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu L1i cache' })
  cacheL1i?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu L2 cache' })
  cacheL2?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu L3 cache' })
  cacheL3?: SortOrderEnum;

  @Field(() => SortOrderEnum, { nullable: true, description: 'Cpu identifier' })
  vulnerabilities?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Cpu single-thread score'
  })
  singleThreadScore?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Cpu multi-thread score'
  })
  multiThreadScore?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Cpu efficiency threshold'
  })
  efficiencyThreshold?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Cpu performance threshold'
  })
  performanceThreshold?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Creation timestamp'
  })
  createdAt?: SortOrderEnum;

  @Field(() => SortOrderEnum, {
    nullable: true,
    description: 'Update timestamp'
  })
  updatedAt?: SortOrderEnum;
}
