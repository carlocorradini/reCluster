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

import {
  Arg,
  Args,
  FieldResolver,
  Mutation,
  Query,
  Resolver,
  Root
} from 'type-graphql';
import { PrismaClient } from '@prisma/client';
import { GraphQLBigInt } from 'graphql-scalars';
import configMeasurements, { digital } from 'convert-units';
import { Fields, FieldsMap, Prisma, DigitalByteUnit } from '@recluster/graphql';
import { Node } from '../entities';
import { CreateNodeArgs, NodeArgs, NodesArgs } from '../args';

const convert = configMeasurements({ digital });

@Resolver(Node)
export class NodeResolver {
  @Query(() => [Node], { description: 'List of nodes' })
  async nodes(
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: NodesArgs
  ) {
    return prisma.node.findMany({
      select: fields,
      where: args.where,
      orderBy: args.orderBy,
      cursor: args.cursor ? { id: args.cursor } : undefined,
      take: args.take,
      skip: args.skip
    });
  }

  @Query(() => Node, {
    nullable: true,
    description: 'Node matching the identifier'
  })
  async node(
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: NodeArgs
  ) {
    return prisma.node.findUnique({
      select: fields,
      where: { id: args.id }
    });
  }

  @Mutation(() => Node, { description: 'Create a new node' })
  async createNode(
    @Fields() fields: FieldsMap,
    @Prisma() prisma: PrismaClient,
    @Args() args: CreateNodeArgs
  ) {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    const vendor_family_model = {
      vendor: args.data.cpu.vendor,
      family: args.data.cpu.family,
      model: args.data.cpu.model
    };

    // Find old vulnerabilities (if any)
    // FIXME Should be done in upsert
    const cpu = await prisma.cpu.findUnique({
      where: { vendor_family_model },
      select: { vulnerabilities: true }
    });
    const vulnerabilities = Array.from(
      new Set([
        ...(cpu?.vulnerabilities ?? []),
        ...args.data.cpu.vulnerabilities
      ])
    );

    // Add or update cpu
    await prisma.cpu.upsert({
      where: { vendor_family_model },
      update: { vulnerabilities },
      create: args.data.cpu
    });

    // Create
    return prisma.node.create({
      select: fields,
      data: {
        ...args.data,
        cpu: { connect: { vendor_family_model } }
      }
    });
  }

  @FieldResolver(() => GraphQLBigInt)
  ram(
    @Root() node: Node,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    // FIXME BigInt conversion
    return Math.round(
      convert(Number(node.ram))
        .from(DigitalByteUnit.B)
        .to(unit ?? DigitalByteUnit.B)
    );
  }
}
