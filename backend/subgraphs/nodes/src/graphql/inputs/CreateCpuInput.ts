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

import { Field, InputType, registerEnumType } from 'type-graphql';
import { GraphQLNonEmptyString, GraphQLPositiveInt } from 'graphql-scalars';
import { CpuArchitecture, CpuVendor } from '@prisma/client';
import { Cpu } from '../entities';

registerEnumType(CpuArchitecture, {
  name: 'CpuArchitecture',
  description: 'Cpu architecture'
});

registerEnumType(CpuVendor, { name: 'CpuVendor', description: 'Cpu vendor' });

@InputType({ description: 'Create Cpu input' })
export class CreateCpuInput
  implements Required<Omit<Cpu, 'id' | 'createdAt' | 'updatedAt'>>
{
  @Field(() => CpuArchitecture, { description: 'Cpu architecture' })
  architecture!: CpuArchitecture;

  @Field(() => [GraphQLNonEmptyString], { description: 'Cpu flags' })
  flags!: string[];

  @Field(() => GraphQLPositiveInt, { description: 'Cpu cores' })
  cores!: number;

  @Field(() => CpuVendor, { description: 'Cpu vendor' })
  vendor!: CpuVendor;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu family' })
  family!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu model' })
  model!: number;

  @Field(() => GraphQLNonEmptyString, { description: 'Cpu name' })
  name!: string;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu L1d cache' })
  cacheL1d!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu L1i cache' })
  cacheL1i!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu L2 cache' })
  cacheL2!: number;

  @Field(() => GraphQLPositiveInt, { description: 'Cpu L3 cache' })
  cacheL3!: number;

  @Field(() => [GraphQLNonEmptyString], { description: 'Cpu vulnerabilities' })
  vulnerabilities!: string[];
}