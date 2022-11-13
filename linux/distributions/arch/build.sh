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

# Current directory
# shellcheck disable=SC1007
DIRNAME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Load commons
. "$DIRNAME/../../../scripts/__commons.sh"

# ================
# CONFIGURATION
# ================
# Docker image
DOCKER_IMAGE="recluster-arch:latest"
# Dockerfile
DOCKERFILE="$DIRNAME/Dockerfile"
# ISO directory
ISO_DIR=$(readlink -f "$DIRNAME/iso")
# Architectures
ARCHS='["x86_64"]'
# Arch profile file
ARCH_PROFILE_FILE=$(readlink -f "$DIRNAME/profiledef.sh")
# Arch packages file
ARCH_PACKAGES_FILE=$(readlink -f "$DIRNAME/packages.x86_64")

# ================
# GLOBALS
# ================
# Container identifier
CONTAINER_ID=

# ================
# CLEANUP
# ================
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Cleanup iso directory
  [ $_exit_code = 0 ] || cleanup_dir "$ISO_DIR"
  # Cleanup Docker container
  cleanup_docker_container "$CONTAINER_ID"

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd docker
  assert_cmd jq

  assert_docker_image "$DOCKER_IMAGE" "$DOCKERFILE"
}

# Prepare container
prepare_container() {
  # Start container
  CONTAINER_ID=$(
    docker run \
      --volume "$ISO_DIR:/tmp/recluster/out" \
      --volume "$ARCH_PROFILE_FILE:/tmp/recluster/profile/profiledef.sh" \
      --volume "$ARCH_PACKAGES_FILE:/tmp/recluster/profile/packages.x86_64" \
      --rm \
      --detach \
      --interactive \
      --tty \
      --privileged \
      "$DOCKER_IMAGE"
  )
}

# Build ISO image
# @param $1 Architecture
builder() {
  _arch=$1

  INFO "Building Arch Linux architecture '$_arch'"

  docker exec "$CONTAINER_ID" \
    mkarchiso \
    -v \
    -w /tmp/recluster/work \
    -o /tmp/recluster/out \
    /tmp/recluster/profile
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
