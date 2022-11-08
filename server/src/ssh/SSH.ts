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

import { NodeSSH, SSHExecOptions, SSHExecCommandOptions } from 'node-ssh';
import { config } from '~/config';

type Exec = {
  disconnect?: boolean;
};

type ConnectArgs = { host: string; username?: string };

type ExecArgs = Exec & {
  command: string;
  parameters?: string[];
  options?: SSHExecOptions & {
    stream?: 'stdout' | 'stderr';
  };
};

type ExecCommandArgs = Exec & {
  command: string;
  options?: SSHExecCommandOptions;
};

export class SSH {
  private readonly ssh: NodeSSH;

  private constructor() {
    this.ssh = new NodeSSH();
  }

  public static async connect(args: ConnectArgs) {
    const instance = new SSH();

    await instance.ssh.connect({
      host: args.host,
      username: args.username ?? config.ssh.username,
      privateKey: config.ssh.privateKey,
      passphrase: config.ssh.passphrase
    });

    return instance;
  }

  public disconnect() {
    this.ssh.dispose();
  }

  public async exec(args: ExecArgs) {
    const result = await this.ssh.exec(
      args.command,
      args.parameters ?? [],
      args.options
    );

    if (args.disconnect) await this.disconnect();

    return result;
  }

  public async execCommand(args: ExecCommandArgs) {
    const result = await this.ssh.execCommand(args.command, args.options);

    if (args.disconnect) await this.disconnect();

    return result;
  }
}
