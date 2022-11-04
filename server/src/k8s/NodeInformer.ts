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

import * as k8s from '@kubernetes/client-node';
import { inject, injectable, singleton } from 'tsyringe';
import convert from 'convert';
import type { UpdateStatusInput } from '~/types';
import { config } from '~/config';
import { logger } from '~/logger';
import { StatusService } from '~/services/StatusService';
import { NodeStatusEnum } from '~/db';
import { kubeconfig } from './kubeconfig';
import { K8sNodeStatusesEnum } from './K8sNodeStatusesEnum';

type K8sNode = {
  id: string;
  status: UpdateStatusInput;
};

@singleton()
@injectable()
export class NodeInformer {
  public static readonly RESTART_TIME: number = convert(3, 's').to('ms');

  private readonly api: k8s.CoreV1Api;

  private readonly informer: k8s.Informer<k8s.V1Node>;

  public constructor(
    @inject(StatusService)
    private readonly statusService: StatusService
  ) {
    this.api = kubeconfig.makeApiClient(k8s.CoreV1Api);

    this.informer = k8s.makeInformer(kubeconfig, '/api/v1/nodes', () =>
      this.api.listNode()
    );

    this.informer.on(k8s.ADD, (node: k8s.V1Node) => this.on(k8s.ADD, node));
    this.informer.on(k8s.UPDATE, (node: k8s.V1Node) =>
      this.on(k8s.UPDATE, node)
    );
    this.informer.on(k8s.DELETE, (node: k8s.V1Node) =>
      this.on(k8s.DELETE, node)
    );
    this.informer.on(k8s.CONNECT, this.onConnect.bind(this));
    this.informer.on(k8s.ERROR, this.onError.bind(this));
  }

  private restart() {
    logger.info(`Restarting Node informer in ${NodeInformer.RESTART_TIME} ms`);

    setTimeout(async () => {
      await this.start();
    }, NodeInformer.RESTART_TIME);
  }

  public async start() {
    try {
      logger.info('Starting Node informer');
      await this.informer.start();
    } catch (error) {
      logger.error(
        `Error starting Node informer: ${
          error instanceof Error ? error.message : error
        }`
      );
      this.restart();
    }
  }

  public async stop() {
    logger.info('Stopping Node informer');
    await this.informer.stop();
  }

  private onConnect() {
    logger.debug('Node informer connected');
  }

  private onError(error: unknown) {
    logger.error(
      `Node informer error: ${error instanceof Error ? error.message : error}`
    );
    this.restart();
  }

  private async onAdd(node: K8sNode) {
    logger.debug(`K8s node added: ${JSON.stringify(node)}`);

    this.statusService.update({ where: { id: node.id }, data: node.status });
  }

  private async onUpdate(node: K8sNode) {
    logger.debug(`K8s node updated: ${JSON.stringify(node)}`);

    this.statusService.update({ where: { id: node.id }, data: node.status });
  }

  private onDelete(node: K8sNode) {
    logger.debug(`K8s node deleted: ${JSON.stringify(node)}`);

    this.statusService.update({
      where: { id: node.id },
      data: {
        status: NodeStatusEnum.ACTIVE,
        reason: 'NodeDeleted',
        message: 'Node deleted'
      }
    });

    // TODO Turn off node
  }

  private on(verb: k8s.ADD | k8s.UPDATE | k8s.DELETE, node: k8s.V1Node) {
    const id: string | undefined =
      node?.metadata?.labels?.[config.k8s.label.node.id];
    const ready: k8s.V1NodeCondition | undefined =
      node?.status?.conditions?.find((c) => c.type === 'Ready');

    if (!id) {
      logger.error(
        `Node informer unknown node with uid '${node?.metadata?.uid ?? ''}`
      );
      return;
    }
    if (!ready) {
      logger.error(`Node informer node '${id}' ready status not found`);
      return;
    }

    // Define status
    let status: NodeStatusEnum;
    switch (ready.status) {
      case K8sNodeStatusesEnum.TRUE:
        status = NodeStatusEnum.ACTIVE_READY;
        break;
      case K8sNodeStatusesEnum.FALSE:
        status = NodeStatusEnum.ACTIVE_NOT_READY;
        break;
      case K8sNodeStatusesEnum.UNKNOWN:
        status = NodeStatusEnum.UNKNOWN;
        break;
      default:
        logger.warn(
          `Node informer node '${id}' unknown ready status '${ready.status}'`
        );
        return;
    }

    // Construct K8s node
    const k8sNode: K8sNode = {
      id,
      status: {
        status,
        reason: ready.reason,
        message: ready.message,
        lastHeartbeat: ready.lastHeartbeatTime,
        lastTransition: ready.lastTransitionTime
      }
    };

    switch (verb) {
      case k8s.ADD:
        this.onAdd(k8sNode);
        break;
      case k8s.UPDATE:
        this.onUpdate(k8sNode);
        break;
      case k8s.DELETE:
        this.onDelete(k8sNode);
        break;
      default:
        logger.warn(`Node informer unknown verb '${verb}'`);
        break;
    }
  }
}
