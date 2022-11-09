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

import convert from 'convert';
import type pino from 'pino';
import type { Config } from '~/types';
import { env } from './env';

export const config: Config = {
  app: 'reCluster',
  node: {
    env: env.NODE_ENV
  },
  server: {
    host: env.HOST,
    port: env.PORT
  },
  logger: {
    level: env.LOGGER_LEVEL as pino.LevelWithSilent
  },
  database: {
    url: env.DATABASE_URL
  },
  ssh: {
    username: env.SSH_USERNAME,
    passphrase: env.SSH_PASSPHRASE,
    privateKey: env.SSH_PRIVATE_KEY
  },
  token: {
    algorithm: 'RS256',
    expiration: convert(365, 'd').to('s'),
    passphrase: env.TOKEN_PASSPHRASE,
    privateKey: env.TOKEN_PRIVATE_KEY,
    publicKey: env.TOKEN_PUBLIC_KEY
  },
  graphql: { path: '/graphql' },
  k8s: {
    label: { node: { id: 'recluster.io/id' } }
  },
  user: {
    maxUsernameLength: 64,
    maxPasswordLength: 16
  },
  nodePool: { controller: { name: 'controllers' } }
};
