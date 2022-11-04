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
import { kubeconfig } from '~/k8s';
import { logger } from '~/logger';
import { config } from '~/config';

type FindUniqueNodeArgs = { id: string };

type DeleteNodeArgs = { id: string };

export class K8sService {
  private readonly api: k8s.CoreV1Api;

  public constructor() {
    this.api = kubeconfig.makeApiClient(k8s.CoreV1Api);
  }

  public async findUniqueNode(args: FindUniqueNodeArgs): Promise<k8s.V1Node> {
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

    if (nodes.length !== 1) {
      // FIXME Error
      throw new Error(`K8s node '${args.id}' not found`);
    }

    return nodes[0];
  }

  public async deleteNode(args: DeleteNodeArgs): Promise<k8s.V1Status> {
    logger.info(`K8s service delete node: ${JSON.stringify(args)}`);

    // TODO Drain node

    const node = await this.findUniqueNode({ id: args.id });
    if (!node.metadata || !node.metadata.name) {
      // FIXME Error
      throw new Error(`K8s node '${args.id}' missing name metadata`);
    }

    const { body: status } = await this.api.deleteNode(node.metadata.name);
    return status;
  }
}
