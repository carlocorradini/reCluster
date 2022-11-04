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

import { Prisma } from '@prisma/client';

// eslint-disable-next-line @typescript-eslint/naming-convention
export const node_pool_controllers: Prisma.NodePoolCreateInput = {
  id: '1f808324-465f-4328-ac07-cee8afb1281a',
  name: 'node_pool_controllers',
  autoScale: false,
  minNodes: 1
};

// eslint-disable-next-line @typescript-eslint/naming-convention
export const node_pool_workers: Prisma.NodePoolCreateInput = {
  id: '88e07149-646d-4456-9c00-16b345f230d2',
  name: 'node_pool_workers',
  autoScale: true,
  minNodes: 1
};

export const nodePools = [node_pool_controllers, node_pool_workers];
