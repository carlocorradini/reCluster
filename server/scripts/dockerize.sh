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
. "$DIRNAME/../../scripts/__commons.sh"

# ================
# CONFIGURATION
# ================
# reCluster server Dockerfile
RECLUSTER_SERVER_DOCKERFILE="$DIRNAME/../Dockerfile"
# reCluster server version
RECLUSTER_SERVER_VERSION=latest
# reCluster server image
RECLUSTER_SERVER_IMAGE="recluster-server:$RECLUSTER_SERVER_VERSION"

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--help]

$HELP_COMMONS_USAGE

reCluster Dockerize script.

Options:
  --help  Show this help message and exit

$HELP_COMMONS_OPTIONS
EOF
}

################################################################################################################################

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  while [ $# -gt 0 ]; do
    # Number of shift
    _shifts=1

    case $1 in
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      *)
        # Commons
        parse_args_commons "$@"
        _shifts=$RETVAL
        ;;
    esac

    # Shift arguments
    while [ "$_shifts" -gt 0 ]; do
      shift
      _shifts=$((_shifts = _shifts - 1))
    done
  done
}

# Verify system
verify_system() {
  assert_cmd docker
}

# Remove Docker image
docker_remove() {
  ! docker image inspect "$RECLUSTER_SERVER_IMAGE" > /dev/null 2>&1 || return 0

  INFO "Removing Docker image '$RECLUSTER_SERVER_IMAGE'"
  docker image rm --force "$RECLUSTER_SERVER_IMAGE" || FATAL "Error removing Docker image '$RECLUSTER_SERVER_IMAGE'"
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  docker_remove
  assert_docker_image "$RECLUSTER_SERVER_IMAGE" "$RECLUSTER_SERVER_DOCKERFILE" "$DIRNAME/.."
}
