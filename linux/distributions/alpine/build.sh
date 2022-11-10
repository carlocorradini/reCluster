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
# Docker image
DOCKER_IMAGE="recluster-alpine:latest"
# Dockerfile
DOCKERFILE="$DIRNAME/Dockerfile"
# ISO directory
ISO_DIR=$(readlink -f "$DIRNAME/iso")
# Architectures
ARCHS='["x86_64"]'
# Alpine version
ALPINE_VERSION=3.16
# Alpine profile file
ALPINE_PROFILE_FILE=$(readlink -f "$DIRNAME/mkimg.recluster.sh")
# Alpine apkovl file
ALPINE_APKOVL_FILE=$(readlink -f "$DIRNAME/genapkovl-recluster.sh")

# ================
# GLOBALS
# ================
# Container identifier
CONTAINER_ID=

# Load commons
. "$DIRNAME/../../../scripts/__commons.sh"

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Remove iso directory
  if [ -n "$ISO_DIR" ] && [ -d "$ISO_DIR" ] && [ $_exit_code -ne 0 ]; then
    DEBUG "Removing ISO directory '$ISO_DIR'"
    rm -rf "$ISO_DIR"
    ISO_DIR=
  fi

  # Destroy Docker container
  destroy_docker_container "$CONTAINER_ID"

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd docker
  assert_cmd jq
  assert_cmd sed

  assert_docker_image "$DOCKER_IMAGE" "$DOCKERFILE"
}

# Prepare container
prepare_container() {
  _profile_file_name=$(basename "$ALPINE_PROFILE_FILE")
  _apkovl_file_name=$(basename "$ALPINE_APKOVL_FILE")

  # Start container
  CONTAINER_ID=$(
    docker run \
      --volume "$ALPINE_PROFILE_FILE:/home/build/aports/scripts/$_profile_file_name" \
      --volume "$ALPINE_APKOVL_FILE:/home/build/aports/scripts/$_apkovl_file_name" \
      --volume "$ISO_DIR:/home/build/iso" \
      --rm \
      --detach \
      --interactive \
      --tty \
      "$DOCKER_IMAGE"
  )

  # Script permission
  docker exec "$CONTAINER_ID" chmod +x "/home/build/aports/scripts/$_profile_file_name"
}

# Build ISO image
# @param $1 Architecture
builder() {
  _arch=$1
  _profile_name=$(basename "$ALPINE_PROFILE_FILE" | sed -E 's/.*mkimg\.(.*)\.sh.*/\1/')

  INFO "Building Alpine Linux architecture '$_arch'"

  docker exec "$CONTAINER_ID" \
    /home/build/aports/scripts/mkimage.sh \
    --tag "v$ALPINE_VERSION" \
    --outdir /home/build/iso \
    --arch "$_arch" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" \
    --profile "$_profile_name"
}

# ================
# MAIN
# ================
{
  verify_system
  recreate_dir "$ISO_DIR"
  prepare_container
  while read -r _arch; do
    builder "$_arch"
  done << EOF
$(echo "$ARCHS" | jq --compact-output --raw-output '.[]')
EOF
}
