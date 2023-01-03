/*
 * MIT License
 *
 * Copyright (c) 2022-2023 Carlo Corradini
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

import type jwt from 'jsonwebtoken';
import type { TokenTypes } from '~/services';
import type {
  UserRoleEnum,
  UserPermissionEnum,
  NodeRoleEnum,
  NodePermissionEnum
} from '~/db';

type ITokenPayload<T extends TokenTypes> = {
  type: T;
  id: string;
  roles: T extends TokenTypes.USER
    ? UserRoleEnum[]
    : T extends TokenTypes.NODE
    ? NodeRoleEnum[]
    : never;
  permissions: T extends TokenTypes.USER
    ? UserPermissionEnum[]
    : T extends TokenTypes.NODE
    ? NodePermissionEnum[]
    : never;
};
export type UserTokenPayload = ITokenPayload<TokenTypes.USER>;
export type NodeTokenPayload = ITokenPayload<TokenTypes.NODE>;
export type TokenPayload = UserTokenPayload | NodeTokenPayload;

type IToken<T> = jwt.Jwt & { payload: T };
export type UserToken = IToken<UserTokenPayload>;
export type NodeToken = IToken<NodeTokenPayload>;
export type Token = UserToken | NodeToken;
