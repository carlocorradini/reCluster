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

/* eslint-disable @typescript-eslint/naming-convention */

import { Prisma, CpuArchitectureEnum, CpuVendorEnum } from '@prisma/client';

export const Intel_I7_6700HQ: Prisma.CpuCreateInput = {
  id: 'ab93a663-7e31-479a-8711-78bbc636a841',
  vendor: CpuVendorEnum.INTEL,
  name: 'Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz',
  architecture: CpuArchitectureEnum.AMD64,
  family: 1,
  model: 94,
  cores: 8,
  cacheL1d: 131072,
  cacheL1i: 131072,
  cacheL2: 1048576,
  cacheL3: 6291456,
  singleThreadScore: 1000,
  multiThreadScore: 8000,
  vulnerabilities: [
    'L1tf',
    'Mds',
    'Meltdown',
    'Spec store bypass',
    'Spectre v1',
    'Spectre v2',
    'Tsx async abort'
  ],
  flags: [
    'fpu',
    'vme',
    'de',
    'pse',
    'tsc',
    'msr',
    'pae',
    'mce',
    'cx8',
    'sep',
    'pge',
    'mca',
    'pat',
    'pse36',
    'mmx',
    'sse',
    'sse2',
    'ss',
    'ht',
    'syscall',
    'nx',
    'lm',
    'constant_tsc',
    'rep_good',
    'pni',
    'fma',
    'cx16',
    'sse4_1',
    'sse4_2',
    'aes',
    'avx',
    'f16c',
    'hypervisor',
    'abm',
    'pti',
    'bmi1',
    'hle',
    'avx2',
    'bmi2',
    'rtm',
    'adx',
    'flush_l1d',
    'arch_capabilities'
  ]
};

export const cpus = [Intel_I7_6700HQ];
