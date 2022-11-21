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
# shellcheck source=./__commons.sh
. "$DIRNAME/__commons.sh"

# ================
# CONFIGURATION
# ================
# Root directory
ROOT_DIR="$(readlink -f "$DIRNAME/..")"

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--help]

$HELP_COMMONS_USAGE

reCluster initialization script.

Options:
  --help                Show this help message and exit

$HELP_COMMONS_OPTIONS
EOF
}

# Download inline script
download_inline_script() {
  _script_url="https://raw.githubusercontent.com/carlocorradini/inline/main/inline.sh"
  _script_file="$DIRNAME/inline.sh"

  INFO "Downloading '$_script_url'"
  download "$_script_file" "$_script_url"
}

# Install dependencies
install_dependencies() {
  INFO "Installing dependencies"

  DEBUG "Installing dependencies"
  npm --prefix "$ROOT_DIR" ci
  DEBUG "Installing server dependencies"
  npm --prefix "$ROOT_DIR/server" ci
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
  assert_cmd npm
  assert_downloader
}

# Initialization
init() {
  INFO "Initialization"
  download_inline_script
  install_dependencies
  INFO "Initialization succeeded"
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  init
}
