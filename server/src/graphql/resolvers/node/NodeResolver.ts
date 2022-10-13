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
import {
  Arg,
  Args,
  FieldResolver,
  Mutation,
  Query,
  Resolver,
  Root
} from 'type-graphql';
import { inject, injectable } from 'tsyringe';
import { GraphQLBigInt, GraphQLJWT } from 'graphql-scalars';
import { convert } from 'convert';
import { NodeService } from '~/services';
import { DigitalUnits } from '../../enums';
import { Node } from '../../entities';
import {
  CreateNodeArgs,
  FindUniqueNodeArgs,
  FindManyNodeArgs,
  UpdateNodeArgs
} from '../../args';

@Resolver(Node)
@injectable()
export class NodeResolver {
  public constructor(
    @inject(NodeService)
    private readonly nodeService: NodeService
  ) {}

  @Query(() => [Node], { description: 'List of nodes' })
  async nodes(@Args() args: FindManyNodeArgs): Promise<Prisma.Node[]> {
    return this.nodeService.findMany(args);
  }

  @Query(() => Node, {
    nullable: true,
    description: 'Node matching the identifier'
  })
  async node(@Args() args: FindUniqueNodeArgs): Promise<Prisma.Node | null> {
    return this.nodeService.findUnique(args);
  }

  @Mutation(() => GraphQLJWT, { description: 'Create a new node' })
  async createNode(@Args() args: CreateNodeArgs): Promise<string> {
    return this.nodeService.create(args);
  }

  @Mutation(() => Node, { description: 'Update node' })
  async updateNode(@Args() args: UpdateNodeArgs): Promise<Prisma.Node> {
    return this.nodeService.update(args);
  }

  @FieldResolver(() => GraphQLBigInt)
  ram(
    @Root() node: Node,
    @Arg('unit', () => DigitalUnits, {
      defaultValue: DigitalUnits.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnits
  ): bigint {
    return convert(node.ram, DigitalUnits.B).to(unit);
  }
}
