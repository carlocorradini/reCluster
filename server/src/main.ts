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

import 'reflect-metadata';
import 'dotenv/config';
import 'json-bigint-patch';
import { ApolloServer } from 'apollo-server';
import { container } from 'tsyringe';
import { logger } from './logger';
import { contextHelper, formatErrorHelper } from './helpers';
import { config } from './config';
import { prisma } from './db';
import { schema } from './graphql';
import { kubeconfig, NodeInformer } from './k8s';

const server = new ApolloServer({
  schema,
  context: contextHelper,
  formatError: formatErrorHelper
});

async function main() {
  // Database
  try {
    await prisma.$connect();
    logger.info(`Database connected`);
  } catch (error) {
    logger.fatal(`Database error: ${error}`);
    throw error;
  }

  // K8s
  try {
    kubeconfig.loadFromDefault(); // Always first
    const nodeInformer = container.resolve(NodeInformer);
    // FIXME nodeInformer.start();
    logger.info('K8s configured');
  } catch (error) {
    logger.fatal(`K8s error: ${error}`);
    throw error;
  }

  // Server
  try {
    const serverInfo = await server.listen({
      port: config.server.port,
      host: config.server.host
    });
    logger.info(`Server started at ${serverInfo.url}`);
  } catch (error) {
    logger.fatal(`Server error: ${error}`);
    throw error;
  }
}

async function terminate(signal: NodeJS.Signals) {
  logger.warn(`Received '${signal}' signal`);

  // Database
  await prisma.$disconnect();
  // K8s
  await container.resolve(NodeInformer).stop();
  // Server
  await server.stop();

  process.kill(process.pid, signal);
}

process.once('SIGTERM', terminate);
process.once('SIGKILL', terminate);
process.once('SIGINT', terminate);
process.once('SIGQUIT', terminate);
process.once('SIGHUP', terminate);

main().catch((error: Error) => {
  logger.fatal(`Error starting: ${error.message}`);
  throw error;
});
