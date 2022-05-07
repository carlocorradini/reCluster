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
# Log disable color flag
LOG_DISABLE_COLOR=1

# Print log message
# @param $1 Log level
# @param $2 Message
_log_print_message() {
  _log_level=$1
  shift
  _log_message=${*:-}
  _log_name=""
  _log_prefix=""
  _log_suffix="\033[0m"

  # Log level is enabled
  if [ "$_log_level" -gt "$LOG_LEVEL" ]; then return; fi

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_name="FATAL"
      _log_prefix="\033[41;37m"
    ;;
    "$LOG_LEVEL_ERROR")
      _log_name="ERROR"
      _log_prefix="\033[1;31m"
    ;;
    "$LOG_LEVEL_WARN")
      _log_name="WARN"
      _log_prefix="\033[1;33m"
    ;;
    "$LOG_LEVEL_INFO")
      _log_name="INFO"
      _log_prefix="\033[37m"
    ;;
    "$LOG_LEVEL_DEBUG")
      _log_name="DEBUG"
      _log_prefix="\033[1;34m"
    ;;
  esac

  # Color disable flag
  if [ "$LOG_DISABLE_COLOR" -eq 0 ]; then
    _log_prefix=""
    _log_suffix=""
  fi

  # Output to stdout
  printf '%b[%-5s][%s:%d] %b%b\n' "$_log_prefix" "$_log_name" "${FUNCNAME[2]}" "${BASH_LINENO[1]}" "$_log_message" "$_log_suffix"
}

# Fatal log message
FATAL() { _log_print_message ${LOG_LEVEL_FATAL} "$@"; exit 1; }
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
  command -v "$1" >/dev/null 2>&1 || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Check docker image
function assert_docker_image() {
  assert_tool docker

  if [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]; then
    WARN "Docker image '$1' not found"

    if [ "$#" -ne 2 ] || [ -z "$2" ]; then
      FATAL "Unable to build '$1' because no Dockerfile has been provided"
    fi

    INFO "Building Docker image '$1' using Dockerfile '$2'"
    docker build --rm -t "$1" -f "$2" "$__DIRNAME/.."
  else
    DEBUG "Docker image '$1' found"
  fi
}
