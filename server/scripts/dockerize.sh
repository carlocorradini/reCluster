#!/usr/bin/env sh
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
# Current directory
# shellcheck disable=SC1007
DIRNAME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# reCluster server Dockerfile
RECLUSTER_SERVER_DOCKERFILE="$DIRNAME/../Dockerfile"
# reCluster server version
RECLUSTER_SERVER_VERSION=latest
# reCluster server image
RECLUSTER_SERVER_IMAGE="recluster-server:$RECLUSTER_SERVER_VERSION"

# Load commons
. "$DIRNAME/../../scripts/__commons.sh"

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd docker
}

# ================
# MAIN
# ================
{
  verify_system
  INFO "Building reCluster server Docker image '$RECLUSTER_SERVER_IMAGE' using Dockerfile '$RECLUSTER_SERVER_DOCKERFILE'"
  docker build --rm -t "$RECLUSTER_SERVER_IMAGE" -f "$RECLUSTER_SERVER_DOCKERFILE" "$DIRNAME/.."
}
