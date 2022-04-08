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

import { Service } from 'typedi';
import { prisma } from '@recluster/database';
import { NodeAddInput } from '~graphql/inputs';
import { PaginationArgs } from '@recluster/graphql';

@Service()
export class NodeService {
  private readonly prisma = prisma;

  public async nodes(options: PaginationArgs) {
    return this.prisma.node.findMany({
      skip: options.cursor ? options.skip + 1 : options.skip,
      take: options.take,
      ...(options.cursor && { cursor: { id: options.cursor } }),
      orderBy: { id: 'asc' }
    });
  }

  async node(id: string) {
    return this.prisma.node.findUnique({ where: { id } });
  }

  async addNode(input: NodeAddInput) {
    return this.prisma.node.create({ data: { ...input } });
  }
}
