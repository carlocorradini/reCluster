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
  CreateCpuInput,
  FindManyCpuArgs,
  FindUniqueCpuArgs
} from '~/graphql';

export class CpuService {
  public async create(args: CreateCpuInput): Promise<Prisma.Cpu> {
    logger.debug(`Cpu service create: ${JSON.stringify(args)}`);

    // eslint-disable-next-line @typescript-eslint/naming-convention
    const vendor_family_model = {
      vendor: args.vendor,
      family: args.family,
      model: args.model
    };

    // Find old vulnerabilities (if any)
    const cpu = await prisma.cpu.findUnique({
      where: { vendor_family_model },
      select: { vulnerabilities: true }
    });

    // Vulnerabilities array (updated if any)
    const vulnerabilities = [
      ...new Set([...(cpu?.vulnerabilities ?? []), ...args.vulnerabilities])
    ];

    // Create or update cpu
    return prisma.cpu.upsert({
      where: { vendor_family_model },
      update: { vulnerabilities },
      create: args
    });
  }

  public async findMany(args: FindManyCpuArgs): Promise<Prisma.Cpu[]> {
    logger.debug(`Cpu service find many: ${JSON.stringify(args)}`);

    return prisma.cpu.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public async findUnique(args: FindUniqueCpuArgs): Promise<Prisma.Cpu | null> {
    logger.debug(`Cpu service find unique: ${JSON.stringify(args)}`);

    return prisma.cpu.findUnique({ where: { id: args.id } });
  }
}
