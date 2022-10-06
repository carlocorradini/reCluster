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

import jwt from 'jsonwebtoken';
import { config } from '~/config';
import { TokenError } from '~/errors';
import { UserRoles, NodeRoles } from '~/graphql/enums';

export enum TokenTypes {
  USER = 'USER',
  NODE = 'NODE'
}

type ITokenPayload<T extends TokenTypes> = {
  type: T;
  id: string;
  roles: T extends TokenTypes.USER
    ? UserRoles[]
    : T extends TokenTypes.NODE
    ? NodeRoles[]
    : never;
};
export type UserTokenPayload = ITokenPayload<TokenTypes.USER>;
export type NodeTokenPayload = ITokenPayload<TokenTypes.NODE>;
export type TokenPayload = UserTokenPayload | NodeTokenPayload;

type IToken<T> = jwt.Jwt & { payload: T };
export type UserToken = IToken<UserTokenPayload>;
export type NodeToken = IToken<NodeTokenPayload>;
export type Token = UserToken | NodeToken;

export class TokenService {
  public static readonly SIGN_OPTIONS: jwt.SignOptions = {
    expiresIn: '365 days'
  };

  public static readonly VERIFY_OPTIONS: jwt.VerifyOptions = {
    complete: true
  };

  public sign(payload: TokenPayload): Promise<string> {
    return new Promise((resolve, reject) => {
      jwt.sign(
        payload,
        config.token.secret,
        TokenService.SIGN_OPTIONS,
        (error, encoded) => {
          if (error) reject(new TokenError(error.message));
          // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
          else resolve(encoded!);
        }
      );
    });
  }

  public verify(token: string): Promise<Token> {
    return new Promise((resolve, reject) => {
      jwt.verify(
        token,
        config.token.secret,
        TokenService.VERIFY_OPTIONS,
        (error, decoded) => {
          if (error) reject(new TokenError(error.message));
          // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
          else resolve(decoded! as Token);
        }
      );
    });
  }

  public decode(token: string): Token {
    const decoded = jwt.decode(token, { complete: true });
    const error = new TokenError('Error decoding token');

    if (
      !decoded || // 'null' or 'undefined'
      typeof decoded.payload === 'string' || // 'string' payload
      !Object.prototype.hasOwnProperty.call(decoded.payload, 'type') // No 'type' property
    ) {
      throw error;
    }

    switch (decoded.payload.type) {
      case TokenTypes.USER:
      case TokenTypes.NODE:
        return decoded as Token;
      default:
        throw error;
    }
  }
}
