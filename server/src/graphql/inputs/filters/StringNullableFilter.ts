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
import { GraphQLString } from 'graphql';
import { Field, InputType } from 'type-graphql';
import { QueryModeCaseSensitivity } from '../../enums';

@InputType({ isAbstract: true, description: 'SNested string nullable filter' })
export class NestedStringNullableFilter
  implements Prisma.NestedStringNullableFilter
{
  @Field(() => GraphQLString, { nullable: true, description: 'String equals' })
  equals?: string | null;

  @Field({ nullable: true, description: 'String not equals' })
  not?: NestedStringNullableFilter;

  @Field(() => [GraphQLString], {
    nullable: true,
    description: 'String exists in list'
  })
  in?: string[] | null;

  @Field(() => [GraphQLString], {
    nullable: true,
    description: 'String does not exists in list'
  })
  notIn?: string[] | null;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String is less than'
  })
  lt?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String is less than or equal to'
  })
  lte?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String is greater than'
  })
  gt?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String is greater than or equal to'
  })
  gte?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String contains'
  })
  contains?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String starts with'
  })
  startsWith?: string;

  @Field(() => GraphQLString, {
    nullable: true,
    description: 'String ends with'
  })
  endsWith?: string;
}

@InputType({ isAbstract: true, description: 'String nullable filter' })
export class StringNullableFilter
  extends NestedStringNullableFilter
  implements Prisma.StringNullableFilter
{
  @Field(() => QueryModeCaseSensitivity, {
    nullable: true,
    description: 'Case sensitivity'
  })
  mode?: QueryModeCaseSensitivity;
}
