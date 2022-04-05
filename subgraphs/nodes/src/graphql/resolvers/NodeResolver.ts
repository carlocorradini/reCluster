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

import { Arg, Query, Resolver } from 'type-graphql';
import { GraphQLID } from '@recluster/graphql';
import { nodes } from '~/data';
import { Node } from '../types';

@Resolver(Node)
export class NodeResolver {
  // eslint-disable-next-line class-methods-use-this
  @Query(() => Node, { nullable: true })
  async node(
    @Arg('id', () => GraphQLID) id: string
  ): Promise<Node | undefined> {
    return nodes.find((node) => node.id === id);
  }

  // eslint-disable-next-line class-methods-use-this
  @Query(() => [Node])
  async nodes(): Promise<Node[]> {
    return nodes;
  }
}
