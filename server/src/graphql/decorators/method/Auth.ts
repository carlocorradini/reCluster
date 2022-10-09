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
import type { AuthData, UserRoles, NodeRoles } from '~/graphql';
import { TokenTypes } from '~/services';

export type AuthArgs<T extends TokenTypes> = {
  type?: T;
  roles?: T extends TokenTypes.USER
    ? UserRoles | UserRoles[]
    : T extends TokenTypes.NODE
    ? NodeRoles | NodeRoles[]
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
      permissions: []
    };

    const typeString = `"${authData.type}"`;
    const rolesString = `[${authData.roles
      .map((role) => `"${role}"`)
      .join(',')}]`;
    const permissionsString = `[${authData.permissions
      .map((permission) => `"${permission}"`)
      .join(',')}]`;

    const authDataString = `@auth(type: ${typeString}, roles: ${rolesString}, permissions: ${permissionsString})`;
    Directive(authDataString)(targetOrPrototype, propertyKey, descriptor);
  };
}
