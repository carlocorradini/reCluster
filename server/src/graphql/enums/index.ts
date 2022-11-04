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
import {
  CpuArchitectureEnum,
  CpuVendorEnum,
  WoLFlagEnum,
  NodeRoleEnum,
  NodePermissionEnum,
  NodeStatusEnum,
  UserRoleEnum,
  UserPermissionEnum
} from '~/db';

export * from './CaseSensitivityEnum';
export * from './DigitalUnitEnum';
export * from './SortOrderEnum';

registerEnumType(CpuArchitectureEnum, {
  name: 'CpuArchitectureEnum',
  description: 'Cpu architectures',
  valuesConfig: {
    AMD64: {
      description:
        '64-bit version of the x86 instruction set. Also known as x64, x86-64, x86_64, AMD64, and Intel 64'
    },
    ARM64: {
      description:
        '64-bit extension of the ARM architecture family. Also known as AArch64 and ARM64'
    }
  }
});

registerEnumType(CpuVendorEnum, {
  name: 'CpuVendorEnum',
  description: 'Cpu vendors',
  valuesConfig: {
    AMD: { description: 'Advanced Micro Devices' },
    INTEL: { description: 'Intel' }
  }
});

registerEnumType(WoLFlagEnum, {
  name: 'WoLFlagEnum',
  description: 'Wake-on-Lan flags',
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

registerEnumType(NodeRoleEnum, {
  name: 'NodeRoleEnum',
  description: 'Node roles',
  valuesConfig: {
    RECLUSTER_CONTROLLER: { description: 'reCluster controller' },
    K8S_CONTROLLER: { description: 'K8s controller' },
    K8S_WORKER: { description: 'K8s worker' }
  }
});

registerEnumType(NodePermissionEnum, {
  name: 'NodePermissionEnum',
  description: 'Node permissions',
  valuesConfig: {}
});

registerEnumType(NodeStatusEnum, {
  name: 'NodeStatusEnum',
  description: 'Node statuses',
  valuesConfig: {
    ACTIVE: { description: 'Node is active' },
    ACTIVE_READY: {
      description: 'Node is active, healthy and ready to accept pods'
    },
    ACTIVE_NOT_READY: {
      description: 'Node is active but not healthy and is not accepting pods'
    },
    BOOTING: {
      description: 'Node is booting'
    },
    INACTIVE: {
      description: 'Node is inactive'
    },
    UNKNOWN: {
      description: 'Unknown'
    }
  }
});

registerEnumType(UserRoleEnum, {
  name: 'UserRoleEnum',
  description: 'User roles',
  valuesConfig: {
    ADMIN: { description: 'Administrator' },
    SIMPLE: { description: 'Simple' }
  }
});

registerEnumType(UserPermissionEnum, {
  name: 'UserPermissionEnum',
  description: 'User permissions',
  valuesConfig: {}
});
