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
# Configuration common file
CONFIG_COMMON_FILE="$DIRNAME/config.common.yml"
# Configuration file to merge
CONFIG_MERGE_FILE="$DIRNAME/config.yml"
# Configuration output file
CONFIG_OUTPUT_FILE="$DIRNAME/output.yml"

# Load commons
. "$DIRNAME/../../scripts/__commons.sh"

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: configs.sh [--common <PATH>] [--help] [--merge <PATH>] [--output <PATH>]

reCluster configuration management script.

Options:
  --common <PATH>    Common configuration file
                     Default: $CONFIG_COMMON_FILE
                     Values:
                       Any valid file path

  --help             Show this help message and exit

  --merge <PATH>     Configuration file to merge
                     Default: $CONFIG_MERGE_FILE
                     Values:
                       Any valid file path

  --output <PATH>    Output configuration file
                     Default: $CONFIG_OUTPUT_FILE
                     Values:
                       Any valid file path
EOF
}

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd yq
}

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  _parse_args_assert_value() {
    if [ -z "$2" ]; then FATAL "Argument '$1' requires a non-empty value"; fi
  }

  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --common)
        # Common config file
        _parse_args_assert_value "$@"

        _config_common_file=$2
        shift
        shift
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --merge)
        # Merge config file
        _parse_args_assert_value "$@"

        _config_merge_file=$2
        shift
        shift
        ;;
      --output)
        # Output config file
        _parse_args_assert_value "$@"

        _config_output_file=$2
        shift
        shift
        ;;
      -*)
        # Unknown argument
        WARN "Unknown argument '$1' is ignored"
        shift
        ;;
      *)
        # No argument
        WARN "Skipping argument '$1'"
        shift
        ;;
    esac
  done

  # Common config file
  if [ -n "$_config_common_file" ]; then CONFIG_COMMON_FILE=$_config_common_file; fi
  # Merge config file
  if [ -n "$_config_merge_file" ]; then CONFIG_MERGE_FILE=$_config_merge_file; fi
  # Output config file
  if [ -n "$_config_output_file" ]; then CONFIG_OUTPUT_FILE=$_config_output_file; fi
}

# Merge files
merge_files() {
  [ -f "$CONFIG_MERGE_FILE" ] || FATAL "Merge file '$CONFIG_MERGE_FILE' does not exists"
  [ -f "$CONFIG_COMMON_FILE" ] || FATAL "Common file '$CONFIG_COMMON_FILE' does not exists"
  _merged=

  DEBUG "Merging '$CONFIG_MERGE_FILE' with '$CONFIG_COMMON_FILE'"

  # shellcheck disable=SC2016
  _merged_file=$(yq eval-all '. as $item ireduce ({}; . * $item)' "$CONFIG_MERGE_FILE" "$CONFIG_COMMON_FILE") || FATAL "Error merging '$CONFIG_MERGE_FILE' with '$CONFIG_COMMON_FILE'"
  DEBUG "Merged file:" "$_merged_file"

  INFO "Saving merged file to '$CONFIG_OUTPUT_FILE'"
  echo "$_merged_file" | tee "$CONFIG_OUTPUT_FILE" > /dev/null
}

# ================
# MAIN
# ================
{
  verify_system
  parse_args "$@"
  merge_files
}
