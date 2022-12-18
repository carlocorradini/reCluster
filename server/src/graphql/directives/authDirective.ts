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

import { GraphQLSchema, defaultFieldResolver } from 'graphql';
import { mapSchema, MapperKind, getDirective } from '@graphql-tools/utils';
import { container } from 'tsyringe';
import type { AuthData, ClassType, Context, ResolverData } from '~/types';
import { AuthenticationError, AuthorizationError } from '~/errors';

enum AuthMode {
  ERROR = 'ERROR',
  NULL = 'NULL'
}

export type AuthFn<TContext = Record<string, unknown>> = (
  resolverData: ResolverData<TContext>,
  authData: AuthData
) => boolean | Promise<boolean>;

export type AuthFnClass<TContext = Record<string, unknown>> = {
  auth(
    resolverData: ResolverData<TContext>,
    authData: AuthData
  ): boolean | Promise<boolean>;
};

type Auth<TContext = Record<string, unknown>> =
  | AuthFn<TContext>
  | ClassType<AuthFnClass<TContext>>;

type AuthDirectiveArgs<TContext = Record<string, unknown>> = {
  name: string;
  auth: Auth<TContext>;
  authMode?: AuthMode;
};

// FIXME INPUT_FIELD_DEFINITION resolve function
function buildAuthDirective<TContext = Record<string, unknown>>({
  name,
  auth,
  authMode
}: AuthDirectiveArgs<TContext>) {
  const typeDirectiveArgumentMaps: Record<string, unknown> = {};

  return {
    typeDefs: `
      """Protect the resource from unauthenticated and unauthorized access."""
      directive @${name}(
        """Applicant type."""
        type: String!,
        """Allowed roles to access the resource."""
        roles: [String!]! = [],
        """Allowed permissions to access the resource."""
        permissions: [String!]! = [],
      ) on OBJECT | FIELD | FIELD_DEFINITION | INPUT_FIELD_DEFINITION`,
    transformer: (schema: GraphQLSchema) =>
      mapSchema(schema, {
        [MapperKind.TYPE]: (type) => {
          const authDirective = getDirective(schema, type, name)?.[0];
          if (authDirective) {
            typeDirectiveArgumentMaps[type.name] = authDirective;
          }
          return undefined;
        },
        // eslint-disable-next-line consistent-return
        [MapperKind.OBJECT_FIELD]: (fieldConfig, _, typeName) => {
          const authDirective =
            getDirective(schema, fieldConfig, name)?.[0] ??
            typeDirectiveArgumentMaps[typeName];

          if (authDirective) {
            const { type, roles, permissions }: Partial<AuthData> =
              authDirective;

            if (type && roles && permissions) {
              const { resolve = defaultFieldResolver } = fieldConfig;

              // eslint-disable-next-line no-param-reassign
              fieldConfig.resolve = async (root, args, context, info) => {
                let accessGranted: boolean;
                const resolverData: ResolverData<TContext> = {
                  root,
                  args,
                  context,
                  info
                };
                const authData: AuthData = { type, roles, permissions };

                if (auth.prototype) {
                  // Auth class
                  const authInstance = container.resolve(
                    auth as ClassType<AuthFnClass<TContext>>
                  );
                  accessGranted = await authInstance.auth(
                    resolverData,
                    authData
                  );
                } else {
                  // Auth function
                  accessGranted = await (auth as AuthFn<TContext>)(
                    resolverData,
                    authData
                  );
                }

                if (!accessGranted) {
                  switch (authMode) {
                    case AuthMode.NULL:
                      return null;
                    case AuthMode.ERROR:
                    default:
                      throw roles.length === 0 && permissions.length === 0
                        ? new AuthenticationError()
                        : new AuthorizationError();
                  }
                }

                return resolve(root, args, context, info);
              };

              return fieldConfig;
            }
          }
        }
      })
  };
}

const authFn: AuthFn<Context> = (
  { context: { applicant } },
  { type, roles, permissions }
) => {
  if (!applicant || applicant.type !== type) {
    // No applicant or invalid type
    return false;
  }

  if (roles.length === 0 && permissions.length === 0) {
    // Only authentication required
    return true;
  }

  // Roles
  const rolesMatch: boolean =
    roles.length === 0
      ? true
      : applicant.roles.some((role) => roles.includes(role));
  // Permissions
  const permissionsMatch: boolean =
    permissions.length === 0
      ? true
      : applicant.permissions.some((permission) =>
          permissions.includes(permission)
        );
  // Roles & Permissions
  return rolesMatch && permissionsMatch;
};

export const authDirective = buildAuthDirective({
  name: 'auth',
  authMode: AuthMode.ERROR,
  auth: authFn
});
