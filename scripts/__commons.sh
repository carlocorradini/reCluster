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
# GLOBALS
# ================
# Return value
RETVAL=

# ================
# PARSE ARGUMENTS
# ================
# Assert argument has a value
# @param $1 Argument name
# @param $2 Argument value
parse_args_assert_value() {
  [ -n "$2" ] || FATAL "Argument '$1' requires a non-empty value"
}
# Assert argument value is a non negative integer (>= 0)
# @param $1 Argument name
# @param $2 Argument value
parse_args_assert_non_negative_integer() {
  { is_integer "$2" && [ "$2" -ge 0 ]; } || FATAL "Value '$2' of argument '$1' is not a non negative number"
}
# Assert argument value is a positive integer (> 0)
# @param $1 Argument name
# @param $2 Argument value
parse_args_assert_positive_integer() {
  { is_integer "$2" && [ "$2" -gt 0 ]; } || FATAL "Value '$2' of argument '$1' is not a positive number"
}
# Parse command line arguments
# @param $@ Arguments
parse_args_commons() {
  # Number of shift
  _shifts=1

  # Parse
  case $1 in
    --disable-color)
      # Disable color
      LOG_COLOR_ENABLE=false
      ;;
    --disable-spinner)
      # Disable spinner
      SPINNER_ENABLE=false
      ;;
    --log-level)
      # Log level
      parse_args_assert_value "$@"

      case $2 in
        fatal) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
        error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        warn) LOG_LEVEL=$LOG_LEVEL_WARN ;;
        info) LOG_LEVEL=$LOG_LEVEL_INFO ;;
        debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        *) FATAL "Value '$2' of argument '$1' is invalid" ;;
      esac
      _shifts=2
      ;;
    --spinner)
      # Spinner
      parse_args_assert_value "$@"

      case $2 in
        dots) SPINNER_SYMBOLS=$SPINNER_SYMBOLS_DOTS ;;
        grayscale) SPINNER_SYMBOLS=$SPINNER_SYMBOLS_GRAYSCALE ;;
        propeller) SPINNER_SYMBOLS=$SPINNER_SYMBOLS_PROPELLER ;;
        *) FATAL "Value '$2' of argument '$1' is invalid" ;;
      esac
      _shifts=2
      ;;
    -*)
      # Unknown argument
      WARN "Unknown argument '$1' is ignored"
      ;;
    *)
      # No argument
      WARN "Skipping argument '$1'"
      ;;
  esac

  # Return
  RETVAL=$_shifts
}

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

# Convert log level to equivalent name
# @param $1 Log level
to_log_level_name() {
  _log_level=${1:-LOG_LEVEL}
  _log_level_name=

  case $_log_level in
    "$LOG_LEVEL_FATAL") _log_level_name=fatal ;;
    "$LOG_LEVEL_ERROR") _log_level_name=error ;;
    "$LOG_LEVEL_WARN") _log_level_name=warn ;;
    "$LOG_LEVEL_INFO") _log_level_name=info ;;
    "$LOG_LEVEL_DEBUG") _log_level_name=debug ;;
    *) FATAL "Unknown log level '$_log_level'" ;;
  esac

  printf '%s\n' "$_log_level_name"
}

# Check if log level is enabled
# @param $1 Log level
is_log_level_enabled() {
  [ "$1" -le "$LOG_LEVEL" ]
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
    printf '%s\n' "$2" | jq '.'
  fi
}

# ================
# SPINNER
# ================
# Spinner PID
SPINNER_PID=
# Spinner symbol time in seconds
SPINNER_TIME=.1
# Spinner symbols dots
SPINNER_SYMBOLS_DOTS="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
# Spinner symbols grayscale
SPINNER_SYMBOLS_GRAYSCALE="░░░░░░░ ▒░░░░░░ ▒▒░░░░░ ▒▒▒░░░░ ▒▒▒▒░░░ ▒▒▒▒▒░░ ▒▒▒▒▒▒░ ▒▒▒▒▒▒▒ ░▒▒▒▒▒▒ ░░▒▒▒▒▒ ░░░▒▒▒▒ ░░░░▒▒▒ ░░░░░▒▒ ░░░░░░▒"
# Spinner symbols propeller
SPINNER_SYMBOLS_PROPELLER="/ - \\ |"
# Spinner symbols
SPINNER_SYMBOLS=$SPINNER_SYMBOLS_PROPELLER
# Spinner flag
SPINNER_ENABLE=true

