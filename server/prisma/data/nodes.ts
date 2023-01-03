/*
 * MIT License
 *
 * Copyright (c) 2022-2023 Carlo Corradini
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

import { Prisma, NodeRoleEnum, NodeStatusEnum } from '@prisma/client';
import { convert } from 'convert';
import { Intel_I7_6700HQ } from './cpus';
import { node_pool_controllers, node_pool_workers } from './nodePools';

// eslint-disable-next-line @typescript-eslint/naming-convention
export const controller_0: Prisma.NodeCreateInput = {
  id: 'd4fb717f-e85f-4e16-bb9b-8c777610316b',
  name: 'controller.d4fb717f-e85f-4e16-bb9b-8c777610316b',
  roles: [NodeRoleEnum.K8S_CONTROLLER, NodeRoleEnum.RECLUSTER_CONTROLLER],
  address: '127.0.0.1',
  memory: BigInt(convert(2, 'GiB').to('B')),
  minPowerConsumption: 2000,
  maxPowerConsumption: 16000,
  status: {
    create: {
      status: NodeStatusEnum.ACTIVE,
      reason: 'NodeRegistered',
      message: 'Node registered',
      lastHeartbeat: new Date(),
      lastTransition: new Date()
    }
  },
  cpu: { connect: { id: Intel_I7_6700HQ.id } },
  storages: {
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
  },
  nodePool: { connect: { id: node_pool_controllers.id } }
};

// eslint-disable-next-line @typescript-eslint/naming-convention
export const worker_0: Prisma.NodeCreateInput = {
  id: 'cfc352b1-ed06-4f85-83f4-3f2382b6cb54',
  name: 'worker.cfc352b1-ed06-4f85-83f4-3f2382b6cb54',
  roles: [NodeRoleEnum.K8S_WORKER],
  address: '127.0.0.2',
  memory: BigInt(convert(2, 'GiB').to('B')),
  minPowerConsumption: 2000,
  maxPowerConsumption: 16000,
  status: {
    create: {
      status: NodeStatusEnum.ACTIVE,
      reason: 'NodeRegistered',
      message: 'Node registered',
      lastHeartbeat: new Date(),
      lastTransition: new Date()
    }
  },
  cpu: { connect: { id: Intel_I7_6700HQ.id } },
  storages: {
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
  },
  nodePool: { connect: { id: node_pool_workers.id } }
};

// eslint-disable-next-line @typescript-eslint/naming-convention
export const worker_1: Prisma.NodeCreateInput = {
  id: '0dafe0a1-beb9-4c30-8834-4e42338ed7b3',
  name: 'worker.0dafe0a1-beb9-4c30-8834-4e42338ed7b3',
  roles: [NodeRoleEnum.K8S_WORKER],
  address: '127.0.0.3',
  memory: BigInt(convert(2, 'GiB').to('B')),
  minPowerConsumption: 2000,
  maxPowerConsumption: 16000,
  status: {
    create: {
      status: NodeStatusEnum.ACTIVE,
      reason: 'NodeRegistered',
      message: 'Node registered',
      lastHeartbeat: new Date(),
      lastTransition: new Date()
    }
  },
  cpu: { connect: { id: Intel_I7_6700HQ.id } },
  storages: {
    createMany: { data: [{ name: 'sda', size: convert(250, 'GB').to('B') }] }
  },
  interfaces: {
    createMany: {
      data: [
        {
          name: 'eth0',
          address: '10-F7-AE-35-8F-72',
          speed: convert(1, 'Gb').to('b')
        }
      ]
    }
  },
  nodePool: { connect: { id: node_pool_workers.id } }
};

export const nodes = [controller_0, worker_0, worker_1];
