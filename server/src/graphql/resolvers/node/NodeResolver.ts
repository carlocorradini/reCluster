/*
 * MIT License
 *
 * Copyright (c) 2022-2023 Carlo Corradini
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
  Ctx,
  FieldResolver,
  Mutation,
  Query,
  Resolver,
  ResolverInterface,
  Root
} from 'type-graphql';
import { inject, injectable } from 'tsyringe';
import { GraphQLBigInt, GraphQLJWT } from 'graphql-scalars';
import { convert } from 'convert';
import type { Context } from '~/types';
import { UserRoleEnum } from '~/db';
import { NodeService } from '~/services';
import { Auth } from '~/helpers';
import { DigitalUnitEnum } from '../../enums';
import { Node } from '../../entities';
import {
  CreateNodeArgs,
  FindUniqueNodeArgs,
  FindManyNodeArgs,
  UnassignNodeArgs
} from '../../args';

@Resolver(Node)
@injectable()
export class NodeResolver implements ResolverInterface<Node> {
  public constructor(
    @inject(NodeService)
    private readonly nodeService: NodeService
  ) {}

  @Query(() => [Node], { description: 'List of nodes' })
  public nodes(@Args() args: FindManyNodeArgs) {
    return this.nodeService.findMany(args);
  }

  @Query(() => Node, {
    nullable: true,
    description: 'Node matching the identifier'
  })
  public node(@Args() args: FindUniqueNodeArgs) {
    return this.nodeService.findUnique({ where: { id: args.id } });
  }

  @Mutation(() => GraphQLJWT, { description: 'Create a new node' })
  public createNode(@Args() args: CreateNodeArgs, @Ctx() context: Context) {
    return this.nodeService.create({
      ...args,
      data: { ...args.data, address: context.ip }
    });
  }

  @Mutation(() => Node, { description: 'Unassign node from node pool' })
  @Auth({ roles: UserRoleEnum.ADMIN })
  public unassignNode(@Args() args: UnassignNodeArgs) {
    return this.nodeService.unassign({ ...args, where: { id: args.id } });
  }

  @FieldResolver(() => GraphQLBigInt)
  public memory(
    @Root() node: Node,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(node.memory, DigitalUnitEnum.B).to(unit);
  }
}
