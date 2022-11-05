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

import type { Prisma } from '@prisma/client';
import { inject, injectable } from 'tsyringe';
import type { CreateNodeInput, UpdateStatusInput, WithRequired } from '~/types';
import { prisma, NodeStatusEnum, NodeRoleEnum, NodePermissionEnum } from '~/db';
import { logger } from '~/logger';
import { SSH } from '~/ssh';
import { TokenService, TokenTypes } from './TokenService';
import { CpuService } from './CpuService';
import { NodePoolService } from './NodePoolService';
import { StatusService } from './StatusService';
import { K8sService } from './K8sService';

type CreateArgs = Omit<Prisma.NodeCreateArgs, 'include' | 'data'> & {
  data: CreateNodeInput;
};

type FindManyArgs = Omit<Prisma.NodeFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.NodeFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<Prisma.NodeFindUniqueOrThrowArgs, 'include'>;

type UpdateArgs = Omit<Prisma.NodeUpdateArgs, 'include' | 'where' | 'data'> & {
  where: WithRequired<Prisma.NodeWhereUniqueInput, 'id'>;
  data: Omit<Prisma.NodeUpdateInput, 'status'> & {
    status?: UpdateStatusInput;
  };
};

type UnassignArgs = {
  where: WithRequired<Prisma.NodeWhereUniqueInput, 'id'>;
};

type ShutdownArgs = {
  where: WithRequired<Prisma.NodeWhereUniqueInput, 'id'>;
  status?: Pick<UpdateStatusInput, 'reason' | 'message'>;
};

@injectable()
export class NodeService {
  public constructor(
    @inject(CpuService)
    private readonly cpuService: CpuService,
    @inject(NodePoolService)
    private readonly nodePoolService: NodePoolService,
    @inject(StatusService)
    private readonly statusService: StatusService,
    @inject(K8sService)
    private readonly k8sService: K8sService,
    @inject(TokenService)
    private readonly tokenService: TokenService
  ) {}

  public async create(args: CreateArgs) {
    logger.info(`Node service create: ${JSON.stringify(args)}`);

    // Create or update cpu
    const { id: cpuId } = await this.cpuService.upsert({
      data: args.data.cpu,
      select: { id: true }
    });

    // Create or update node pool
    const { id: nodePoolId } = await this.nodePoolService.upsert({
      data: { cpu: args.data.cpu.cores, memory: args.data.ram },
      select: { id: true }
    });

    // Create
    const node = await prisma.node.create({
      ...args,
      select: { id: true, roles: true, permissions: true },
      data: {
        ...args.data,
        status: {
          create: {
            status: NodeStatusEnum.ACTIVE,
            reason: 'NodeRegistered',
            message: 'Node registered',
            lastHeartbeat: new Date(),
            lastTransition: new Date()
          }
        },
        nodePool: { connect: { id: nodePoolId } },
        cpu: { connect: { id: cpuId } },
        disks: { createMany: { data: args.data.disks } },
        interfaces: {
          createMany: { data: args.data.interfaces }
        }
      }
    });

    // Generate token
    return this.tokenService.sign({
      type: TokenTypes.NODE,
      id: node.id,
      roles: node.roles as NodeRoleEnum[], // FIXME
      permissions: node.permissions as NodePermissionEnum[] // FIXME
    });
  }

  public findMany(args: FindManyArgs) {
    logger.debug(`Node service find many: ${JSON.stringify(args)}`);

    return prisma.node.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(args: FindUniqueArgs) {
    logger.debug(`Node service find unique: ${JSON.stringify(args)}`);

    return prisma.node.findUnique(args);
  }

  public findUniqueOrThrow(args: FindUniqueOrThrowArgs) {
    logger.debug(`Node service find unique or throw: ${JSON.stringify(args)}`);

    return prisma.node.findUniqueOrThrow(args);
  }

  public async update(args: UpdateArgs) {
    logger.info(`Node service update: ${JSON.stringify(args)}`);

    // Extract data
    const { data } = args;

    if (data.status) {
      await this.statusService.update({
        where: { id: args.where.id },
        data: data.status
      });

      delete data.status;
    }

    // Write data
    // eslint-disable-next-line no-param-reassign
    args.data = data;

    return prisma.node.update({
      ...args,
      data: { ...args.data, status: undefined }
    });
  }

  public async unassign(args: UnassignArgs) {
    logger.info(`Node service unassign: ${JSON.stringify(args)}`);

    // Check if node exists and assigned to node pool
    const count = await prisma.node.count({
      where: {
        id: args.where.id,
        nodePoolAssigned: true
      }
    });
    if (count !== 1) {
      // FIXME Error
      throw new Error(`Cannot unassign node ${args.where.id}`);
    }

    // Delete K8s node
    await this.k8sService.deleteNode({ id: args.where.id });

    // Unassign node
    return this.update({
      where: { id: args.where.id },
      data: {
        nodePoolAssigned: false,
        status: {
          status: NodeStatusEnum.ACTIVE_DELETE,
          reason: 'NodeUnassign',
          message: 'Node unassign'
        }
      }
    });
  }

  public async shutdown(args: ShutdownArgs) {
    logger.info(`Node service shutdown: ${JSON.stringify(args)}`);

    // FIXME Node host
    const host = '';

    const ssh = await new SSH().connect({ host });

    await ssh.execCommand({
      command: 'shutdown -h now',
      disconnect: true
    });
    await this.statusService.update({
      where: { id: args.where.id },
      data: {
        status: NodeStatusEnum.INACTIVE,
        reason: args.status?.reason ?? 'NodeShutdown',
        message: args.status?.message ?? 'Node shutdown'
      }
    });
  }
}
