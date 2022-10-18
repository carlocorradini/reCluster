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

import type * as Prisma from '@prisma/client';
import { Args, Mutation, Query, Resolver } from 'type-graphql';
import { inject, injectable } from 'tsyringe';
import { GraphQLJWT } from 'graphql-scalars';
import { UserService } from '~/services';
import { User } from '../../entities';
import {
  FindUniqueUserArgs,
  FindManyUserArgs,
  CreateUserArgs,
  SignInArgs
} from '../../args';

@Resolver(User)
@injectable()
export class UserResolver {
  public constructor(
    @inject(UserService)
    private readonly userService: UserService
  ) {}

  @Query(() => [User], { description: 'List of Users' })
  public users(@Args() args: FindManyUserArgs): Promise<Prisma.User[]> {
    return this.userService.findMany(args);
  }

  @Query(() => User, {
    nullable: true,
    description: 'User matching the identifier'
  })
  public user(@Args() args: FindUniqueUserArgs): Promise<Prisma.User | null> {
    return this.userService.findUnique(args);
  }

  @Mutation(() => User, { description: 'Create a new user' })
  public createUser(@Args() args: CreateUserArgs): Promise<Prisma.User> {
    return this.userService.create(args);
  }

  @Mutation(() => GraphQLJWT, { description: 'Sign in user' })
  public signIn(@Args() args: SignInArgs): Promise<string> {
    return this.userService.signIn(args);
  }
}
