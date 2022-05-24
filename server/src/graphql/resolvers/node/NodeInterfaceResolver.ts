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

import { PrismaClient } from '@prisma/client';
import { Args, FieldResolver, Resolver, Root } from 'type-graphql';
import { Prisma } from '../../decorators';
import { PaginationArgs } from '../../args';
import { Node, Interface } from '../../entities';

@Resolver(() => Node)
export class NodeInterfaceResolver {
  @FieldResolver(() => [Interface], { description: 'Node interfaces' })
  async interfaces(
    @Root() node: Node,
    @Prisma() prisma: PrismaClient,
    @Args() args: PaginationArgs
  ) {
    return prisma.interface.findMany({
      where: { nodeId: node.id },
      cursor: args.cursor ? { id: args.cursor } : undefined,
      take: args.take,
      skip: args.skip
    });
  }
}
