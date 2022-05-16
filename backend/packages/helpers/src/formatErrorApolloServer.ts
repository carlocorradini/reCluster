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

import { GraphQLError } from 'graphql';
import { ArgumentValidationError } from 'type-graphql';
import { Prisma } from '@prisma/client';
import { DatabaseError, ValidationError } from '@recluster/errors';

export function formatErrorApolloServer(error: GraphQLError) {
  // Database
  if (
    error.originalError instanceof Prisma.PrismaClientKnownRequestError ||
    error.originalError instanceof Prisma.PrismaClientUnknownRequestError ||
    error.originalError instanceof Prisma.PrismaClientRustPanicError ||
    error.originalError instanceof Prisma.PrismaClientInitializationError ||
    error.originalError instanceof Prisma.PrismaClientValidationError
  ) {
    // TODO When PrismaClientRustPanicError occurs restart Node process
    return new DatabaseError(
      error.originalError instanceof Prisma.PrismaClientKnownRequestError
        ? error.originalError.code
        : undefined
    );
  }

  // Validation
  if (error.originalError instanceof ArgumentValidationError) {
    return new ValidationError(error.originalError.validationErrors);
  }

  // Generic
  return error;
}
