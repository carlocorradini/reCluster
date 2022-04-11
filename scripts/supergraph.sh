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
DIRNAME=$(dirname "${BASH_SOURCE[0]}")
readonly DIRNAME
# Apollo Rover version
readonly APOLLO_ROVER_VERSION="latest"
# Apollo Rover image
readonly APOLLO_ROVER_IMAGE="recluster/router:$APOLLO_ROVER_VERSION"
# Apollo Rover Dockerfile
APOLLO_ROVER_DOCKERFILE=$(readlink -f "$DIRNAME/../docker/Dockerfile.rover")
readonly APOLLO_ROVER_DOCKERFILE
# Supergraph input
SUPERGRAPH_INPUT=$(readlink -f "$DIRNAME/../router/supergraph.yaml")
readonly SUPERGRAPH_INPUT
# Supergraph output
SUPERGRAPH_OUTPUT=$(readlink -f "$DIRNAME/../router/supergraph.graphql")
readonly SUPERGRAPH_OUTPUT

# Commons
source "$DIRNAME/__commons.sh"

# Assert
assert_tool docker
assert_docker_image "$APOLLO_ROVER_IMAGE" "$APOLLO_ROVER_DOCKERFILE"

# Generate supergraph
INFO "Generating supergraph from '$SUPERGRAPH_INPUT'"
SUPERGRAPH=$(docker run \
    --mount "type=bind,source=$SUPERGRAPH_INPUT,target=/root/supergraph.yaml" \
    --rm \
    $APOLLO_ROVER_IMAGE \
    supergraph compose --config /root/supergraph.yaml)
readonly SUPERGRAPH

# Save supergraph
INFO "Saving supergraph in '$SUPERGRAPH_OUTPUT'"
printf "%s" "$SUPERGRAPH" > "$SUPERGRAPH_OUTPUT"
