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

import type { Cpu as PrismaCpu, Prisma } from '@prisma/client';
import type { CreateCpuInput } from '~/types';
import { prisma } from '~/db';
import { logger } from '~/logger';

type UpsertArgs = Omit<Prisma.CpuCreateArgs, 'include'> & {
  data: CreateCpuInput;
};

type FindManyArgs = Omit<Prisma.CpuFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.CpuFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<Prisma.CpuFindUniqueOrThrowArgs, 'include'>;

export class CpuService {
  // FIXME Return type
  public async upsert(args: UpsertArgs): Promise<PrismaCpu> {
    logger.info(`Cpu service upsert: ${JSON.stringify(args)}`);

    // eslint-disable-next-line @typescript-eslint/naming-convention
    const vendor_family_model: Prisma.CpuVendorFamilyModelCompoundUniqueInput =
      {
        vendor: args.data.vendor,
        family: args.data.family,
        model: args.data.model
      };

    // Find old vulnerabilities (if any)
    const cpu = await this.findUnique({
      where: { vendor_family_model },
      select: { vulnerabilities: true }
    });

    // Vulnerabilities array (updated if any)
    const vulnerabilities = [
      ...new Set([
        ...(cpu?.vulnerabilities ?? []),
        ...(args.data.vulnerabilities ?? [])
      ])
    ];

    // Create or update cpu
    return prisma.cpu.upsert({
      where: { vendor_family_model },
      create: args.data,
      update: { vulnerabilities },
      select: args.select
    }) as unknown as Promise<PrismaCpu>; // FIXME Forced correct return type
  }

  public findMany(args: FindManyArgs) {
    logger.debug(`Cpu service find many: ${JSON.stringify(args)}`);

    return prisma.cpu.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(args: FindUniqueArgs) {
    logger.debug(`Cpu service find unique: ${JSON.stringify(args)}`);

    return prisma.cpu.findUnique(args);
  }

  public findUniqueOrThrow(args: FindUniqueOrThrowArgs) {
    logger.debug(`Cpu service find unique or throw: ${JSON.stringify(args)}`);

    return prisma.cpu.findUniqueOrThrow(args);
  }
}
