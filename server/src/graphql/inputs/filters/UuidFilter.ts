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

/* eslint-disable max-classes-per-file */

import type { Prisma } from '@prisma/client';
import { Field, InputType } from 'type-graphql';
import { GraphQLUUID } from 'graphql-scalars';
import { QueryModeCaseSensitivity } from '../../enums';

@InputType({ isAbstract: true, description: 'Nested UUID filter' })
class NestedUuidFilter implements Prisma.NestedUuidFilter {
  @Field(() => GraphQLUUID, { nullable: true, description: 'UUID equals' })
  equals?: string;

  @Field(() => NestedUuidFilter, {
    nullable: true,
    description: 'UUID not equals'
  })
  not?: NestedUuidFilter;

  @Field(() => [GraphQLUUID], {
    nullable: true,
    description: 'UUID exists in list'
  })
  in?: string[];

  @Field(() => [GraphQLUUID], {
    nullable: true,
    description: 'UUID does not exists in list'
  })
  notIn?: string[];

  @Field(() => GraphQLUUID, {
    nullable: true,
    description: 'UUID is less than'
  })
  lt?: string;

  @Field(() => GraphQLUUID, {
    nullable: true,
    description: 'UUID is less than or equal to'
  })
  lte?: string;

  @Field(() => GraphQLUUID, {
    nullable: true,
    description: 'UUID is greater than'
  })
  gt?: string;

  @Field(() => GraphQLUUID, {
    nullable: true,
    description: 'UUID is greater than or equal to'
  })
  gte?: string;
}

@InputType({ isAbstract: true, description: 'UUID filter' })
export class UuidFilter extends NestedUuidFilter implements Prisma.UuidFilter {
  @Field(() => QueryModeCaseSensitivity, {
    nullable: true,
    description: 'Case sensitivity'
  })
  mode?: QueryModeCaseSensitivity;
}
