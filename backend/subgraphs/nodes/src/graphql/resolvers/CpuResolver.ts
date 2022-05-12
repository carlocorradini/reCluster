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

import { Args, FieldResolver, Query, Resolver, Root } from 'type-graphql';
import { PrismaClient } from '@prisma/client';
import { Fields, FieldsMap, Prisma, RemoveNullArgs } from '@recluster/graphql';
import { RequiredFieldError } from '@recluster/errors';
import { Cpu, Node } from '../entities';
import { CpuArgs, CpusArgs, NodesArgs } from '../args';

@Resolver(Cpu)
export class CpuResolver {
  @Query(() => [Cpu], { description: 'List of Cpus' })
  @RemoveNullArgs()
  async cpus(
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: CpusArgs
  ) {
    return prisma.cpu.findMany({
      select: fields,
      where: args.where,
      orderBy: args.orderBy,
      cursor: args.cursor ? { id: args.cursor } : undefined,
      take: args.take,
      skip: args.skip
    });
  }

  @Query(() => Cpu, {
    nullable: true,
    description: 'Cpu matching the identifier'
  })
  @RemoveNullArgs()
  async cpu(
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: CpuArgs
  ) {
    return prisma.cpu.findUnique({ where: { id: args.id }, select: fields });
  }

  @FieldResolver(() => [Node], { description: 'Nodes equipped Cpu' })
  @RemoveNullArgs()
  async nodes(
    @Root() cpu: Cpu,
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: NodesArgs
  ) {
    if (!cpu.id) throw new RequiredFieldError('id', cpu.constructor.name);

    return prisma.node.findMany({
      select: fields,
      where: { ...args.where, cpuId: cpu.id },
      orderBy: args.orderBy,
      cursor: args.cursor ? { id: args.cursor } : undefined,
      take: args.take,
      skip: args.skip
    });
  }
}
