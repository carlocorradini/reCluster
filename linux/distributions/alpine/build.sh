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

# ================
# CONFIGURATION
# ================
# Current directory
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIRNAME
# Alpine Linux version
readonly ALPINE_VERSION="3.16"
# reCluster Alpine Linux image
readonly RECLUSTER_ALPINE_IMAGE="recluster-alpine:$ALPINE_VERSION"
# reCluster Alpine Linux Dockerfile
readonly RECLUSTER_ALPINE_DOCKERFILE="$DIRNAME/Dockerfile"
# mkimage profile
MKIMAGE_PROFILE=$(readlink -f "$DIRNAME/mkimg.recluster.sh")
readonly MKIMAGE_PROFILE
# mkimage apkovl
MKIMAGE_APKOVL=$(readlink -f "$DIRNAME/genapkovl-recluster.sh")
readonly MKIMAGE_APKOVL
# mkimage iso directory
MKIMAGE_ISO_DIR=$(readlink -f "$DIRNAME/iso")
readonly MKIMAGE_ISO_DIR
# mkimage architectures
MKIMAGE_ARCHS=("x86_64")
# Container identifier
CONTAINER=

# Commons
source "$DIRNAME/../../../scripts/__commons.sh"

# Assert
assert_cmd docker
assert_docker_image "$RECLUSTER_ALPINE_IMAGE" "$RECLUSTER_ALPINE_DOCKERFILE"

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?

  # Docker container
  if [ -n "$CONTAINER" ]; then
    docker stop "$CONTAINER"
    docker rm "$CONTAINER"
  fi

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

# ================
# FUNCTIONS
# ================
# ISO directory
function iso_dir() {
  if [ -d "$MKIMAGE_ISO_DIR" ]; then
    WARN "Removing ISO directory '$MKIMAGE_ISO_DIR'"
    rm -rf "$MKIMAGE_ISO_DIR"
  else
    INFO "Creating ISO directory '$MKIMAGE_ISO_DIR'"
    mkdir "$MKIMAGE_ISO_DIR"
  fi
}

# Prepare reCluster container
function prepare_container() {
  local profile_file_name
  local apkovl_file_name
  profile_file_name=$(basename "$MKIMAGE_PROFILE")
  apkovl_file_name=$(basename "$MKIMAGE_APKOVL")

  # Start container
  CONTAINER=$(
    docker run \
      --volume "$MKIMAGE_PROFILE:/home/build/aports/scripts/$profile_file_name" \
      --volume "$MKIMAGE_APKOVL:/home/build/aports/scripts/$apkovl_file_name" \
      --volume "$MKIMAGE_ISO_DIR:/home/build/iso" \
      --detach \
      --interactive \
      --tty \
      "$RECLUSTER_ALPINE_IMAGE"
  )

  # Script permission
  docker exec "$CONTAINER" chmod +x "/home/build/aports/scripts/$profile_file_name"
}

# Build ISO image
function builder() {
  local arch
  local profile_name
  arch=$1
  profile_name=$(basename "$MKIMAGE_PROFILE" | sed -E 's/.*mkimg\.(.*)\.sh.*/\1/')

  INFO "Building '$profile_name' architecture '$arch'"

  docker exec "$CONTAINER" \
    /home/build/aports/scripts/mkimage.sh \
    --tag "v$ALPINE_VERSION" \
    --outdir /home/build/iso \
    --arch "$arch" \
    --repository "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main" \
    --repository "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" \
    --profile "$profile_name"
}

# ================
# MAIN
# ================
{
  iso_dir
  prepare_container
  for arch in "${MKIMAGE_ARCHS[@]}"; do
    builder "$arch"
  done
}
