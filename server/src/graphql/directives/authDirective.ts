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

import {
  GraphQLSchema,
  defaultFieldResolver,
  GraphQLDirective,
  DirectiveLocation,
  GraphQLList,
  GraphQLString,
  GraphQLNonNull
} from 'graphql';
import { mapSchema, MapperKind, getDirective } from '@graphql-tools/utils';
import { container } from 'tsyringe';
import { ClassType, ResolverData } from '~/types';
import { AuthenticationError, AuthorizationError } from '~/errors';
import { TokenTypes } from '~/services';
import { authFn } from '~/auth';

enum AuthMode {
  ERROR = 'ERROR',
  NULL = 'NULL'
}

type AuthData = {
  type: string;
  roles: string[];
  permissions: string[];
};

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

export type Auth<TContext = Record<string, unknown>> =
  | AuthFn<TContext>
  | ClassType<AuthFnClass<TContext>>;

type AuthDirective<TContext = Record<string, unknown>> = {
  auth: Auth<TContext>;
  authMode?: AuthMode;
};

function buildAuthDirective<TContext = Record<string, unknown>>({
  auth,
  authMode
}: AuthDirective<TContext>) {
  const name = 'auth';
  const typeDirectiveArgumentMaps: Record<string, unknown> = {};

  return {
    typeDefsObj: new GraphQLDirective({
      name,
      description: 'Protect the resource from unauthorized access.',
      locations: [
        DirectiveLocation.OBJECT,
        DirectiveLocation.FIELD,
        DirectiveLocation.FIELD_DEFINITION,
        DirectiveLocation.INPUT_FIELD_DEFINITION
      ],
      args: {
        type: {
          type: GraphQLNonNull(GraphQLString),
          defaultValue: TokenTypes.USER,
          description: 'Applicant type.'
        },
        roles: {
          type: GraphQLNonNull(GraphQLList(GraphQLNonNull(GraphQLString))),
          defaultValue: [],
          description: 'Allowed roles to access the resource.'
        },
        permissions: {
          type: GraphQLNonNull(GraphQLList(GraphQLNonNull(GraphQLString))),
          defaultValue: [],
          description: 'Allowed applicant to access the resource.'
        }
      }
    }),
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
            const {
              type,
              roles,
              permissions
            }: { type?: string; roles?: string[]; permissions?: string[] } =
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
                      throw roles.length === 0
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

export const authDirective = buildAuthDirective({
  auth: authFn,
  authMode: AuthMode.ERROR
});
