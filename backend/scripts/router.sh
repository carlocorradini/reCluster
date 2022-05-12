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
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIRNAME
# Apollo Router version
readonly APOLLO_ROUTER_VERSION=v0.9.0-rc.0
# Apollo Router image
readonly APOLLO_ROUTER_IMAGE="ghcr.io/apollographql/router:$APOLLO_ROUTER_VERSION"
# Apollo Router config
APOLLO_ROUTER_CONFIG=$(readlink -f "$DIRNAME/../router/router.yaml")
readonly APOLLO_ROUTER_CONFIG
# Apollo Router supergraph
APOLLO_ROUTER_SUPERGRAPH=$(readlink -f "$DIRNAME/../router/supergraph.graphql")
readonly APOLLO_ROUTER_SUPERGRAPH

# Commons
source "$DIRNAME/../../scripts/__commons.sh"

# Assert
assert_cmd docker

# Apollo Router
INFO "Starting Apollo Router '$APOLLO_ROUTER_IMAGE': { config: '$APOLLO_ROUTER_CONFIG', supergraph: '$APOLLO_ROUTER_SUPERGRAPH' }"
docker run -p 4000:4000 \
  --mount "type=bind,source=$APOLLO_ROUTER_CONFIG,target=/dist/config/router.yaml" \
  --mount "type=bind,source=$APOLLO_ROUTER_SUPERGRAPH,target=/dist/config/supergraph.graphql" \
  --rm \
  $APOLLO_ROUTER_IMAGE \
  --config config/router.yaml \
  --supergraph config/supergraph.graphql
