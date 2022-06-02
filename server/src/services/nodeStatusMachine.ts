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

import { createMachine } from 'xstate';
import { NodeStatus } from '~/graphql/entities';

export const nodeStatusMachine = createMachine({
  states: {
    [NodeStatus.ACTIVE]: {
      on: {
        [NodeStatus.ACTIVE_TO_WORKING]: NodeStatus.ACTIVE_TO_WORKING,
        [NodeStatus.ACTIVE_TO_INACTIVE]: NodeStatus.ACTIVE_TO_INACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.ACTIVE_TO_WORKING]: {
      on: {
        [NodeStatus.WORKING]: NodeStatus.WORKING,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.ACTIVE_TO_INACTIVE]: {
      on: {
        [NodeStatus.INACTIVE]: NodeStatus.INACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.WORKING]: {
      on: {
        [NodeStatus.WORKING_TO_ACTIVE]: NodeStatus.WORKING_TO_ACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.WORKING_TO_ACTIVE]: {
      on: {
        [NodeStatus.ACTIVE]: NodeStatus.ACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.INACTIVE]: {
      on: {
        [NodeStatus.INACTIVE_TO_ACTIVE]: NodeStatus.INACTIVE_TO_ACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.INACTIVE_TO_ACTIVE]: {
      on: {
        [NodeStatus.ACTIVE]: NodeStatus.ACTIVE,
        [NodeStatus.ERROR]: NodeStatus.ERROR
      }
    },
    [NodeStatus.ERROR]: {
      on: {
        [NodeStatus.ACTIVE]: NodeStatus.ACTIVE,
        [NodeStatus.ACTIVE_TO_WORKING]: NodeStatus.ACTIVE_TO_WORKING,
        [NodeStatus.ACTIVE_TO_INACTIVE]: NodeStatus.ACTIVE_TO_INACTIVE,
        [NodeStatus.WORKING]: NodeStatus.WORKING,
        [NodeStatus.WORKING_TO_ACTIVE]: NodeStatus.WORKING_TO_ACTIVE,
        [NodeStatus.INACTIVE]: NodeStatus.INACTIVE,
        [NodeStatus.INACTIVE_TO_ACTIVE]: NodeStatus.INACTIVE_TO_ACTIVE
      }
    }
  }
});
