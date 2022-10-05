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

export enum InterfaceWoLFlags {
  a = 'a',
  b = 'b',
  d = 'd',
  g = 'g',
  m = 'm',
  p = 'p',
  s = 's',
  u = 'u'
}

registerEnumType(InterfaceWoLFlags, {
  name: 'InterfaceWoLFlags',
  description: 'Interface Wake-on-Lan flags',
  valuesConfig: {
    a: { description: 'Wake on ARP' },
    b: { description: 'Wake on broadcast messages' },
    d: { description: 'Disable' },
    g: { description: 'Wake on MagicPacket' },
    m: { description: 'Wake on multicast messages' },
    p: { description: 'Wake on PHY activity' },
    s: { description: 'Enable SecureOn password for MagicPacket' },
    u: { description: 'Wake on unicast messages' }
  }
});
