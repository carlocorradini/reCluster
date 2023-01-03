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

import type { GraphQLFormattedError } from 'graphql';
import { ArgumentValidationError } from 'type-graphql';
import { Prisma } from '@prisma/client';
import { unwrapResolverError } from '@apollo/server/errors';
import { logger } from '~/logger';
import { DatabaseError, ValidationError } from '~/errors';

export function formatError(
  formattedError: GraphQLFormattedError,
  error: unknown
): GraphQLFormattedError {
  const originalError = unwrapResolverError(error);

  // Log
  logger.error(
    `Server error: ${
      originalError instanceof Error ? originalError.message : originalError
    }`
  );

  // Database
  if (
    originalError instanceof Prisma.PrismaClientKnownRequestError ||
    originalError instanceof Prisma.PrismaClientUnknownRequestError ||
    originalError instanceof Prisma.PrismaClientRustPanicError ||
    originalError instanceof Prisma.PrismaClientInitializationError ||
    originalError instanceof Prisma.PrismaClientValidationError
  ) {
    // TODO When PrismaClientRustPanicError occurs restart Node process
    return new DatabaseError(
      originalError instanceof Prisma.PrismaClientKnownRequestError
        ? originalError.code
        : undefined
    );
  }

  // Validation
  if (originalError instanceof ArgumentValidationError) {
    return new ValidationError(originalError.validationErrors);
  }

  // Generic
  return formattedError;
}
