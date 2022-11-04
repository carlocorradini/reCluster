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

import { NodePool as PrismaNodePool, Prisma } from '@prisma/client';
import { injectable, inject, delay } from 'tsyringe';
import type { UpdateNodePoolInput, WithRequired } from '~/types';
import { prisma } from '~/db';
import { logger } from '~/logger';
// eslint-disable-next-line import/no-cycle
import { NodeService } from './NodeService';
import { K8sService } from './K8sService';

type UpsertArgs = {
  data: { cpu: number; memory: number | bigint };
  select?: Prisma.NodePoolSelect | null;
};

type FindManyArgs = Omit<Prisma.NodePoolFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.NodePoolFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<
  Prisma.NodePoolFindUniqueOrThrowArgs,
  'include'
>;

type UpdateArgs = Omit<
  Prisma.NodePoolUpdateArgs,
  'include' | 'where' | 'data'
> & {
  where: WithRequired<Prisma.NodePoolWhereUniqueInput, 'id'>;
  data: UpdateNodePoolInput;
};

type DeleteNodeArgs = {
  id: string;
  nodeId: string;
};

type CountArgs = {
  id: string;
};

type MaxNodesArgs = {
  id: string;
};

@injectable()
export class NodePoolService {
  public constructor(
    @inject(delay(() => NodeService))
    private readonly nodeService: NodeService,
    @inject(K8sService)
    private readonly k8sService: K8sService
  ) {}

  // FIXME Return type
  public async upsert(args: UpsertArgs): Promise<PrismaNodePool> {
    logger.info(`Node pool service upsert: ${JSON.stringify(args)}`);

    const nodePool = await prisma.nodePool.findFirst({
      where: {
        nodes: {
          some: { cpu: { cores: args.data.cpu }, ram: args.data.memory }
        }
      },
      select: args.select
    });
    if (nodePool) return nodePool as PrismaNodePool;

    return prisma.nodePool.create({
      data: {
        name: `CPU${args.data.cpu}.MEMORY${args.data.memory}`,
        minNodes: 1
      },
      select: args.select
    }) as unknown as Promise<PrismaNodePool>;
  }

  public findMany(args: FindManyArgs) {
    logger.debug(`Node pool service find many: ${JSON.stringify(args)}`);

    return prisma.nodePool.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(args: FindUniqueArgs) {
    logger.debug(`Node pool service find unique: ${JSON.stringify(args)}`);

    return prisma.nodePool.findUnique(args);
  }

  public findUniqueOrThrow(args: FindUniqueOrThrowArgs) {
    logger.debug(
      `Node pool service find unique or throw: ${JSON.stringify(args)}`
    );

    return prisma.nodePool.findUniqueOrThrow(args);
  }

  public async update(args: UpdateArgs) {
    logger.info(`Node pool service update: ${JSON.stringify(args)}`);

    // Extract data
    const { data } = args;

    if (data.count) {
      const newCount = data.count;
      const { minNodes } = await this.findUniqueOrThrow({
        where: args.where,
        select: { minNodes: true }
      });
      const maxNodes = await this.maxNodes({ id: args.where.id });

      if (newCount < minNodes || newCount > maxNodes) {
        // FIXME Error
        throw new Error(
          `Count ${newCount} is invalid because exceeds min ${minNodes} or max ${maxNodes} limits`
        );
      }

      const oldCount = await this.count({ id: args.where.id });

      if (newCount < oldCount) {
        // TODO Decrease
      } else if (newCount > oldCount) {
        // TODO Increase
      }
    }

    // Fix data for Prisma
    data.count = undefined;
    // Write data
    // eslint-disable-next-line no-param-reassign
    args.data = data;

    return prisma.nodePool.update(args);
  }

  public async deleteNode(args: DeleteNodeArgs) {
    logger.info(`Node pool service delete node: ${JSON.stringify(args)}`);

    // Check if node pool exists and node exists and assigned
    const count = await prisma.nodePool.count({
      where: {
        id: args.id,
        nodes: { some: { id: args.nodeId, nodePoolAssigned: true } }
      }
    });
    if (count !== 1) {
      // FIXME Error
      throw new Error(
        `Cannot find Node ${args.nodeId} assigned to Node pool ${args.id}`
      );
    }

    // Unassign node
    const node = await this.nodeService.update({
      where: { id: args.nodeId },
      data: { nodePoolAssigned: false }
    });

    // Delete K8s node
    await this.k8sService.deleteNode({ id: args.nodeId });

    return node;
  }

  public async count(args: CountArgs): Promise<number> {
    logger.debug(`Node pool service count: ${JSON.stringify(args)}`);

    const {
      _count: { nodes }
    } = await prisma.nodePool.findUniqueOrThrow({
      where: { id: args.id },
      select: {
        _count: {
          select: {
            nodes: { where: { nodePoolAssigned: true } }
          }
        }
      }
    });

    return nodes;
  }

  public async maxNodes(args: MaxNodesArgs): Promise<number> {
    logger.debug(`Node pool service max nodes: ${JSON.stringify(args)}`);

    const {
      _count: { nodes }
    } = await prisma.nodePool.findUniqueOrThrow({
      where: { id: args.id },
      select: { _count: { select: { nodes: true } } }
    });

    return nodes;
  }
}
