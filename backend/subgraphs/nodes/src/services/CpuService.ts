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

import { Service } from 'typedi';
import { AddCpuInput } from '~/graphql/inputs';
import { CpusArgs } from '~/graphql/args';
import { prisma } from '~/database';

@Service()
export class CpuService {
  private readonly prisma = prisma;

  public async cpus(options: CpusArgs) {
    return this.prisma.cpu.findMany({
      skip: options.cursor ? options.skip + 1 : options.skip,
      take: options.take,
      ...(options.cursor && { cursor: { id: options.cursor } }),
      where: {
        ...(options.architecture && { architecture: options.architecture }),
        ...(options.flags && { flags: { hasEvery: options.flags } })
      },
      orderBy: { id: 'asc' }
    });
  }

  public async cpu(id: string) {
    return this.prisma.cpu.findUnique({ where: { id } });
  }

  public async addCpu(input: AddCpuInput) {
    return this.prisma.cpu.create({
      data: { ...input }
    });
  }
}
