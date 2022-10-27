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

import { Prisma, NodeRoles, NodeStatuses } from '@prisma/client';
import { convert } from 'convert';
import { Intel_I7_6700HQ } from './cpus';

export const master: Prisma.NodeCreateInput = {
  id: 'd4fb717f-e85f-4e16-bb9b-8c777610316b',
  roles: [NodeRoles.K8S_MASTER, NodeRoles.RECLUSTER_MASTER],
  ram: BigInt(convert(8, 'GiB').to('B')),
  minPowerConsumption: 2000,
  maxPowerConsumption: 16000,
  status: {
    create: {
      status: NodeStatuses.ACTIVE,
      reason: 'NodeRegistered',
      message: 'Node registered',
      lastHeartbeat: new Date(),
      lastTransition: new Date()
    }
  },
  cpu: { connect: { id: Intel_I7_6700HQ.id } },
  disks: {
    createMany: { data: [{ name: 'sda', size: convert(250, 'GB').to('B') }] }
  },
  interfaces: {
    createMany: {
      data: [
        {
          name: 'eth0',
          address: '46:6C:A8:E6:0C:D3',
          speed: convert(1, 'Gb').to('b')
        }
      ]
    }
  }
};

export const worker: Prisma.NodeCreateInput = {
  id: 'cfc352b1-ed06-4f85-83f4-3f2382b6cb54',
  roles: [NodeRoles.K8S_WORKER],
  ram: BigInt(convert(8, 'GiB').to('B')),
  minPowerConsumption: 2000,
  maxPowerConsumption: 16000,
  status: {
    create: {
      status: NodeStatuses.ACTIVE,
      reason: 'NodeRegistered',
      message: 'Node registered',
      lastHeartbeat: new Date(),
      lastTransition: new Date()
    }
  },
  cpu: { connect: { id: Intel_I7_6700HQ.id } },
  disks: {
    createMany: { data: [{ name: 'sda', size: convert(250, 'GB').to('B') }] }
  },
  interfaces: {
    createMany: {
      data: [
        {
          name: 'eth0',
          address: '01:28:1B:3C:9F:F5',
          speed: convert(1, 'Gb').to('b')
        }
      ]
    }
  }
};

export const nodes = [master, worker];
