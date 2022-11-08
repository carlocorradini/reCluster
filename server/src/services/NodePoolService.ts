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
import type { UpdateNodePoolInput, WithRequired } from '~/types';
import { prisma } from '~/db';
import { logger } from '~/logger';

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

type CountArgs = {
  id: string;
};

type MaxNodesArgs = {
  id: string;
};

export class NodePoolService {
  // FIXME Return type
  public upsert(
    args: UpsertArgs,
    prismaTxn?: Prisma.TransactionClient
  ): Promise<PrismaNodePool> {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
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
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Node pool service find many: ${JSON.stringify(args)}`);

    return prismaTxn.nodePool.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Node pool service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.nodePool.findUnique(args);
  }

  public findUniqueOrThrow(
    args: FindUniqueOrThrowArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(
      `Node pool service find unique or throw: ${JSON.stringify(args)}`
    );

    return prismaTxn.nodePool.findUniqueOrThrow(args);
  }

  public update(args: UpdateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node pool service update: ${JSON.stringify(args)}`);

      // Extract data
      const { data } = args;

      if (data.count) {
        const newCount = data.count;
        const { minNodes } = await this.findUniqueOrThrow(
          {
            where: args.where,
            select: { minNodes: true }
          },
          prisma
        );
        const maxNodes = await this.maxNodes({ id: args.where.id }, prisma);

        if (newCount < minNodes || newCount > maxNodes) {
          // FIXME Error
          throw new Error(
            `Count ${newCount} is invalid because exceeds min ${minNodes} or max ${maxNodes} limits`
          );
        }

        const oldCount = await this.count({ id: args.where.id }, prisma);

        if (newCount < oldCount) {
          // TODO Decrease
        } else if (newCount > oldCount) {
          // TODO Increase
        }

        delete data.count;
      }

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.nodePool.update(args);
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public async count(
    args: CountArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ): Promise<number> {
    logger.debug(`Node pool service count: ${JSON.stringify(args)}`);

    const {
      _count: { nodes }
    } = await prismaTxn.nodePool.findUniqueOrThrow({
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

  public async maxNodes(
    args: MaxNodesArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ): Promise<number> {
    logger.debug(`Node pool service max nodes: ${JSON.stringify(args)}`);

    const {
      _count: { nodes }
    } = await prismaTxn.nodePool.findUniqueOrThrow({
      where: { id: args.id },
      select: { _count: { select: { nodes: true } } }
    });

    return nodes;
  }
}
