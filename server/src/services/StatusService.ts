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

import type { Prisma } from '@prisma/client';
import type { UpdateStatusInput, WithRequired } from '~/types';
import { prisma, NodeStatusEnum } from '~/db';
import { logger } from '~/logger';

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

export class StatusService {
  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Status service find many: ${JSON.stringify(args)}`);

    return prismaTxn.status.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Status service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.status.findUnique(args);
  }

  public findUniqueOrThrow(
    args: FindUniqueOrThrowArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(
      `Status service find unique or throw: ${JSON.stringify(args)}`
    );

    return prismaTxn.status.findUniqueOrThrow(args);
  }

  public update(args: UpdateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Status service update: ${JSON.stringify(args)}`);

      // Extract data
      const { data } = args;

      // Update data
      data.reason = data.reason ?? null;
      data.message = data.message ?? null;
      data.lastHeartbeat = data.lastHeartbeat ?? null;
      if (!data.lastTransition) {
        const { status: lastStatus } = await this.findUniqueOrThrow(
          {
            where: args.where,
            select: { status: true }
          },
          prisma
        );

        if (data.status !== lastStatus) {
          data.lastTransition = new Date();
        }
      }

      // Logic by status
      switch (data.status) {
        case NodeStatusEnum.ACTIVE:
        case NodeStatusEnum.ACTIVE_READY:
        case NodeStatusEnum.ACTIVE_NOT_READY:
        case NodeStatusEnum.ACTIVE_DELETING:
        case NodeStatusEnum.BOOTING:
        case NodeStatusEnum.INACTIVE:
          // Update last heartbeat
          data.lastHeartbeat = data.lastHeartbeat ?? new Date();
          break;
        default:
          break;
      }

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.status.update(args);
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }
}
