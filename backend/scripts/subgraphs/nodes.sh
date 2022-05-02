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
# Subgraph nodes version
readonly SUBGRAPH_NODES_VERSION="latest"
# Subgraph nodes image
readonly SUBGRAPH_NODES_IMAGE="recluster/subgraphs/nodes:$SUBGRAPH_NODES_VERSION"
# Subgraph nodes Dockerfile
SUBGRAPH_NODES_DOCKERFILE=$(readlink -f "$DIRNAME/../../docker/subgraphs/Dockerfile.nodes")
readonly SUBGRAPH_NODES_DOCKERFILE
# Database
readonly DATABASE_URL="postgresql://recluster:password@localhost:5432/recluster?schema=public"

# Commons
source "$DIRNAME/../../../scripts/__commons.sh"

# Assert
assert_cmd docker
assert_docker_image "$SUBGRAPH_NODES_IMAGE" "$SUBGRAPH_NODES_DOCKERFILE"

# Subgraph nodes
INFO "Starting subgraph nodes '$SUBGRAPH_NODES_IMAGE'"
docker run \
  -p 80:8000 \
  -e "DATABASE_URL=$DATABASE_URL" \
  --rm \
  "$SUBGRAPH_NODES_IMAGE"
