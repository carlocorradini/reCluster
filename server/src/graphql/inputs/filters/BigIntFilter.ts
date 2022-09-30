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

import { GraphQLBigInt } from 'graphql-scalars';
import { Field, InputType } from 'type-graphql';
import { Prisma } from '@prisma/client';

@InputType({ isAbstract: true, description: 'BigInt filter' })
export class BigIntFilter implements Prisma.BigIntFilter {
  @Field(() => GraphQLBigInt, { nullable: true, description: 'BigInt equals' })
  equals?: bigint;

  @Field({ nullable: true, description: 'BigInt not equals' })
  not?: BigIntFilter;

  @Field(() => [GraphQLBigInt], {
    nullable: true,
    description: 'BigInt exists in list'
  })
  in?: bigint[];

  @Field(() => [GraphQLBigInt], {
    nullable: true,
    description: 'BigInt does not exists in list'
  })
  notIn?: bigint[];

  @Field(() => GraphQLBigInt, {
    nullable: true,
    description: 'BigInt is less than'
  })
  lt?: bigint;

  @Field(() => GraphQLBigInt, {
    nullable: true,
    description: 'BigInt is less than or equal to'
  })
  lte?: bigint;

  @Field(() => GraphQLBigInt, {
    nullable: true,
    description: 'BigInt is greater than'
  })
  gt?: bigint;

  @Field(() => GraphQLBigInt, {
    nullable: true,
    description: 'BigInt is greater than or equal to'
  })
  gte?: bigint;
}
