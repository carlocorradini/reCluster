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

import convert from 'convert';
import { DigitalUnit } from '~/graphql/enums';

type Converter<V, F, T = F> = {
  value: V;
  from: F;
  to: T;
};

export function digitalConverter(
  args: Converter<number | bigint, DigitalUnit>
): number | bigint {
  // FIXME Remove Kb and KB conversion
  const from = // eslint-disable-next-line no-nested-ternary
    args.from === DigitalUnit.Kb
      ? 'kb'
      : args.from === DigitalUnit.KB
      ? 'kB'
      : args.from;
  const to = // eslint-disable-next-line no-nested-ternary
    args.to === DigitalUnit.Kb
      ? 'kb'
      : args.to === DigitalUnit.KB
      ? 'kB'
      : args.to;

  // FIXME BigInt conversion
  return convert(args.value, from).to(to);
}
