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
  public upsert(
    args: UpsertArgs,
    prismaTxn?: Prisma.TransactionClient
  ): Promise<PrismaCpu> {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Cpu service upsert: ${JSON.stringify(args)}`);

      // eslint-disable-next-line @typescript-eslint/naming-convention
      const vendor_family_model: Prisma.CpuVendorFamilyModelCompoundUniqueInput =
        {
          vendor: args.data.vendor,
          family: args.data.family,
          model: args.data.model
        };

      // Find old vulnerabilities (if any)
      const cpu = await this.findUnique(
        {
          where: { vendor_family_model },
          select: {
            vulnerabilities: true,
            singleThreadScore: true,
            multiThreadScore: true,
            efficiencyThreshold: true,
            performanceThreshold: true
          }
        },
        prisma
      );

      // Update if cpu exists
      if (cpu) {
        cpu.vulnerabilities = [
          ...new Set([
            ...cpu.vulnerabilities,
            ...(args.data.vulnerabilities ?? [])
          ])
        ];
        cpu.singleThreadScore = Math.round(
          (cpu.singleThreadScore + args.data.singleThreadScore) / 2
        );
        cpu.multiThreadScore = Math.round(
          (cpu.multiThreadScore + args.data.multiThreadScore) / 2
        );
        if (cpu.efficiencyThreshold || args.data.efficiencyThreshold) {
          cpu.efficiencyThreshold = Math.round(
            ((cpu.efficiencyThreshold ?? 0) +
              (args.data.efficiencyThreshold ?? 0)) /
              (cpu.efficiencyThreshold && args.data.efficiencyThreshold ? 2 : 1)
          );
        }
        if (cpu.performanceThreshold || args.data.performanceThreshold) {
          cpu.performanceThreshold = Math.round(
            ((cpu.performanceThreshold ?? 0) +
              (args.data.performanceThreshold ?? 0)) /
              (cpu.performanceThreshold && args.data.performanceThreshold
                ? 2
                : 1)
          );
        }
      }

      // Create or update cpu
      return prisma.cpu.upsert({
        where: { vendor_family_model },
        create: args.data,
        update: { ...cpu },
        select: args.select
      }) as unknown as Promise<PrismaCpu>; // FIXME Forced correct return type
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Cpu service find many: ${JSON.stringify(args)}`);

    return prismaTxn.cpu.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Cpu service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.cpu.findUnique(args);
  }

  public findUniqueOrThrow(
    args: FindUniqueOrThrowArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Cpu service find unique or throw: ${JSON.stringify(args)}`);

    return prismaTxn.cpu.findUniqueOrThrow(args);
  }
}
