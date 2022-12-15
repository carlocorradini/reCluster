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

import { Directive } from 'type-graphql';
import type { AuthData } from '~/types';
import type {
  UserRoleEnum,
  NodeRoleEnum,
  UserPermissionEnum,
  NodePermissionEnum
} from '~/db';
import { TokenTypes } from '~/services/TokenService';

type AuthArgs<T extends TokenTypes> = {
  type?: T;
  roles?: T extends TokenTypes.USER
    ? UserRoleEnum | UserRoleEnum[]
    : T extends TokenTypes.NODE
    ? NodeRoleEnum | NodeRoleEnum[]
    : never;
  permissions?: T extends TokenTypes.USER
    ? UserPermissionEnum | UserPermissionEnum[]
    : T extends TokenTypes.NODE
    ? NodePermissionEnum | NodePermissionEnum[]
    : never;
};

export function Auth<T extends TokenTypes = TokenTypes.USER>(
  args?: AuthArgs<T>
): PropertyDecorator & MethodDecorator & ClassDecorator;
export function Auth<T extends TokenTypes = TokenTypes.USER>(
  args?: AuthArgs<T>
): PropertyDecorator | MethodDecorator | ClassDecorator {
  return (targetOrPrototype, propertyKey, descriptor) => {
    const authData: AuthData = {
      type: args?.type ?? TokenTypes.USER,
      // eslint-disable-next-line no-nested-ternary
      roles: !args?.roles
        ? []
        : Array.isArray(args.roles)
        ? args.roles
        : [args.roles],
      // eslint-disable-next-line no-nested-ternary
      permissions: !args?.permissions
        ? []
        : Array.isArray(args.permissions)
        ? args.permissions
        : [args.permissions]
    };

    // Directive sdl
    let sdl = `@auth(type: "${authData.type}"`;
    if (authData.roles.length > 0) {
      sdl += `, roles: [${authData.roles
        .map((role) => `"${role}"`)
        .join(',')}]`;
    }
    if (authData.permissions.length > 0) {
      sdl += `, permissions: [${authData.permissions
        .map((permission) => `"${permission}"`)
        .join(',')}]`;
    }
    sdl += `)`;

    // Attach
    Directive(sdl)(targetOrPrototype, propertyKey, descriptor);
  };
}
