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
import { delay, inject, injectable } from 'tsyringe';
import type {
  CreateNodeInput,
  UpdateNodeInput,
  UpdateStatusInput,
  WithRequired
} from '~/types';
import { NodeError } from '~/errors';
import { prisma, NodeStatusEnum, NodeRoleEnum } from '~/db';
import { logger } from '~/logger';
import { SSH } from '~/ssh';
import { TokenService, TokenTypes } from './TokenService';
import { CpuService } from './CpuService';
// eslint-disable-next-line import/no-cycle
import { NodePoolService } from './NodePoolService';
import { StatusService } from './StatusService';
import { K8sService } from './K8sService';
import { WoLService } from './WoLService';

type CreateArgs = Omit<Prisma.NodeCreateArgs, 'include' | 'data'> & {
  data: CreateNodeInput;
};

type FindManyArgs = Omit<Prisma.NodeFindManyArgs, 'include' | 'cursor'> & {
  cursor?: string;
};

type FindUniqueArgs = Omit<Prisma.NodeFindUniqueArgs, 'include'>;

type FindUniqueOrThrowArgs = Omit<Prisma.NodeFindUniqueOrThrowArgs, 'include'>;

type UpdateArgs = Omit<Prisma.NodeUpdateArgs, 'include' | 'where' | 'data'> & {
  where: WithRequired<Pick<Prisma.NodeWhereUniqueInput, 'id'>, 'id'>;
  data: UpdateNodeInput;
};

type UnassignArgs = {
  where: WithRequired<Pick<Prisma.NodeWhereUniqueInput, 'id'>, 'id'>;
};

type ShutdownArgs = {
  where: WithRequired<Pick<Prisma.NodeWhereUniqueInput, 'id'>, 'id'>;
  status?: Pick<UpdateStatusInput, 'reason' | 'message'>;
};

type BootArgs = {
  where: WithRequired<Pick<Prisma.NodeWhereUniqueInput, 'id'>, 'id'>;
  status?: Pick<UpdateStatusInput, 'reason' | 'message'>;
};

@injectable()
export class NodeService {
  public constructor(
    @inject(CpuService)
    private readonly cpuService: CpuService,
    @inject(delay(() => NodePoolService))
    private readonly nodePoolService: NodePoolService,
    @inject(StatusService)
    private readonly statusService: StatusService,
    @inject(K8sService)
    private readonly k8sService: K8sService,
    @inject(TokenService)
    private readonly tokenService: TokenService,
    @inject(WoLService)
    private readonly wolService: WoLService
  ) {}

  public create(args: CreateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node service create: ${JSON.stringify(args)}`);

      // Create or update cpu
      const { id: cpuId } = await this.cpuService.upsert(
        {
          data: args.data.cpu,
          select: { id: true }
        },
        prisma
      );

      // Create or update node pool
      const { id: nodePoolId } = await this.nodePoolService.upsert(
        {
          data: {
            cpu: args.data.cpu.cores,
            memory: args.data.memory,
            roles: args.data.roles
          },
          select: { id: true }
        },
        prisma
      );

      // Create
      const { id, roles } = await prisma.node.create({
        ...args,
        select: { id: true, roles: true },
        data: {
          ...args.data,
          name: `dummy.${args.data.hostname}`,
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
          storages: { createMany: { data: args.data.storages } },
          interfaces: {
            createMany: { data: args.data.interfaces }
          }
        }
      });

      // Update name
      const node = await this.update(
        {
          where: { id },
          select: { id: true, roles: true, permissions: true },
          data: {
            name: `${
              roles.some((role) => role === NodeRoleEnum.K8S_WORKER)
                ? 'worker'
                : 'controller'
            }.${id}`
          }
        },
        prisma
      );

      // Generate token
      return this.tokenService.sign({
        type: TokenTypes.NODE,
        id: node.id,
        roles: node.roles,
        permissions: node.permissions
      });
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public findMany(
    args: FindManyArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Node service find many: ${JSON.stringify(args)}`);

