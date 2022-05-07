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

import { Directive, Field, ObjectType, registerEnumType } from 'type-graphql';
import { CpuArchitecture, CpuVendor } from '@prisma/client';
import {
  GraphQLID,
  GraphQLNonEmptyString,
  GraphQLPositiveInt,
  GraphQLTimestamp
} from '@recluster/graphql';

@ObjectType({ description: 'CPU (Central Processing Unit)' })
@Directive(`@key(fields: "id")`)
export class Cpu {
  @Field(() => GraphQLID, { description: 'CPU identifier' })
  id!: string;

  @Field(() => CpuArchitecture, { description: 'CPU architecture' })
  architecture!: CpuArchitecture;

  @Field(() => [GraphQLNonEmptyString], { description: 'CPU flags' })
  flags!: string[];

  @Field(() => GraphQLPositiveInt, { description: 'CPU cores' })
  cores!: number[];

  @Field(() => CpuVendor, { description: 'CPU vendor' })
  vendor!: CpuVendor;

  @Field(() => GraphQLPositiveInt, { description: 'CPU family' })
  family!: number;

  @Field(() => GraphQLPositiveInt, { description: 'CPU model' })
  model!: number;

  @Field(() => GraphQLNonEmptyString, { description: 'CPU name' })
  name!: string;

  @Field(() => GraphQLPositiveInt, { description: 'CPU L1d cache' })
  cacheL1d!: number;

  @Field(() => GraphQLPositiveInt, { description: 'CPU L1i cache' })
  cacheL1i!: number;

  @Field(() => GraphQLPositiveInt, { description: 'CPU L2 cache' })
  cacheL2!: number;

  @Field(() => GraphQLPositiveInt, { description: 'CPU L3 cache' })
  cacheL3!: number;

  @Field(() => [GraphQLNonEmptyString], { description: 'CPU vulnerabilities' })
  vulnerabilities!: string[];

  @Field(() => GraphQLTimestamp, { description: 'Creation timestamp' })
  createdAt!: Date;

  @Field(() => GraphQLTimestamp, { description: 'Update timestamp' })
  updatedAt!: Date;
}

registerEnumType(CpuArchitecture, {
  name: 'CpuArchitecture',
  description: 'CPU architecture'
});

registerEnumType(CpuVendor, {
  name: 'CpuVendor',
  description: 'CPU vendor'
});
