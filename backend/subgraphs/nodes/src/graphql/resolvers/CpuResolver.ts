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

import { Arg, Args, FieldResolver, Query, Resolver, Root } from 'type-graphql';
import { Service, Inject } from 'typedi';
import { GraphQLID } from '@recluster/graphql';
import { CpuService, NodeService } from '~/services';
import { NodesArgs, CpusArgs } from '~graphql/args';
import { Cpu, Node } from '../entities';

@Resolver(Cpu)
@Service()
export class CpuResolver {
  @Inject()
  private readonly cpuService!: CpuService;

  @Inject()
  private readonly nodeService!: NodeService;

  @Query(() => [Cpu], { description: 'List of CPUs' })
  async cpus(@Args() options: CpusArgs) {
    return this.cpuService.cpus(options);
  }

  @Query(() => Cpu, {
    nullable: true,
    description: 'CPU matching the identifier'
  })
  async cpu(
    @Arg('id', () => GraphQLID, { description: 'CPU identifier' }) id: string
  ) {
    return this.cpuService.cpu(id);
  }

  @FieldResolver(() => [Node], { description: 'Nodes equipped CPU' })
  async nodes(@Root() cpu: Cpu, @Args() options: NodesArgs) {
    return this.nodeService.nodes({ ...options, cpuId: cpu.id });
  }
}
