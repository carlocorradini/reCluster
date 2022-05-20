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

import {
  Arg,
  FieldResolver,
  Resolver,
  ResolverInterface,
  Root
} from 'type-graphql';
import { GraphQLNonNegativeInt } from 'graphql-scalars';
import configMeasurements, { digital } from 'convert-units';
import { DigitalByteUnit } from '@recluster/graphql';
import { Cpu } from '../entities';

const convert = configMeasurements({ digital });

function cacheConverter(value: number, toUnit?: DigitalByteUnit) {
  return Math.round(
    convert(value)
      .from(DigitalByteUnit.B)
      .to(toUnit ?? DigitalByteUnit.B)
  );
}

@Resolver(Cpu)
export class CpuCacheResolver implements ResolverInterface<Cpu> {
  @FieldResolver(() => GraphQLNonNegativeInt)
  cacheL1d(
    @Root() cpu: Cpu,
    @Arg('unit', () => DigitalByteUnit, {
      defaultValue: DigitalByteUnit.B,
      description: 'Digital conversion unit'
    })
    unit?: DigitalByteUnit
  ) {
    return cacheConverter(cpu.cacheL1d, unit);
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
    return cacheConverter(cpu.cacheL1i, unit);
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
    return cacheConverter(cpu.cacheL2, unit);
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
    return cacheConverter(cpu.cacheL3, unit);
  }
}
