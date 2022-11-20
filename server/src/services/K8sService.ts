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
import type { K8sNode } from '~/types';
import { NodeStatusEnum } from '~/db';
import { K8sError } from '~/errors';
import { kubeconfig } from '~/k8s/kubeconfig';
import { K8sNodeStatusEnum } from '~/k8s/K8sNodeStatusEnum';
import { logger } from '~/logger';
import { config } from '~/config';

type FindUniqueNodeArgs = { id: string };

type DeleteNodeArgs = { id: string };

export class K8sService {
  private readonly api: k8s.CoreV1Api;

  public constructor() {
    this.api = kubeconfig.makeApiClient(k8s.CoreV1Api);
  }

  public async findUniqueNode(args: FindUniqueNodeArgs): Promise<K8sNode> {
    const label = `${config.k8s.label.node.id}=${args.id}`;

    const {
      body: { items: nodes }
    } = await this.api.listNode(
      undefined,
      undefined,
      undefined,
      undefined,
      label,
      1
    );

    if (nodes.length !== 1)
      throw new K8sError(`K8s node '${args.id}' not found`);

    return K8sService.toK8sNode(nodes[0]);
  }

  public async deleteNode(args: DeleteNodeArgs): Promise<k8s.V1Status> {
    logger.info(`K8s service delete node: ${JSON.stringify(args)}`);

    // TODO Drain node

    const node = await this.findUniqueNode({ id: args.id });
    const { body: status } = await this.api.deleteNode(node.name);

    return status;
  }

  public static toK8sNode(node: k8s.V1Node): K8sNode {
    const id: string | undefined =
      node?.metadata?.labels?.[config.k8s.label.node.id];
    const name: string | undefined = node.metadata?.name;
    const address: string | undefined = node.status?.addresses?.find(
      (a) => a.type === 'InternalIP'
    )?.address;
    const ready: k8s.V1NodeCondition | undefined =
      node?.status?.conditions?.find((c) => c.type === 'Ready');

    if (!id)
      throw new K8sError(
        `K8s node uid '${node?.metadata?.uid ?? ''} id label '${
          config.k8s.label.node.id
        }' not found`
      );
    if (!name) throw new K8sError(`K8s node '${id}' name not found`);
    if (!address) throw new K8sError(`K8s node '${id}' address not found`);
    if (!ready)
      throw new K8sError(`K8s node '${id}' ready condition not found`);

    let status: NodeStatusEnum;
    switch (ready.status) {
      case K8sNodeStatusEnum.TRUE:
        status = NodeStatusEnum.ACTIVE_READY;
        break;
      case K8sNodeStatusEnum.FALSE:
        status = NodeStatusEnum.ACTIVE_NOT_READY;
        break;
      case K8sNodeStatusEnum.UNKNOWN:
        status = NodeStatusEnum.UNKNOWN;
        break;
      default:
        throw new K8sError(
          `Node '${id}' unknown ready status '${ready.status}'`
        );
    }

    return <K8sNode>{
      id,
      name,
      address,
      status: {
        status,
        reason: ready.reason,
        message: ready.message,
        lastHeartbeat: ready.lastHeartbeatTime,
        lastTransition: ready.lastTransitionTime
      }
    };
  }
}
