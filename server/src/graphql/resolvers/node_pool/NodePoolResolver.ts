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

import { GraphQLInt } from 'graphql';
import {
  Args,
  FieldResolver,
  Mutation,
  Query,
  Resolver,
  Root
} from 'type-graphql';
import { inject, injectable } from 'tsyringe';
import { NodePoolService } from '~/services';
import { NodePool, Node } from '../../entities';
import {
  DeleteNodePoolNodeArgs,
  FindManyNodePoolArgs,
  FindUniqueNodePoolArgs,
  UpdateNodePoolArgs
} from '../../args';

@Resolver(NodePool)
@injectable()
export class NodePoolResolver {
  public constructor(
    @inject(NodePoolService)
    private readonly nodePoolService: NodePoolService
  ) {}

  @Query(() => [NodePool], { description: 'List of Node pools' })
  public nodePools(@Args() args: FindManyNodePoolArgs) {
    return this.nodePoolService.findMany(args);
  }

  @Query(() => NodePool, {
    nullable: true,
    description: 'Node pool matching the identifier'
  })
  public nodePool(@Args() args: FindUniqueNodePoolArgs) {
    return this.nodePoolService.findUnique({ where: { id: args.id } });
  }

  @Mutation(() => NodePool, { description: 'Update Node pool' })
  public updateNodePool(@Args() args: UpdateNodePoolArgs) {
    return this.nodePoolService.update({
      where: { id: args.id },
      data: args.data
    });
  }

  @Mutation(() => Node, { description: 'Delete Node from Node pool' })
  public deleteNodePoolNode(@Args() args: DeleteNodePoolNodeArgs) {
    return this.nodePoolService.deleteNode({
      id: args.id,
      nodeId: args.nodeId
    });
  }

  @FieldResolver(() => GraphQLInt, { description: 'Node pool node count' })
  public count(@Root() nodePool: NodePool) {
    return this.nodePoolService.count({ id: nodePool.id });
  }

  @FieldResolver(() => GraphQLInt, {
    description: 'Node pool maximum number of nodes'
  })
  public maxNodes(@Root() nodePool: NodePool) {
    return this.nodePoolService.maxNodes({ id: nodePool.id });
  }
}
