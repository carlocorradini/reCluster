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
import { Service, Inject } from 'typedi';
import { GraphQLBigInt } from 'graphql-scalars';
import { DiskService } from '~/services';
import { byteConverter } from '~/utils';
import { DigitalByteUnit } from '../../enums';
import { Disk } from '../../entities';
import { FindUniqueDiskArgs, FindManyDiskArgs } from '../../args';

@Resolver(Disk)
@Service()
export class DiskResolver {
  @Inject()
  private readonly diskService!: DiskService;

  @Query(() => [Disk], { description: 'List of Disks' })
  async disks(@Args() args: FindManyDiskArgs) {
    return this.diskService.findMany(args);
  }

  @Query(() => Disk, {
    nullable: true,
    description: 'Disk matching the identifier'
  })
  async disk(@Args() args: FindUniqueDiskArgs) {
    return this.diskService.findUnique({ ...args, where: { id: args.id } });
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
    return byteConverter({ value: disk.size, to: unit });
  }
}
