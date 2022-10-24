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

import { registerEnumType } from 'type-graphql';

export enum NodeStatuses {
  ACTIVE = 'ACTIVE',
  ACTIVE_NOT_READY = 'ACTIVE_NOT_READY',
  ACTIVE_READY = 'ACTIVE_READY',
  ACTIVE_UNKNOWN = 'ACTIVE_UNKNOWN',
  INACTIVE = 'INACTIVE',
  ERROR = 'ERROR'
}

registerEnumType(NodeStatuses, {
  name: 'NodeStatuses',
  description: 'Node statuses',
  valuesConfig: {
    ACTIVE: { description: 'Node is active' },
    ACTIVE_NOT_READY: {
      description:
        'Node is active and K8s is not healthy and is not accepting pods'
    },
    ACTIVE_READY: {
      description: 'Node is active and K8s is healthy and ready to accept pods'
    },
    ACTIVE_UNKNOWN: {
      description:
        'Node is active and K8s has not heard the node in the last node-monitor-grace-period'
    },
    INACTIVE: { description: 'Node is inactive' },
    ERROR: { description: 'Node error' }
  }
});
