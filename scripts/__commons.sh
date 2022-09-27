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
__DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __DIRNAME

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Prevents errors in a pipeline from being masked
set -o pipefail
# Disable wildcard character expansion
set -o noglob

# ================
# LOGGER
# ================
# Fatal log level. Cause exit failure
readonly LOG_LEVEL_FATAL=100
# Error log level
readonly LOG_LEVEL_ERROR=200
# Warning log level
readonly LOG_LEVEL_WARN=300
# Informational log level
readonly LOG_LEVEL_INFO=500
# Debug log level
readonly LOG_LEVEL_DEBUG=600
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Log color flag
LOG_COLOR_ENABLE=true

# Print log message
# @param $1 Log level
# @param $2 Message
function _log_print_message() {
  local log_level
  local log_level_name
  local log_message
  local log_prefix
  local log_suffix
  log_level=${1:-LOG_LEVEL_FATAL}
  shift
  log_message=${*:-}
  log_suffix="\033[0m"

  # Check log level
  if [ "$log_level" -gt "$LOG_LEVEL" ]; then return; fi

  case $log_level in
    "$LOG_LEVEL_FATAL")
      log_level_name=FATAL
      log_prefix="\033[41;37m"
      ;;
    "$LOG_LEVEL_ERROR")
      log_level_name=ERROR
      log_prefix="\033[1;31m"
      ;;
    "$LOG_LEVEL_WARN")
      log_level_name=WARN
      log_prefix="\033[1;33m"
      ;;
    "$LOG_LEVEL_INFO")
      log_level_name=INFO
      log_prefix="\033[37m"
      ;;
    "$LOG_LEVEL_DEBUG")
      log_level_name=DEBUG
      log_prefix="\033[1;34m"
      ;;
  esac

  # Check color flag
  if [ "$LOG_COLOR_ENABLE" = false ]; then
    log_prefix=
    log_suffix=
  fi

  # Output to stdout
  printf '%b[%-5s][%s:%d] %b%b\n' "$log_prefix" "$log_level_name" "${FUNCNAME[2]}" "${BASH_LINENO[1]}" "$log_message" "$log_suffix"
}

# Fatal log message
FATAL() {
  _log_print_message ${LOG_LEVEL_FATAL} "$@"
  exit 1
}
# Error log message
ERROR() { _log_print_message ${LOG_LEVEL_ERROR} "$@"; }
# Warning log message
WARN() { _log_print_message ${LOG_LEVEL_WARN} "$@"; }
# Informational log message
INFO() { _log_print_message ${LOG_LEVEL_INFO} "$@"; }
# Debug log message
DEBUG() { _log_print_message ${LOG_LEVEL_DEBUG} "$@"; }

# ================
# FUNCTIONS
# ================
# Assert command is installed
# @param $1 Command name
function assert_cmd() {
  [ -x "$(command -v "$1")" ] || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Assert downloader (curl or wget) is installed
function assert_downloader() {
  [ -n "${DOWNLOADER+x}" ] && return

  # Check and set downloader
  _assert_downloader() {
    # Return failure if it doesn't exist or is no executable
    [ -x "$(command -v "$1")" ] || return 1
    # Set downloader program and return success
    DOWNLOADER=$1
    readonly DOWNLOADER
    DEBUG "Downloader is '$DOWNLOADER'"
    return 0
  }

  # Downloader command
  _assert_downloader curl \
    || _assert_downloader wget \
    || FATAL "No executable downloader found: 'curl' or 'wget'"
  DEBUG "Downloader '$DOWNLOADER' found at '$(command -v "$DOWNLOADER")'"
}

# Check docker image
function assert_docker_image() {
  assert_cmd docker

  if [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]; then
    WARN "Docker image '$1' not found"

    if [ "$#" -ne 2 ] || [ -z "$2" ]; then
      FATAL "Unable to build '$1' because no Dockerfile has been provided"
    fi

    INFO "Building Docker image '$1' using Dockerfile '$2'"
    docker build --rm -t "$1" -f "$2" "$__DIRNAME/.." || FATAL "Error building Docker image '$1' using Dockerfile '$2'"
  else
    DEBUG "Docker image '$1' found"
  fi
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
      wget --quiet ---output-document=- "$1" 2>&1 || FATAL "Download '$1' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}