# Spinner logic
_spinner() {
  # Termination flag
  _terminate=false
  # Termination signal
  trap '_terminate=true' USR1
  # Message
  _spinner_message=${1:-""}

  while :; do
    # Cursor invisible
    tput civis

    for s in $SPINNER_SYMBOLS; do
      # Save cursor position
      tput sc
      # Symbol and message
      printf "%s %s" "$s" "$_spinner_message"
      # Restore cursor position
      tput rc

      # Terminate
      if [ "$_terminate" = true ]; then
        # Clear line from position to end
        tput el
        break 2
      fi

      # Animation time
      sleep "$SPINNER_TIME"

      # Check parent still alive
      # Parent PID
      _spinner_ppid=$(ps -p "$$" -o ppid=)
      if [ -n "$_spinner_ppid" ]; then
        # shellcheck disable=SC2086
        _spinner_parent_up=$(ps --no-headers $_spinner_ppid)
        if [ -z "$_spinner_parent_up" ]; then break 2; fi
      fi
    done
  done

  # Cursor normal
  tput cnorm
  return 0
}

# Start spinner
# @param $1 Message
# shellcheck disable=SC2120
spinner_start() {
  _spinner_message=${1:-"Loading..."}
  INFO "$_spinner_message"

  [ "$SPINNER_ENABLE" = true ] || return 0
  [ -z "$SPINNER_PID" ] || FATAL "Spinner PID ($SPINNER_PID) already defined"

  # Spawn spinner process
  _spinner "$_spinner_message" &
  # Spinner process id
  SPINNER_PID=$!
}

# Stop spinner
spinner_stop() {
  [ "$SPINNER_ENABLE" = true ] || return 0
  [ -n "$SPINNER_PID" ] || FATAL "Spinner PID is undefined"

  # Send termination signal
  kill -s USR1 "$SPINNER_PID"
  # Wait may fail
  wait "$SPINNER_PID" || :
  # Reset pid
  SPINNER_PID=
}

