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
# Alpine Linux version
ALPINE_VERSION=3.16
# reCluster Alpine Linux image
RECLUSTER_ALPINE_IMAGE="recluster-alpine:$ALPINE_VERSION"
# reCluster Alpine Linux Dockerfile
RECLUSTER_ALPINE_DOCKERFILE="$DIRNAME/Dockerfile"
# mkimage profile
MKIMAGE_PROFILE=$(readlink -f "$DIRNAME/mkimg.recluster.sh")
# mkimage apkovl
MKIMAGE_APKOVL=$(readlink -f "$DIRNAME/genapkovl-recluster.sh")
# mkimage iso directory
MKIMAGE_ISO_DIR=$(readlink -f "$DIRNAME/iso")
# mkimage architectures
MKIMAGE_ARCHS='["x86_64"]'
# Container identifier
CONTAINER_ID=

# Load commons
. "$DIRNAME/../../../scripts/__commons.sh"

# Verify system
verify_system() {
  assert_cmd docker
  assert_cmd jq
  assert_cmd sed

  assert_docker_image "$RECLUSTER_ALPINE_IMAGE" "$RECLUSTER_ALPINE_DOCKERFILE"
}

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?

  # Docker container
  if [ -n "$CONTAINER_ID" ]; then
    docker stop "$CONTAINER_ID"
    docker rm "$CONTAINER_ID"
  fi

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

# ================
# FUNCTIONS
# ================
# ISO directory
iso_dir() {
  if [ -d "$MKIMAGE_ISO_DIR" ]; then
    WARN "Removing ISO directory '$MKIMAGE_ISO_DIR'"
    rm -rf "$MKIMAGE_ISO_DIR"
  else
    INFO "Creating ISO directory '$MKIMAGE_ISO_DIR'"
    mkdir "$MKIMAGE_ISO_DIR"
  fi
}

# Prepare reCluster container
prepare_container() {
  _profile_file_name=$(basename "$MKIMAGE_PROFILE")
  _apkovl_file_name=$(basename "$MKIMAGE_APKOVL")

  # Start container
  CONTAINER_ID=$(
    docker run \
      --volume "$MKIMAGE_PROFILE:/home/build/aports/scripts/$_profile_file_name" \
      --volume "$MKIMAGE_APKOVL:/home/build/aports/scripts/$_apkovl_file_name" \
      --volume "$MKIMAGE_ISO_DIR:/home/build/iso" \
      --detach \
      --interactive \
      --tty \
      "$RECLUSTER_ALPINE_IMAGE"
  )

  # Script permission
  docker exec "$CONTAINER_ID" chmod +x "/home/build/aports/scripts/$_profile_file_name"
}

# Build ISO image
# @param $1 Architecture
builder() {
  _arch=$1
  _profile_name=$(basename "$MKIMAGE_PROFILE" | sed -E 's/.*mkimg\.(.*)\.sh.*/\1/')

  INFO "Building '$_profile_name' architecture '$_arch'"

  docker exec "$CONTAINER_ID" \
    /home/build/aports/scripts/mkimage.sh \
    --tag "v$ALPINE_VERSION" \
    --outdir /home/build/iso \
    --arch "$_arch" \
    --repository "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main" \
    --repository "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" \
    --profile "$_profile_name"
}

# ================
# MAIN
# ================
{
  verify_system
  iso_dir
  prepare_container
  while read -r _arch; do
    builder "$_arch"
  done << EOF
$(echo "$MKIMAGE_ARCHS" | jq --compact-output --raw-output '.[]')
EOF
}
