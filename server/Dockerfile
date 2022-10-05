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
COPY .npmrc ./
COPY tsconfig.json ./
COPY prisma ./prisma
# Copy source files
COPY src ./src

# Install development dependencies
RUN npm ci --development

# Build
RUN npm run build

# ================
# PRODUCTION
# ================
FROM node:$NODEJS_VERSION-alpine

# Author
LABEL org.opencontainers.image.authors="Carlo Corradini <carlo.corradini98@gmail.com>"

# Environment
ENV NODE_ENV production
ENV PORT $PORT

# Working directory
ARG WORKDIR
WORKDIR $WORKDIR

# Install packages
RUN apk add --no-cache dumb-init

# Change user
USER node

# Copy package.json and package-lock.json
COPY --from=builder --chown=node:node $WORKDIR/package.json $WORKDIR/package-lock.json ./
# Copy build files
COPY --from=builder --chown=node:node $WORKDIR/build ./

# Install production dependencies
RUN npm ci --production --ignore-scripts

# Copy prisma
COPY --from=builder --chown=node:node $WORKDIR/node_modules/.prisma $WORKDIR/node_modules/.prisma

# Expose
EXPOSE $PORT

# Bootstrap
CMD [ "dumb-init", "node", "main.js" ]
