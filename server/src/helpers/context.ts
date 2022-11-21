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

import { container } from 'tsyringe';
import type { ApolloFastifyContextFunction } from '@as-integrations/fastify';
import type { Context, TokenPayload } from '~/types';
import { TokenService } from '~/services';
import { AuthenticationError } from '~/errors';

export const context: ApolloFastifyContextFunction<Context> = async ({
  ip,
  headers
}): Promise<Context> => {
  let applicant: TokenPayload | undefined;
  const authorizationHeader =
    headers && 'Authorization' in headers ? 'Authorization' : 'authorization';

  if (headers && headers[authorizationHeader]) {
    const parts = (headers[authorizationHeader] as string).split(' ');

    if (parts.length === 2) {
      const scheme = parts[0];
      const credentials = parts[1];

      if (/^Bearer$/i.test(scheme)) {
        const token = credentials;
        const tokenService = container.resolve(TokenService);

        try {
          const decodedToken = await tokenService.verify(token);
          applicant = decodedToken.payload;
        } catch (error) {
          throw new AuthenticationError(
            error instanceof Error ? error.message : `${error}`
          );
        }
      }
    } else {
      throw new AuthenticationError(
        "Token format is 'Authorization: Bearer [token]'"
      );
    }
  }

  return { ip, applicant };
};
