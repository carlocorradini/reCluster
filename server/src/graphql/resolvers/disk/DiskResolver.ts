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

import { Arg, Args, FieldResolver, Query, Resolver, Root } from 'type-graphql';
import { GraphQLBigInt } from 'graphql-scalars';
import { PrismaClient } from '@prisma/client';
import configMeasurements, { digital } from 'convert-units';
import { Disk } from '../../entities';
import { Prisma } from '../../decorators';
import { FindUniqueDiskArgs, FindManyDisksArgs } from '../../args';
import { DigitalByteUnit } from '../../enums';

const convert = configMeasurements({ digital });

@Resolver(Disk)
export class DiskResolver {
  @Query(() => [Disk], { description: 'List of Disks' })
  async disks(@Prisma() prisma: PrismaClient, @Args() args: FindManyDisksArgs) {
    return prisma.disk.findMany({
      where: args.where,
      orderBy: args.orderBy,
      cursor: args.cursor ? { id: args.cursor } : undefined,
      take: args.take,
      skip: args.skip
    });
  }

  @Query(() => Disk, {
    nullable: true,
    description: 'Disk matching the identifier'
  })
  async disk(@Prisma() prisma: PrismaClient, @Args() args: FindUniqueDiskArgs) {
    return prisma.disk.findUnique({ where: { id: args.id } });
  }

  @FieldResolver(() => GraphQLBigInt)
  size(
    @Root() disk: Disk,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    // FIXME BigInt conversion
    return Math.round(
      convert(Number(disk.size))
        .from(DigitalByteUnit.B)
        .to(unit ?? DigitalByteUnit.B)
    );
  }
}
