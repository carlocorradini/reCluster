# MIT License
#
# Copyright (c) 2022-2022 Carlo Corradini
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ================
# CONFIGURATION
# ================
# Node.js version
ARG NODEJS_VERSION=16
# Working directory
ARG WORKDIR=/usr/app
# Port
ARG PORT=80

# ================
# BUILDER
# ================
FROM node:$NODEJS_VERSION-alpine AS builder

# Working directory
ARG WORKDIR
WORKDIR $WORKDIR

# Copy build files
COPY package.json package-lock.json ./
COPY .npmrc .
COPY tsconfig.json .
COPY schema.prisma .
# Copy source files
COPY src ./src

# Install development dependencies
RUN npm ci --development --ignore-scripts

# Generate prisma
RUN npm run db:generate

# Build
RUN npm run build

# ================
# PRODUCTION
# ================
FROM node:$NODEJS_VERSION-alpine

# Author
LABEL org.opencontainers.image.authors="Carlo Corradini <carlo.corradini98@gmail.com>"

# Working directory
ARG WORKDIR
WORKDIR $WORKDIR

# Copy package.json and package-lock.json
COPY --from=builder $WORKDIR/package.json $WORKDIR/package-lock.json ./
# Copy build files
COPY --from=builder $WORKDIR/build ./

# Install production dependencies
RUN npm ci --production --ignore-scripts

# Copy prisma
COPY --from=builder $WORKDIR/node_modules/.prisma $WORKDIR/node_modules/.prisma

# Expose
EXPOSE $PORT

# Bootstrap
CMD [ "node", "main.js" ]
