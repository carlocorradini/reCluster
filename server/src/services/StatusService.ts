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

import type { Prisma } from '@prisma/client';
import { inject, injectable } from 'tsyringe';
import type { UpdateStatusInput, WithRequired } from '~/types';
import { prisma, NodeStatusEnum } from '~/db';
import { logger } from '~/logger';
// eslint-disable-next-line import/no-cycle
import { NodeService } from './NodeService';

type FindManyArgs = Omit<Prisma.StatusFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.StatusFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<
  Prisma.StatusFindUniqueOrThrowArgs,
  'include'
>;

type UpdateArgs = Omit<
  Prisma.StatusUpdateArgs,
  'include' | 'where' | 'data'
> & {
  where: WithRequired<Prisma.StatusWhereUniqueInput, 'id'>;
  data: UpdateStatusInput;
};

@injectable()
export class StatusService {
  public constructor(
    @inject(NodeService)
    private readonly nodeService: NodeService
  ) {}

  public findMany(args: FindManyArgs) {
    logger.debug(`Status service find many: ${JSON.stringify(args)}`);

    return prisma.status.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(args: FindUniqueArgs) {
    logger.debug(`Status service find unique: ${JSON.stringify(args)}`);

    return prisma.status.findUnique(args);
  }

  public findUniqueOrThrow(args: FindUniqueOrThrowArgs) {
    logger.debug(
      `Status service find unique or throw: ${JSON.stringify(args)}`
    );

    return prisma.status.findUniqueOrThrow(args);
  }

  public async update(args: UpdateArgs) {
    logger.info(`Status service update: ${JSON.stringify(args)}`);

    // Extract data
    const { data } = args;

    // Update data
    data.reason = data.reason ?? null;
    data.message = data.message ?? null;
    data.lastHeartbeat = data.lastHeartbeat ?? null;
    if (!data.lastTransition) {
      const { status: lastStatus } = await prisma.status.findUniqueOrThrow({
        where: args.where,
        select: { status: true }
      });

      if (data.status !== lastStatus) {
        data.lastTransition = new Date();
      }
    }

    // Logic by status
    switch (data.status) {
      case NodeStatusEnum.ACTIVE:
      case NodeStatusEnum.BOOTING:
        // Update last heartbeat
        data.lastHeartbeat = new Date();
        // Node assigned to node pool
        await this.nodeService.update({
          where: { id: args.where.id },
          data: { nodePoolAssigned: true }
        });
        break;
      default:
        break;
    }

    // Write data
    // eslint-disable-next-line no-param-reassign
    args.data = data;

    return prisma.status.update(args);
  }
}
