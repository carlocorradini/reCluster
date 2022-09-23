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
# Log disable color flag
LOG_DISABLE_COLOR=1

# Print log message
# @param $1 Log level
# @param $2 Message
function _log_print_message() {
  local log_level=$1
  shift
  local log_message=${*:-}
  local log_name
  local log_prefix
  local log_suffix="\033[0m"

  # Log level is enabled
  if [ "$log_level" -gt "$LOG_LEVEL" ]; then return; fi

  case $log_level in
    "$LOG_LEVEL_FATAL")
      log_name=FATAL
      log_prefix="\033[41;37m"
      ;;
    "$LOG_LEVEL_ERROR")
      log_name=ERROR
      log_prefix="\033[1;31m"
      ;;
    "$LOG_LEVEL_WARN")
      log_name=WARN
      log_prefix="\033[1;33m"
      ;;
    "$LOG_LEVEL_INFO")
      log_name=INFO
      log_prefix="\033[37m"
      ;;
    "$LOG_LEVEL_DEBUG")
      log_name=DEBUG
      log_prefix="\033[1;34m"
      ;;
  esac

  # Color disable flag
  if [ "$LOG_DISABLE_COLOR" -eq 0 ]; then
    log_prefix=
    log_suffix=
  fi

  # Output to stdout
  printf '%b[%-5s][%s:%d] %b%b\n' "$log_prefix" "$log_name" "${FUNCNAME[2]}" "${BASH_LINENO[1]}" "$log_message" "$log_suffix"
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
    DEBUG "Downloader is '$DOWNLOADER'"
    return 0
  }

  _assert_downloader curl \
    || _assert_downloader wget \
    || FATAL "Unable to find downloader 'curl' or 'wget'"
  readonly DOWNLOADER
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
  [ $# -eq 2 ] || FATAL "Download requires exactly 2 arguments but '$#' found"
  assert_downloader

  # Download
  DEBUG "Downloading '$2' into '$1'"
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --output "$1" "$2" || FATAL "Download '$2' failed"
      ;;
    wget)
      wget --quiet --output-document="$1" "$2" || FATAL "Download '$2' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# Print downloaded content
# @param $1 Download URL
download_print() {
  [ $# -eq 1 ] || FATAL "Download requires exactly 1 argument but '$#' found"
  assert_downloader

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
