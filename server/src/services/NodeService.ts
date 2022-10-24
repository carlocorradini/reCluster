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
import { inject, injectable } from 'tsyringe';
import { prisma } from '~/db';
import { logger } from '~/logger';
import type {
  FindManyNodeArgs,
  FindUniqueNodeArgs,
  CreateNodeArgs,
  UpdateNodeArgs,
  NodeRoles,
  NodePermissions
} from '~/graphql';
import { NodeStatuses } from '~/graphql/enums';
import { TokenService, TokenTypes } from './TokenService';
import { CpuService } from './CpuService';

@injectable()
export class NodeService {
  public constructor(
    @inject(CpuService)
    private readonly cpuService: CpuService,
    @inject(TokenService)
    private readonly tokenService: TokenService
  ) {}

  public async findMany(args: FindManyNodeArgs): Promise<Prisma.Node[]> {
    logger.debug(`Node service find many: ${JSON.stringify(args)}`);

    return prisma.node.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public async findUnique(
    args: FindUniqueNodeArgs
  ): Promise<Prisma.Node | null> {
    logger.debug(`Node service find unique: ${JSON.stringify(args)}`);

    return prisma.node.findUnique({ where: { id: args.id } });
  }

  public async create(args: CreateNodeArgs): Promise<string> {
    logger.info(`Node service create: ${JSON.stringify(args)}`);

    // Create or update cpu
    const { id: cpuId } = await this.cpuService.create(args.data.cpu);

    // Create
    const node = await prisma.node.create({
      ...args,
      select: { id: true, roles: true, permissions: true },
      data: {
        ...args.data,
        cpu: { connect: { id: cpuId } },
        disks: { createMany: { data: args.data.disks, skipDuplicates: true } },
        interfaces: {
          createMany: { data: args.data.interfaces, skipDuplicates: true }
        },
        statuses: { create: { status: NodeStatuses.ACTIVE } }
      }
    });

    // Generate token
    return this.tokenService.sign({
      type: TokenTypes.NODE,
      id: node.id,
      roles: node.roles as NodeRoles[],
      permissions: node.permissions as NodePermissions[]
    });
  }

  public async update(args: UpdateNodeArgs): Promise<Prisma.Node> {
    logger.info(`Node service update: ${JSON.stringify(args)}`);

    return prisma.node.update({ where: { id: args.id }, data: args.data });
  }
}
