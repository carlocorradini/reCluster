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

/**
 * Expand T recursively
 */
export type ExpandRecursively<T> = T extends object
  ? T extends infer O
    ? { [K in keyof O]: ExpandRecursively<O[K]> }
    : never
  : T;

/**
 * Required keys of T
 */
export type RequiredKeys<T> = {
  [K in keyof T]-?: Record<string, never> extends { [P in K]: T[K] }
    ? never
    : K;
}[keyof T];

/**
 * Optional keys of T
 */
export type OptionalKeys<T> = {
  [K in keyof T]-?: Record<string, never> extends { [P in K]: T[K] }
    ? K
    : never;
}[keyof T];

/**
 * Required properties of T
 */
export type PickRequired<T> = Pick<T, RequiredKeys<T>>;

/**
 * Optional properties of T
 */
export type PickOptional<T> = Pick<T, OptionalKeys<T>>;

/**
 * Properties of T can be null
 */
export type Nullable<T> = { [P in keyof T]: T[P] | null };

/**
 * Properties and nested properties of T can be null
 */
export type NullableRecursive<T> = ExpandRecursively<Nullable<T>>;

/**
 * Properties and nested properties of T can not be null
 */
export type NonNullableRecursive<T> = ExpandRecursively<NonNullable<T>>;

/**
 * Optional properties of T can be null
 */
export type NullableOptional<T> = PickRequired<T> & Nullable<PickOptional<T>>;

/**
 * Properties and nested properties of T are optional
 */
export type PartialRecursive<T> = ExpandRecursively<Partial<T>>;

/**
 * Find many args of T
 */
export type FindManyArgs<T> = Omit<T, 'select' | 'include' | 'distinct'> & {
  cursor?: string;
};
