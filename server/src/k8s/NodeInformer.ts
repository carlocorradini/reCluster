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
import { Inject, Service } from 'typedi';
import { NodeService } from '~/services';
import { logger } from '~/logger';
import { NodeStatus } from '~/graphql';
import { kubeconfig } from './kubeconfig';

type NodeInfo = {
  id: string;
  ready: boolean;
};

@Service()
export class NodeInformer {
  public static readonly RECLUSTER_IO_ID: string = 'recluster.io/id';

  public static readonly RESTART_TIME_MS: number = 3000;

  @Inject()
  private readonly nodeService!: NodeService;

  private readonly informer: k8s.Informer<k8s.V1Node>;

  public constructor() {
    const api = kubeconfig.makeApiClient(k8s.CoreV1Api);

    this.informer = k8s.makeInformer(kubeconfig, '/api/v1/nodes', () =>
      api.listNode()
    );

    this.informer.on(k8s.ADD, this.onAdd);
    this.informer.on(k8s.UPDATE, this.onUpdate);
    this.informer.on(k8s.DELETE, this.onDelete);
    this.informer.on(k8s.CONNECT, this.onConnect);
    this.informer.on(k8s.ERROR, this.onError as k8s.ObjectCallback<k8s.V1Node>);
  }

  private restart() {
    logger.debug(
      `Restarting Node informer in ${NodeInformer.RESTART_TIME_MS} ms`
    );

    setTimeout(() => {
      logger.info('Restarting Node informer');
      this.start();
    }, NodeInformer.RESTART_TIME_MS);
  }

  public async start() {
    try {
      logger.info('Starting Node informer');
      await this.informer.start();
      logger.info('Node informer started');
    } catch (error) {
      logger.error(`Error starting Node informer: ${error}`);
      this.restart();
    }
  }

  public async stop() {
    logger.info('Stopping Node informer');
    await this.informer.stop();
    logger.info('Node informer stopped');
  }

  private onAdd(node: k8s.V1Node) {
    logger.debug(`Node added in K8s: ${JSON.stringify(node)}`);

    const nodeInfo = this.nodeInfo(node);
    logger.info(`Node '${nodeInfo.id}' added in K8s`);

    this.nodeService.update(nodeInfo.id, {
      data: {
        status: NodeStatus.ACTIVE_TO_WORKING
      }
    });
  }

  private async onUpdate(node: k8s.V1Node) {
    logger.debug(`Node updated in K8s: ${JSON.stringify(node)}`);

    const nodeInfo = this.nodeInfo(node);
    logger.info(
      `Node '${nodeInfo.id}' updated in K8s: ${JSON.stringify(nodeInfo)}`
    );

    let status: NodeStatus = NodeStatus.ERROR;
    const reClusterNode = await this.nodeService.findUnique({
      select: { status: true },
      where: { id: nodeInfo.id }
    });

    switch (reClusterNode?.status) {
      case NodeStatus.ACTIVE_TO_WORKING: {
        if (!nodeInfo.ready) return;
        status = NodeStatus.WORKING;
        break;
      }
      case NodeStatus.WORKING_TO_ACTIVE: {
        if (nodeInfo.ready) return;
        status = NodeStatus.ACTIVE;
        break;
      }
      default: {
        status = NodeStatus.ERROR;
        break;
      }
    }

    this.nodeService.update(nodeInfo.id, { data: { status } });
  }

  private onDelete(node: k8s.V1Node) {
    // TODO Fix status
    logger.debug(`Node deleted in K8s: ${JSON.stringify(node)}`);

    const nodeInfo = this.nodeInfo(node);
    logger.info(`Node '${nodeInfo.id}' deleted in K8s`);

    this.nodeService.update(nodeInfo.id, {
      data: { status: NodeStatus.ACTIVE }
    });
  }

  private onConnect() {
    logger.info('Node informer connected');
  }

  private onError(error: Error) {
    logger.error(`Node informer error: ${error.message}`);
    this.restart();
  }

  private nodeInfo(node: k8s.V1Node): NodeInfo {
    // TODO Better error
    if (!node?.metadata?.labels?.[NodeInformer.RECLUSTER_IO_ID])
      throw new Error(
        `Label '${NodeInformer.RECLUSTER_IO_ID}' not found in K8s Node uid ${node?.metadata?.uid}`
      );

    return {
      id: node?.metadata?.labels?.[NodeInformer.RECLUSTER_IO_ID],
      ready:
        node?.status?.conditions?.find((c) => c.type === 'Ready')?.status ===
        'True'
    };
  }
}
