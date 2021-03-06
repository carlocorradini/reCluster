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
import { GraphQLNonNegativeInt } from 'graphql-scalars';
import { CpuService } from '~/services';
import { byteConverter } from '~/utils';
import { DigitalByteUnit } from '../../enums';
import { Cpu } from '../../entities';
import { FindUniqueCpuArgs, FindManyCpuArgs } from '../../args';

@Resolver(Cpu)
@Service()
export class CpuResolver {
  @Inject()
  private readonly cpuService!: CpuService;

  @Query(() => [Cpu], { description: 'List of Cpus' })
  async cpus(@Args() args: FindManyCpuArgs) {
    return this.cpuService.findMany(args);
  }

  @Query(() => Cpu, {
    nullable: true,
    description: 'Cpu matching the identifier'
  })
  async cpu(@Args() args: FindUniqueCpuArgs) {
    return this.cpuService.findUnique({ ...args, where: { id: args.id } });
  }

  @FieldResolver(() => GraphQLNonNegativeInt)
  cacheL1d(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    return byteConverter({ value: cpu.cacheL1d, to: unit });
  }

  @FieldResolver(() => GraphQLNonNegativeInt)
  cacheL1i(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    return byteConverter({ value: cpu.cacheL1i, to: unit });
  }

  @FieldResolver(() => GraphQLNonNegativeInt)
  cacheL2(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    return byteConverter({ value: cpu.cacheL2, to: unit });
  }

  @FieldResolver(() => GraphQLNonNegativeInt)
  cacheL3(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    return byteConverter({ value: cpu.cacheL3, to: unit });
  }
}
