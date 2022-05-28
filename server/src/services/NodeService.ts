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
import { Service } from 'typedi';
import { NodeStatus } from '~/graphql/entities';
import { prisma } from '~/db';
import { logger } from '~/logger';

@Service()
export class NodeService {
  public async findMany(
    args: Omit<Prisma.NodeFindManyArgs, 'cursor'> & { cursor?: string }
  ) {
    logger.debug(`Node service find many: ${JSON.stringify(args)}`);

    return prisma.node.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public async findUnique(
    args: Omit<Prisma.NodeFindUniqueArgs, 'where'> & { where: { id: string } }
  ) {
    logger.debug(`Node service find unique: ${JSON.stringify(args)}`);

    return prisma.node.findUnique(args);
  }

  public async create(
    args: Omit<Prisma.NodeCreateArgs, 'data'> & {
      data: Omit<
        Prisma.NodeCreateInput,
        'cpu' | 'status' | 'disks' | 'interfaces'
      > & {
        cpu: Omit<Prisma.CpuCreateWithoutNodesInput, 'vulnerabilities'> & {
          vulnerabilities: Prisma.Enumerable<string>;
        };
        disks: Prisma.DiskCreateWithoutNodeInput[];
        interfaces: Prisma.InterfaceCreateWithoutNodeInput[];
      };
    }
  ) {
    logger.info(`Node service create: ${JSON.stringify(args)}`);

    // eslint-disable-next-line @typescript-eslint/naming-convention
    const vendor_family_model = {
      vendor: args.data.cpu.vendor,
      family: args.data.cpu.family,
      model: args.data.cpu.model
    };

    // Find old vulnerabilities (if any)
    // FIXME Should be done in upsert
    const cpu = await prisma.cpu.findUnique({
      where: { vendor_family_model },
      select: { vulnerabilities: true }
    });
    const vulnerabilities = Array.from(
      new Set([
        ...(cpu?.vulnerabilities ?? []),
        ...args.data.cpu.vulnerabilities
      ])
    );

    // Add or update cpu
    await prisma.cpu.upsert({
      where: { vendor_family_model },
      update: { vulnerabilities },
      create: args.data.cpu
    });

    // Create
    return prisma.node.create({
      ...args,
      data: {
        ...args.data,
        status: NodeStatus.ACTIVE,
        cpu: { connect: { vendor_family_model } },
        disks: { createMany: { data: args.data.disks, skipDuplicates: true } },
        interfaces: {
          createMany: { data: args.data.interfaces, skipDuplicates: true }
        }
      }
    });
  }
}
