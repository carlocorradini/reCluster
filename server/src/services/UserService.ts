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

import type * as Prisma from '@prisma/client';
import { prisma } from '~/db';
import { logger } from '~/logger';
import type {
  CreateUserArgs,
  FindManyUserArgs,
  FindUniqueUserArgs
} from '~/graphql';

export class UserService {
  public async findMany(args: FindManyUserArgs): Promise<Prisma.User[]> {
    logger.debug(`User service find many: ${JSON.stringify(args)}`);

    return prisma.user.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public async findUnique(
    args: FindUniqueUserArgs
  ): Promise<Prisma.User | null> {
    logger.debug(`User service find unique: ${JSON.stringify(args)}`);

    return prisma.user.findUnique({ where: { id: args.id } });
  }

  public async create(args: CreateUserArgs): Promise<Prisma.User> {
    logger.info(`User service create: ${JSON.stringify(args)}`);

    return prisma.user.create({ ...args });
  }
}
