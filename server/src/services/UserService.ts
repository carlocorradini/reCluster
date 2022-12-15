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

import type { User as PrismaUser, Prisma } from '@prisma/client';
import { inject, injectable } from 'tsyringe';
import type { CreateUserInput, UpdateUserInput, WithRequired } from '~/types';
import { prisma } from '~/db';
import { logger } from '~/logger';
import { AuthenticationError } from '~/errors';
import { TokenService, TokenTypes } from './TokenService';
import { CryptoService } from './CryptoService';

type CreateArgs = Omit<Prisma.UserCreateArgs, 'include' | 'data'> & {
  data: CreateUserInput;
};

type FindManyArgs = Omit<Prisma.UserFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.UserFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<Prisma.UserFindUniqueOrThrowArgs, 'include'>;

type UpdateArgs = Omit<Prisma.UserUpdateArgs, 'include' | 'where' | 'data'> & {
  where: WithRequired<Pick<Prisma.UserWhereUniqueInput, 'id'>, 'id'>;
  data: UpdateUserInput;
};

type SignInArgs = Required<Pick<PrismaUser, 'username' | 'password'>>;

@injectable()
export class UserService {
  public constructor(
    @inject(TokenService)
    private readonly tokenService: TokenService,
    @inject(CryptoService)
    private readonly cryptoService: CryptoService
  ) {}

  public create(args: CreateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`User service create: ${JSON.stringify(args)}`);

      // Extract data
      const { data } = args;

      // Update data
      data.password = await this.cryptoService.hash(data.password);

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.user.create(args);
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`User service find many: ${JSON.stringify(args)}`);

    return prismaTxn.user.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`User service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.user.findUnique(args);
  }

  public findUniqueOrThrow(
    args: FindUniqueOrThrowArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`User service find unique or throw: ${JSON.stringify(args)}`);

    return prismaTxn.user.findUniqueOrThrow(args);
  }

  public update(args: UpdateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`User service update: ${JSON.stringify(args)}`);

      // Extract data
      const { data } = args;

      // Update data
      if (data.password) {
        data.password = await this.cryptoService.hash(data.password);
      }

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.user.update(args);
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public signIn(args: SignInArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`User service sign in: ${args.username}`);

      const user = await this.findUnique(
        {
          select: { id: true, roles: true, permissions: true, password: true },
          where: { username: args.username }
        },
        prisma
      );

      // Check password
      if (
        !user ||
        !(await this.cryptoService.compare(args.password, user.password))
      ) {
        throw new AuthenticationError('Username or password is incorrect');
      }

      // Generate token
      return this.tokenService.sign({
        type: TokenTypes.USER,
        id: user.id,
        roles: user.roles,
        permissions: user.permissions
      });
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }
}
