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

import { GraphQLID } from 'graphql';
import { Field, InputType } from 'type-graphql';
import { GraphQLNonEmptyString } from 'graphql-scalars';
import { IsStrongPassword, MaxLength, ArrayUnique } from 'class-validator';
import type { UpdateUserInput as IUpdateUserInput } from '~/types';
import { UserPermissionEnum, UserRoleEnum } from '~/db';
import { config } from '~/config';
import { Auth } from '~/helpers';

@InputType({ description: 'Update User input' })
export class UpdateUserInput implements IUpdateUserInput {
  @Field(() => GraphQLID, { nullable: true, description: 'User identifier' })
  @Auth({ roles: UserRoleEnum.ADMIN })
  id?: string;

  @Field(() => GraphQLNonEmptyString, {
    nullable: true,
    description: 'User password'
  })
  @MaxLength(config.user.password.validation.maxLength)
  @IsStrongPassword({
    minLength: config.user.password.validation.minLength,
    minLowercase: config.user.password.validation.minLowercase,
    minUppercase: config.user.password.validation.minUppercase,
    minNumbers: config.user.password.validation.minNumbers,
    minSymbols: config.user.password.validation.minSymbols
  })
  password?: string;

  @Field(() => [UserRoleEnum], { nullable: true, description: 'User roles' })
  @ArrayUnique()
  @Auth({ roles: UserRoleEnum.ADMIN })
  roles?: UserRoleEnum[];

  @Field(() => [UserPermissionEnum], {
    nullable: true,
    description: 'User permissions'
  })
  @ArrayUnique()
  @Auth({ roles: UserRoleEnum.ADMIN })
  permissions?: UserPermissionEnum[];
}
