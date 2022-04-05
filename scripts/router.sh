#!/usr/bin/env bash
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



# Current directory
DIRNAME="$(dirname "$(readlink -f "$0")")"
readonly DIRNAME
# Apollo Router version
readonly APOLLO_ROUTER_VERSION="v0.1.0-preview.2"

# Commons
source "$DIRNAME/__commons.sh"

# Assert
assert_tool docker

# Apollo Router
INFO "Starting Apollo Router $APOLLO_ROUTER_VERSION"
docker run \
  -p 4000:4000 \
  --mount "type=bind,source=$DIRNAME/../router/router.yaml,target=/dist/config/router.yaml" \
  --mount "type=bind,source=$DIRNAME/../router/supergraph.graphql,target=/dist/config/supergraph.graphql" \
  --rm \
  "ghcr.io/apollographql/router:$APOLLO_ROUTER_VERSION" \
  --config config/router.yaml \
  --supergraph config/supergraph.graphql
