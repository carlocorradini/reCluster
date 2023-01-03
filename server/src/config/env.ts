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

import fs from 'node:fs';
import { host, port, str, url, cleanEnv, makeValidator } from 'envalid';

const fileValidator = makeValidator((file) => {
  return fs.readFileSync(file, { encoding: 'utf8', flag: 'r' });
});

export const env = cleanEnv(process.env, {
  NODE_ENV: str({
    choices: ['development', 'production', 'test'],
    default: 'production',
    desc: 'Node environment'
  }),
  HOST: host({ default: '0.0.0.0', desc: 'Server host' }),
  PORT: port({ default: 80, desc: 'Server port' }),
  LOGGER_LEVEL: str({
    choices: ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'],
    default: 'info',
    devDefault: 'debug',
    desc: 'Logger level'
  }),
  DATABASE_URL: url({ desc: 'Database URL' }),
  SSH_USERNAME: str({ default: 'root', desc: 'SSH username' }),
  SSH_PRIVATE_KEY: fileValidator({ desc: 'SSH private key' }),
  SSH_PASSPHRASE: str({ default: '', desc: 'SSH passphrase' }),
  TOKEN_PRIVATE_KEY: fileValidator({ desc: 'Token private key' }),
  TOKEN_PUBLIC_KEY: fileValidator({ desc: 'Token public key' }),
  TOKEN_PASSPHRASE: str({ default: '', desc: 'Token passphrase' })
});
