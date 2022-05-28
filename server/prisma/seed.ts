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
  PrismaClient,
  Prisma,
  CpuArchitecture,
  CpuVendor,
  NodeStatus
} from '@prisma/client';
import pino from 'pino';

const logger = pino({ level: 'debug', name: 'prisma-seed' });
const prisma = new PrismaClient();

const nodes: Prisma.NodeCreateInput[] = [
  {
    ram: 17_179_869_184,
    status: NodeStatus.ACTIVE,
    cpu: {
      connectOrCreate: {
        create: {
          architecture: CpuArchitecture.x86_64,
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
            'apic',
            'sep',
            'mtrr',
            'pge',
            'mca',
            'cmov',
            'pat',
            'pse36',
            'clflush',
            'mmx',
            'fxsr',
            'sse',
            'sse2',
            'ss',
            'ht',
            'syscall',
            'nx',
            'pdpe1gb',
            'rdtscp',
            'lm',
            'constant_tsc',
            'rep_good',
            'nopl',
            'xtopology',
            'cpuid',
            'pni',
            'pclmulqdq',
            'ssse3',
            'fma',
            'cx16',
            'pcid',
            'sse4_1',
            'sse4_2',
            'movbe',
            'popcnt',
            'aes',
            'xsave',
            'avx',
            'f16c',
            'rdrand',
            'hypervisor',
            'lahf_lm',
            'abm',
            '3dnowprefetch',
            'invpcid_single',
            'pti',
            'ssbd',
            'ibrs',
            'ibpb',
            'stibp',
            'fsgsbase',
            'bmi1',
            'hle',
            'avx2',
            'smep',
            'bmi2',
            'erms',
            'invpcid',
            'rtm',
            'rdseed',
            'adx',
            'smap',
            'clflushopt',
            'xsaveopt',
            'xsavec',
            'xgetbv1',
            'xsaves',
            'flush_l1d',
            'arch_capabilities'
          ],
          cores: 8,
          vendor: CpuVendor.INTEL,
          family: 6,
          model: 94,
          name: 'Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz',
          vulnerabilities: [
            'Itlb multihit',
            'L1tf',
            'Mds',
            'Meltdown',
            'Spec store bypass',
            'Spectre v1',
            'Spectre v2',
            'Srbds',
            'Tsx async abort'
          ],
          cacheL1d: 131_072,
          cacheL1i: 131_072,
          cacheL2: 1_048_576,
          cacheL3: 6_291_456
        },
        where: {
          vendor_family_model: { vendor: CpuVendor.INTEL, family: 6, model: 94 }
        }
      }
    },
    disks: {
      createMany: {
        data: [
          { name: 'sda', size: 1_099_511_627_776 },
          { name: 'sdb', size: 268_435_456 }
        ],
        skipDuplicates: true
      }
    },
    interfaces: {
      createMany: {
        data: [
          {
            name: 'eth0',
            address: '00:15:5d:a1:b7:47',
            speed: 10000000000,
            wol: []
          }
        ],
        skipDuplicates: true
      }
    }
  }
];

async function main() {
  logger.debug('Connecting database');
  await prisma.$connect();

  logger.info('Start seeding ...');

  // eslint-disable-next-line no-restricted-syntax
  for (const n of nodes) {
    // eslint-disable-next-line no-await-in-loop
    const node = await prisma.node.create({ data: n });
    logger.info(`Created node '${node.id}'`);
  }

  logger.info('Seeding finished');
}

main()
  .catch((error) => {
    logger.error(error);
    throw error;
  })
  .finally(async () => {
    logger.debug('Disconnecting database');
    await prisma.$disconnect();
  });
