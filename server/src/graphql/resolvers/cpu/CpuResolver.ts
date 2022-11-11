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

import { GraphQLInt } from 'graphql';
import {
  Arg,
  Args,
  FieldResolver,
  Query,
  Resolver,
  ResolverInterface,
  Root
} from 'type-graphql';
import { injectable, inject } from 'tsyringe';
import { convert } from 'convert';
import { CpuService } from '~/services';
import { DigitalUnitEnum } from '../../enums';
import { Cpu } from '../../entities';
import { FindUniqueCpuArgs, FindManyCpuArgs } from '../../args';

@Resolver(Cpu)
@injectable()
export class CpuResolver implements ResolverInterface<Cpu> {
  public constructor(
    @inject(CpuService) private readonly cpuService: CpuService
  ) {}

  @Query(() => [Cpu], { description: 'List of Cpus' })
  public cpus(@Args() args: FindManyCpuArgs) {
    return this.cpuService.findMany(args);
  }

  @Query(() => Cpu, {
    nullable: true,
    description: 'Cpu matching the identifier'
  })
  public cpu(@Args() args: FindUniqueCpuArgs) {
    return this.cpuService.findUnique({ where: { id: args.id } });
  }

  @FieldResolver(() => GraphQLInt)
  public cacheL1d(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(cpu.cacheL1d, DigitalUnitEnum.B).to(unit);
  }

  @FieldResolver(() => GraphQLInt)
  public cacheL1i(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(cpu.cacheL1i, DigitalUnitEnum.B).to(unit);
  }

  @FieldResolver(() => GraphQLInt)
  public cacheL2(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(cpu.cacheL2, DigitalUnitEnum.B).to(unit);
  }

  @FieldResolver(() => GraphQLInt)
  public cacheL3(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(cpu.cacheL3, DigitalUnitEnum.B).to(unit);
  }
}
