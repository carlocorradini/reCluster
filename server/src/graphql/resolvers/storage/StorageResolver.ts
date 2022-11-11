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

import {
  Arg,
  Args,
  FieldResolver,
  Query,
  Resolver,
  ResolverInterface,
  Root
} from 'type-graphql';
import { inject, injectable } from 'tsyringe';
import { GraphQLBigInt } from 'graphql-scalars';
import { convert } from 'convert';
import { StorageService } from '~/services';
import { DigitalUnitEnum } from '../../enums';
import { Storage } from '../../entities';
import { FindUniqueStorageArgs, FindManyStorageArgs } from '../../args';

@Resolver(Storage)
@injectable()
export class StorageResolver implements ResolverInterface<Storage> {
  public constructor(
    @inject(StorageService)
    private readonly storageService: StorageService
  ) {}

  @Query(() => [Storage], { description: 'List of Storages' })
  public storages(@Args() args: FindManyStorageArgs) {
    return this.storageService.findMany(args);
  }

  @Query(() => Storage, {
    nullable: true,
    description: 'Storage matching the identifier'
  })
  public storage(@Args() args: FindUniqueStorageArgs) {
    return this.storageService.findUnique({ where: { id: args.id } });
  }

  @FieldResolver(() => GraphQLBigInt)
  public size(
    @Root() storage: Storage,
    @Arg('unit', () => DigitalUnitEnum, {
      defaultValue: DigitalUnitEnum.B,
      description: 'Digital conversion unit'
    })
    unit: DigitalUnitEnum
  ) {
    return convert(storage.size, DigitalUnitEnum.B).to(unit);
  }
}
