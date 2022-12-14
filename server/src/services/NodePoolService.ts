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
import { delay, inject, injectable } from 'tsyringe';
import { convert } from 'convert';
import type {
  CreateNodeInput,
  UpdateNodePoolInput,
  WithRequired
} from '~/types';
import { NodePoolError } from '~/errors';
import { config } from '~/config';
import { prisma, NodeStatusEnum } from '~/db';
import { logger } from '~/logger';
import { isControllerNode } from '~/helpers';
// eslint-disable-next-line import/no-cycle
import { NodeService } from './NodeService';

type UpsertArgs = {
  data: Pick<CreateNodeInput, 'memory' | 'roles'> & { cpu: number };
  select?: Prisma.NodePoolSelect;
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
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
  data: UpdateNodePoolInput;
};

type IncreaseOrDecreaseArgs = {
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
  data: {
    count: number;
  };
};

type IncreaseArgs = {
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
  data: {
    count: number;
  };
};

type DecreaseArgs = {
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
  data: {
    count: number;
  };
};

type CountArgs = {
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
};

type MaxNodesArgs = {
  where: WithRequired<Pick<Prisma.NodePoolWhereUniqueInput, 'id'>, 'id'>;
};

@injectable()
export class NodePoolService {
  public constructor(
    @inject(delay(() => NodeService)) private readonly nodeService: NodeService
  ) {}

  // FIXME Return type
  public upsert(
    args: UpsertArgs,
    prismaTxn?: Prisma.TransactionClient
  ): Promise<PrismaNodePool> {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node pool service upsert: ${JSON.stringify(args)}`);

      const isController = isControllerNode(args.data.roles);
      // FIXME BigInt/Number conversion
      const name = isController
        ? config.nodePool.controller.name
        : `cpu${args.data.cpu}.memory${
            Math.round(convert(Number(args.data.memory), 'B').to('GiB') * 2) / 2
          }`;

      return prisma.nodePool.upsert({
        select: args.select,
        where: { name },
        update: { ...(isController && { minNodes: { increment: 1 } }) },
        create: {
          name,
          minNodes: isController ? 1 : config.nodePool.worker.minNodes,
          ...(isController && { autoScale: false })
        }
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
        await this.increaseOrDecrease({
          where: args.where,
          data: { count: data.count }
        });

        delete data.count;
      }

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.nodePool.update(args);
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  private increaseOrDecrease(
    args: IncreaseOrDecreaseArgs,
    prismaTxn?: Prisma.TransactionClient
  ) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(
        `Node pool service increase or decrease: ${JSON.stringify(args)}`
      );

      const newCount = args.data.count;
      const { minNodes } = await this.findUniqueOrThrow(
        {
          where: args.where,
          select: { minNodes: true }
        },
        prisma
      );
      const maxNodes = await this.maxNodes({ where: args.where }, prisma);

      if (newCount < minNodes || newCount > maxNodes)
        throw new NodePoolError(
          `Node pool '${args.where.id}' count ${newCount} is invalid because exceeds min ${minNodes} or max ${maxNodes}`
        );

      const oldCount = await this.count(
        { where: { id: args.where.id } },
        prisma
      );

      if (newCount > oldCount) {
        await this.increase(
          {
            where: args.where,
            data: { count: newCount - oldCount }
          },
          prisma
        );
      } else if (newCount < oldCount) {
        await this.decrease(
          {
            where: args.where,
            data: { count: oldCount - newCount }
          },
          prisma
        );
      } else {
        logger.warn(
          `Increase/Decrease new count '${newCount}' is equal to old count '${oldCount}'`
        );
      }
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  private increase(args: IncreaseArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node pool service increase: ${JSON.stringify(args)}`);

      const nodes = await this.nodeService.findMany(
        {
          where: {
            nodePoolId: args.where.id,
            nodePoolAssigned: false,
            status: { status: NodeStatusEnum.INACTIVE },
            interfaces: { some: { wol: { isEmpty: false } } }
          },
          select: { id: true },
          take: args.data.count,
          orderBy: [
            { maxPowerConsumption: 'asc' },
            { minPowerConsumption: 'asc' },
            { cpu: { multiThreadScore: 'desc' } },
            { cpu: { singleThreadScore: 'desc' } }
          ]
        },
        prisma
      );

      if (nodes.length !== args.data.count)
        throw new NodePoolError(
          `Node pool '${args.where.id}' increase request ${args.data.count} but received ${nodes.length}`
        );

      await Promise.all(
        nodes.map((node) =>
          this.nodeService.boot({ where: { id: node.id } }, prisma)
        )
      );
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  private decrease(args: DecreaseArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node pool service decrease: ${JSON.stringify(args)}`);

      const nodes = await this.nodeService.findMany(
        {
          where: {
            nodePoolId: args.where.id,
            nodePoolAssigned: true,
            status: {
              status: {
                in: [
                  NodeStatusEnum.ACTIVE_READY,
                  NodeStatusEnum.ACTIVE_NOT_READY
                ]
              }
            }
          },
          select: { id: true },
          take: args.data.count,
          orderBy: [
            { maxPowerConsumption: 'desc' },
            { minPowerConsumption: 'desc' },
            { cpu: { multiThreadScore: 'asc' } },
            { cpu: { singleThreadScore: 'asc' } }
          ]
        },
        prisma
      );

      if (nodes.length !== args.data.count)
        throw new NodePoolError(
          `Node pool '${args.where.id}' decrease request ${args.data.count} but received ${nodes.length}`
        );

      await Promise.all(
        nodes.map((node) =>
          this.nodeService.shutdown({ where: { id: node.id } }, prisma)
        )
      );
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
      where: { id: args.where.id },
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
      where: { id: args.where.id },
      select: { _count: { select: { nodes: true } } }
    });

    return nodes;
  }
}
