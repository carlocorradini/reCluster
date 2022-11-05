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

# Fail on error
set -o errexit
# Disable wildcard character expansion
set -o noglob

# ================
# LOGGER
# ================
# Fatal log level. Cause exit failure
LOG_LEVEL_FATAL=100
# Error log level
LOG_LEVEL_ERROR=200
# Warning log level
LOG_LEVEL_WARN=300
# Informational log level
LOG_LEVEL_INFO=500
# Debug log level
LOG_LEVEL_DEBUG=600
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Log color flag
LOG_COLOR_ENABLE=true

# Check if log level is enabled
# @param $1 Log level
is_log_level_enabled() {
  if [ "$1" -le "$LOG_LEVEL" ]; then
    # Enabled
    return 0
  else
    # Disabled
    return 1
  fi
}

# Print log message
# @param $1 Log level
# @param $2 Message
_log_print_message() {
  _log_level=${1:-LOG_LEVEL_FATAL}
  shift
  _log_level_name=
  _log_message=${*:-}
  _log_prefix=
  _log_suffix="\033[0m"

  # Check log level
  is_log_level_enabled "$_log_level" || return 0

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_level_name=FATAL
      _log_prefix="\033[41;37m"
      ;;
    "$LOG_LEVEL_ERROR")
      _log_level_name=ERROR
      _log_prefix="\033[1;31m"
      ;;
    "$LOG_LEVEL_WARN")
      _log_level_name=WARN
      _log_prefix="\033[1;33m"
      ;;
    "$LOG_LEVEL_INFO")
      _log_level_name=INFO
      _log_prefix="\033[37m"
      ;;
    "$LOG_LEVEL_DEBUG")
      _log_level_name=DEBUG
      _log_prefix="\033[1;34m"
      ;;
  esac

  # Check color flag
  if [ "$LOG_COLOR_ENABLE" = false ]; then
    _log_prefix=
    _log_suffix=
  fi

  # Log
  printf '%b[%-5s] %b%b\n' "$_log_prefix" "$_log_level_name" "$_log_message" "$_log_suffix"
}

# Fatal log message
# @param $1 Message
FATAL() {
  _log_print_message "$LOG_LEVEL_FATAL" "$1" >&2
  exit 1
}
# Error log message
# @param $1 Message
ERROR() { _log_print_message "$LOG_LEVEL_ERROR" "$1" >&2; }
# Warning log message
# @param $1 Message
WARN() { _log_print_message "$LOG_LEVEL_WARN" "$1" >&2; }
# Informational log message
# @param $1 Message
INFO() { _log_print_message "$LOG_LEVEL_INFO" "$1"; }
# Debug log message
# @param $1 Message
# @param $2 JSON value
DEBUG() {
  _log_print_message "$LOG_LEVEL_DEBUG" "$1"
  if [ -n "$2" ] && is_log_level_enabled "$LOG_LEVEL_DEBUG"; then
    echo "$2" | jq .
  fi
}

# ================
# FUNCTIONS
# ================
# Check command is installed
# @param $1 Command name
check_cmd() {
  command -v "$1" > /dev/null 2>&1
}

# Assert command is installed
# @param $1 Command name
assert_cmd() {
  check_cmd "$1" || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Assert executable downloader
assert_downloader() {
  [ -n "$DOWNLOADER" ] && return 0

  _assert_downloader() {
    # Return failure if it doesn't exist or is no executable
    [ -x "$(command -v "$1")" ] || return 1

    # Set downloader
    DOWNLOADER=$1
    return 0
  }

  # Downloader command
  _assert_downloader curl \
    || _assert_downloader wget \
    || FATAL "No executable downloader found: 'curl' or 'wget'"
  DEBUG "Downloader '$DOWNLOADER' found at '$(command -v "$DOWNLOADER")'"
}

# Assert Docker image
# @param $1 Docker image
# @param $2 Dockerfile
# @param $3 Dockerfile context
assert_docker_image() {
  assert_cmd docker
  _docker_image=$1
  _dockerfile=${2:-}
  _dockerfile_context=${3:-}

  if docker image inspect "$_docker_image" > /dev/null 2>&1; then
    DEBUG "Docker image '$_docker_image' found"
    return 0
  fi

  WARN "Docker image '$_docker_image' not found"

  if [ -z "$_dockerfile" ]; then
    INFO "Pulling Docker image '$_docker_image'"
    docker pull "$_docker_image" || FATAL "Error pulling Docker image '$_docker_image'"
  else
    [ -n "$_dockerfile_context" ] || _dockerfile_context=$(dirname "$_dockerfile")
    INFO "Building Docker image '$_docker_image' using Dockerfile '$_dockerfile' with context '$_dockerfile_context'"
    docker build --rm -t "$_docker_image" -f "$_dockerfile" "$_dockerfile_context" || FATAL "Error building Docker image '$_docker_image'"
  fi
}

# Destroy Docker container
# @param $1 Container id
destroy_docker_container() {
  assert_cmd docker
  _container_id=$1

  [ -n "$_container_id" ] || return 0

  INFO "Stopping Docker container '$_container_id'"
  docker stop "$_container_id" > /dev/null 2>&1 || return 0
  INFO "Removing Docker container '$_container_id'"
  docker rm "$_container_id" > /dev/null 2>&1 || return 0
}

# Download a file
# @param $1 Output location
# @param $2 Download URL
download() {
  assert_downloader

  DEBUG "Downloading file '$2' to '$1'"

  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --output "$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    wget)
      wget --quiet --output-document="$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# Print downloaded content
# @param $1 Download URL
download_print() {
  assert_downloader > /dev/null

  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --show-error "$1" || FATAL "Download '$1' failed"
      ;;
    wget)
      wget --quiet --output-document=- "$1" 2>&1 || FATAL "Download '$1' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}