    return prismaTxn.node.findMany({
      ...args,
      cursor: args.cursor ? { id: args.cursor } : undefined
    });
  }

  public findUnique(
    args: FindUniqueArgs,
    prismaTxn: Prisma.TransactionClient = prisma
  ) {
    logger.debug(`Node service find unique: ${JSON.stringify(args)}`);

    return prismaTxn.node.findUnique(args);
  }

  public findUniqueOrThrow<T extends Prisma.NodeFindUniqueOrThrowArgs>(
    args: Prisma.SelectSubset<T, FindUniqueOrThrowArgs>,
    prismaTxn: Prisma.TransactionClient = prisma
  ): Prisma.Prisma__NodeClient<Prisma.NodeGetPayload<T>> {
    logger.debug(`Node service find unique or throw: ${JSON.stringify(args)}`);

    return prismaTxn.node.findUniqueOrThrow(args);
  }

  public update(args: UpdateArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node service update: ${JSON.stringify(args)}`);

      // Extract data
      const { data } = args;

      if (data.status) {
        await this.statusService.update(
          {
            where: { id: args.where.id },
            data: data.status
          },
          prisma
        );

        delete data.status;
      }

      // Write data
      // eslint-disable-next-line no-param-reassign
      args.data = data;

      return prisma.node.update({
        ...args,
        data: { ...args.data, status: undefined }
      });
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public unassign(args: UnassignArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node service unassign: ${JSON.stringify(args)}`);

      // Check if node exists and assigned to node pool
      const { nodePoolAssigned } = await this.findUniqueOrThrow(
        {
          where: { id: args.where.id },
          select: { nodePoolAssigned: true }
        },
        prisma
      );
      if (!nodePoolAssigned)
        throw new NodeError(
          `Node '${args.where.id}' is not assigned to any node pool`
        );

      // Delete K8s node
      await this.k8sService.deleteNode({ id: args.where.id });

      // Update
      return this.update(
        {
          where: { id: args.where.id },
          data: {
            nodePoolAssigned: false,
            status: {
              status: NodeStatusEnum.ACTIVE_DELETE,
              reason: 'NodeUnassign',
              message: 'Node unassign'
            }
          }
        },
        prisma
      );
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public shutdown(args: ShutdownArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node service shutdown: ${JSON.stringify(args)}`);

      // Check if node exists and not assigned to node pool
      const node = await this.findUniqueOrThrow(
        {
          where: { id: args.where.id },
          select: { nodePoolId: true, nodePoolAssigned: true, hostname: true }
        },
        prisma
      );
      if (node.nodePoolAssigned)
        throw new NodeError(
          `Node '${args.where.id}' is assigned to node pool ${node.nodePoolId}`
        );

      // Shutdown
      const ssh = await SSH.connect({ host: node.hostname });
      await ssh.execCommand({
        command: 'sudo poweroff',
        disconnect: true
      });

      // Update
      await this.update(
        {
          where: { id: args.where.id },
          data: {
            status: {
              status: NodeStatusEnum.INACTIVE,
              reason: args.status?.reason ?? 'NodeShutdown',
              message: args.status?.message ?? 'Node shutdown'
            }
          }
        },
        prisma
      );
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }

  public boot(args: BootArgs, prismaTxn?: Prisma.TransactionClient) {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const fn = async (prisma: Prisma.TransactionClient) => {
      logger.info(`Node service boot: ${JSON.stringify(args)}`);

      // Check if node exists and not assigned to node pool
      const node = await this.findUniqueOrThrow(
        {
          where: { id: args.where.id },
          select: {
            nodePoolId: true,
            nodePoolAssigned: true,
            address: true,
            interfaces: {
              where: { wol: { isEmpty: false } },
              select: { address: true }
            }
          }
        },
        prisma
      );
      if (node.nodePoolAssigned)
        throw new NodeError(
          `Node '${args.where.id}' is assigned to node pool ${node.nodePoolId}`
        );
      if (node.interfaces.length === 0)
        throw new NodeError(`Node '${args.where.id}' has no WoL interfaces`);

      // Bootstrap
      await Promise.any(
        node.interfaces.map((intf) =>
          this.wolService.wake({
            mac: intf.address,
            address: node.address
          })
        )
      );

      // Update
      await this.update(
        {
          where: { id: args.where.id },
          data: {
            nodePoolAssigned: true,
            status: {
              status: NodeStatusEnum.BOOTING,
              reason: args.status?.reason ?? 'NodeBoot',
              message: args.status?.message ?? 'Node boot'
            }
          }
        },
        prisma
      );
    };

    return prismaTxn ? fn(prismaTxn) : prisma.$transaction(fn);
  }
}
