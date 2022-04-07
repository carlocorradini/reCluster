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

import { Arg, Mutation, Query, Resolver } from 'type-graphql';
import { Service, Inject } from 'typedi';
import { GraphQLID, Node } from '@recluster/graphql';
import { PrismaClient } from '@prisma/client';
import { NodeAddInput } from '~graphql/inputs';

@Resolver(Node)
@Service()
export class NodeResolver {
  @Inject()
  private readonly prisma!: PrismaClient;

  @Query(() => [Node])
  async nodes() {
    return this.prisma.node.findMany();
  }

  @Query(() => Node, { nullable: true })
  async node(@Arg('id', () => GraphQLID) id: string) {
    return this.prisma.node.findUnique({ where: { id } });
  }

  @Mutation(() => Node)
  async addNode(@Arg('node') nodeInput: NodeAddInput) {
    return this.prisma.node.create({ data: { ...nodeInput } });
  }
}
