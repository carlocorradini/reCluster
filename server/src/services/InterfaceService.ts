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

import { Prisma } from '@prisma/client';
import { prisma } from '~/db';
import { logger } from '~/logger';

type FindManyArgs = Omit<Prisma.InterfaceFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.InterfaceFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<
  Prisma.InterfaceFindUniqueOrThrowArgs,
  'include'
>;

export class InterfaceService {
  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Interface service find many: ${JSON.stringify(args)}`);

    return prismaTxn.interface.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Interface service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.interface.findUnique(args);
  }

  public findUniqueOrThrow(
    args: FindUniqueOrThrowArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(
      `Interface service find unique or throw: ${JSON.stringify(args)}`
    );

    return prismaTxn.interface.findUniqueOrThrow(args);
  }
}
