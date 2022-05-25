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
import { Service, Inject } from 'typedi';
import { GraphQLBigInt } from 'graphql-scalars';
import configMeasurements, { digital } from 'convert-units';
import { NodeService } from '~/services';
import { DigitalByteUnit } from '../../enums';
import { Node } from '../../entities';
import {
  CreateNodeArgs,
  FindUniqueNodeArgs,
  FindManyNodeArgs
} from '../../args';

const convert = configMeasurements({ digital });

@Resolver(Node)
@Service()
export class NodeResolver {
  @Inject()
  private readonly nodeService!: NodeService;

  @Query(() => [Node], { description: 'List of nodes' })
  async nodes(@Args() args: FindManyNodeArgs) {
    return this.nodeService.findMany(args);
  }

  @Query(() => Node, {
    nullable: true,
    description: 'Node matching the identifier'
  })
  async node(@Args() args: FindUniqueNodeArgs) {
    return this.nodeService.findUnique({ ...args, where: { id: args.id } });
  }

  @Mutation(() => Node, { description: 'Create a new node' })
  async createNode(@Args() args: CreateNodeArgs) {
    return this.nodeService.create(args);
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
