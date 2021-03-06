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

import { Prisma } from '@prisma/client';
import { GraphQLBigInt } from 'graphql-scalars';
import { Field, InputType } from 'type-graphql';
import { PickRequired } from '~/utils';
import { CreateCpuInput } from './CreateCpuInput';
import { CreateDiskInput } from './CreateDiskInput';
import { CreateInterfaceInput } from './CreateInterfaceInput';

type ICreateNodeInput = PickRequired<Omit<Prisma.NodeCreateInput, 'status'>> & {
  cpu: CreateCpuInput;
  disks: CreateDiskInput[];
  interfaces: CreateInterfaceInput[];
};

@InputType({ description: 'Create Node input' })
export class CreateNodeInput implements ICreateNodeInput {
  @Field(() => GraphQLBigInt, { description: 'Node ram' })
  ram!: bigint;

  @Field(() => CreateCpuInput, { description: 'Node Cpu' })
  cpu!: CreateCpuInput;

  @Field(() => [CreateDiskInput], { description: 'Node disks' })
  disks!: CreateDiskInput[];

  @Field(() => [CreateInterfaceInput], { description: 'Node interfaces' })
  interfaces!: CreateInterfaceInput[];
}
