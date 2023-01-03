#!/usr/bin/env ts-node

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

import 'reflect-metadata';
import 'json-bigint-patch';
import 'dotenv/config';
import yargs from 'yargs';
import pino from 'pino';
import { lexicographicSortSchema } from 'graphql';
import { printSchemaWithDirectives } from '@graphql-tools/utils';
import { outputFileSync } from 'type-graphql/dist/helpers/filesystem';
import { schema } from '../src/graphql';

const logger = pino({ level: 'debug', name: 'graphql-schema' });

const GRAPHQL_SCHEMA = 'schema.graphql';

// Arguments
const argv = yargs(process.argv.slice(2))
  .options({
    output: {
      type: 'string',
      default: GRAPHQL_SCHEMA,
      description: 'Output path'
    }
  })
  .help()
  .parseSync();

// Generate schema string
logger.debug('Generating GraphQL schema string');
const schemaString = printSchemaWithDirectives(lexicographicSortSchema(schema));

// Save schema
logger.info(`Saving GraphQL schema to '${argv.output}'`);
outputFileSync(argv.output, schemaString);
