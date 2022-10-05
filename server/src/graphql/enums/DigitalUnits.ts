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

import { registerEnumType } from 'type-graphql';

export enum DigitalUnits {
  b = 'b',
  Kb = 'Kb',
  Kib = 'Kib',
  Mb = 'Mb',
  Mib = 'Mib',
  Gb = 'Gb',
  Gib = 'Gib',
  Tb = 'Tb',
  Tib = 'Tib',
  Pb = 'Pb',
  Pib = 'Pib',
  B = 'B',
  KB = 'KB',
  KiB = 'KiB',
  MB = 'MB',
  MiB = 'MiB',
  GB = 'GB',
  GiB = 'GiB',
  TB = 'TB',
  TiB = 'TiB',
  PB = 'PB',
  PiB = 'PiB'
}

registerEnumType(DigitalUnits, {
  name: 'DigitalUnits',
  description: 'Digital units',
  valuesConfig: {
    b: { description: 'Bit' },
    Kb: { description: 'Kilobit' },
    Kib: { description: 'Kibibit' },
    Mb: { description: 'Megabit' },
    Mib: { description: 'Mebibit' },
    Gb: { description: 'Gigabit' },
    Gib: { description: 'Gibibit' },
    Tb: { description: 'Terabit' },
    Tib: { description: 'Tebibit' },
    Pb: { description: 'Petabit' },
    Pib: { description: 'Pebibit' },
    B: { description: 'Byte' },
    KB: { description: 'Kilobyte' },
    KiB: { description: 'Kibibyte' },
    MB: { description: 'Megabyte' },
    MiB: { description: 'Mebibyte' },
    GB: { description: 'Gigabyte' },
    GiB: { description: 'Gibibyte' },
    TB: { description: 'Terabyte' },
    TiB: { description: 'Tebibyte' },
    PB: { description: 'Petabyte' },
    PiB: { description: 'Pebibyte' }
  }
});