# ================
# ASSERT
# ================
# Assert command is installed
# @param $1 Command name
assert_cmd() {
  check_cmd "$1" || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Assert spinner
assert_spinner() {
  [ "$SPINNER_ENABLE" = true ] || return 0

  assert_cmd ps
  assert_cmd tput
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

  ! docker image inspect "$_docker_image" > /dev/null 2>&1 || {
    DEBUG "Docker image '$_docker_image' found"
    return 0
  }

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

# Assert executable downloader
assert_downloader() {
  [ -z "$DOWNLOADER" ] || return 0

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

# Assert URL is reachable
# @param $1 URL address
# @param $2 Timeout in seconds
assert_url_reachability() {
  assert_downloader

  # URL address
  _url_address=$1
  # Timeout in seconds
  _timeout=${2:-10}

  DEBUG "Testing URL '$_url_address' reachability"
  case $DOWNLOADER in
    curl)
      curl --fail --silent --show-error --max-time "$_timeout" "$_url_address" > /dev/null || FATAL "URL address '$_url_address' is unreachable"
      ;;
    wget)
      wget --quiet --spider --timeout="$_timeout" --tries=1 "$_url_address" 2>&1 || FATAL "URL address '$_url_address' is unreachable"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# ================
# CLEANUP
# ================
# Cleanup spinner
cleanup_spinner() {
  { [ "$SPINNER_ENABLE" = true ] && [ -n "$SPINNER_PID" ]; } || return 0

  DEBUG "Resetting cursor"
  tput rc
  tput cnorm
  SPINNER_ENABLE=
  SPINNER_PID=
}

# Cleanup Docker container
# @param $1 Container id
cleanup_docker_container() {
  { [ -n "$1" ] && check_cmd docker; } || return 0

  _container_id=$1
  DEBUG "Stopping Docker container '$_container_id'"
  docker stop "$_container_id" > /dev/null 2>&1 || return 0
  DEBUG "Removing Docker container '$_container_id'"
  docker rm "$_container_id" > /dev/null 2>&1 || return 0
}

# Cleanup directory
# @param $1 Directory path
cleanup_dir() {
  { [ -n "$1" ] && [ -d "$1" ]; } || return 0

  _dir=$1
  DEBUG "Removing directory '$_dir'"
  rm -rf "$TMP_DIR" || return 0
}

# ================
# FUNCTIONS
# ================
# Check command is installed
# @param $1 Command name
check_cmd() {
  command -v "$1" > /dev/null 2>&1
}

# Download a file
# @param $1 Output location
# @param $2 Download URL
download() {
  assert_downloader

  # Download
  DEBUG "Downloading file '$2' to '$1'"
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --output "$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    wget)
      wget --quiet --output-document="$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac

  DEBUG "Successfully downloaded file '$2' to '$1'"
}

# Print downloaded content
# @param $1 Download URL
download_print() {
  assert_downloader > /dev/null

  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --show-error "$1" || FATAL "Download print '$1' failed"
      ;;
    wget)
      wget --quiet --output-document=- "$1" 2>&1 || FATAL "Download print '$1' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# Remove and create directory
# @param $1 Directory path
recreate_dir() {
  _dir=$1
  DEBUG "Recreating directory '$_dir'"

  if [ -d "$_dir" ]; then
    WARN "Removing directory '$_dir'"
    rm -rf "$_dir" || FATAL "Error removing directory '$_dir'"
  fi

  INFO "Creating directory '$_dir'"
  mkdir -p "$_dir" || FATAL "Error creating directory '$_dir'"
}

# Check if value is an integer number
# @param $1 Value
is_integer() {
  [ -n "$1" ] || return 1

  case $1 in
    '' | *[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Git files
# @param $1 Git directory
git_files() {
  assert_cmd basename
  assert_cmd git
  assert_cmd jq

  _dir=$1
  # Append .git if not present
  [ "$(basename "$_dir")" = .git ] || _dir="$_dir/.git"

  DEBUG "Git files in '$_dir' Git directory"

  # Check if directory
  [ -d "$_dir" ] || FATAL "Directory '$_dir' does not exists"

  # Git files
  _git_files=$(
    git --git-dir "$_dir" ls-files --cached --others --exclude-standard --full-name \
      | jq --raw-input --null-input '[inputs | select(length > 0)]'
  ) || FATAL "Error Git files in '$_dir' Git directory"

  # Return
  # shellcheck disable=2034
  RETVAL=$_git_files
}

# Check if directory in git
# @param $1 Git files
# @param $2 Directory
git_has_directory() {
  assert_cmd jq

  _git_files=$1
  _dir=$2

  DEBUG "Checking Git has directory '$_dir'"
  [ "$(printf '%s\n' "$_git_files" | jq --raw-output --arg dir "$_dir" 'any(.[]; startswith($dir))')" = true ]
}

# Check if file in git
# @param $1 Git files
# @param $2 File
git_has_file() {
  assert_cmd jq

  _git_files=$1
  _file=$2

  DEBUG "Checking Git has file '$_file'"
  [ "$(printf '%s\n' "$_git_files" | jq --raw-output --arg file "$_file" 'any(.[]; . == $file)')" = true ]
}

# ================
# CONFIGURATION
# ================
# Help usage string
# shellcheck disable=2034
HELP_COMMONS_USAGE=$(
  cat << EOF
Usage commons: $(basename "$0") [--disable-color] [--disable-spinner] [--log-level <LEVEL>] [--spinner <SPINNER>]
EOF
)
# Help options string
# shellcheck disable=2034
HELP_COMMONS_OPTIONS=$(
  cat << EOF
Options commons:
  --disable-color      Disable color

  --disable-spinner    Disable spinner

  --log-level <LEVEL>  Logger level
                       Default: $(to_log_level_name "$LOG_LEVEL")
                       Values:
                         fatal    Fatal level
                         error    Error level
                         warn     Warning level
                         info     Informational level
                         debug    Debug level

  --spinner <SPINNER>  Spinner
                       Default: propeller
                       Values:
                         dots         Dots spinner
                         grayscale    Grayscale spinner
                         propeller    Propeller spinner
EOF
)
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Log color flag
LOG_COLOR_ENABLE=true
# Spinner symbols
SPINNER_SYMBOLS=$SPINNER_SYMBOLS_PROPELLER
# Spinner flag
SPINNER_ENABLE=true
