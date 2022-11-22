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
# shellcheck source=../../scripts/__commons.sh
. "$DIRNAME/../../scripts/__commons.sh"

# ================
# CONFIGURATION
# ================
# Common file
COMMON_FILE="common.config.yml"
# Merge file
MERGE_FILE="config.yml"
# Output file
OUT_FILE="output.yml"
# Overwrite flag
OVERWRITE=false

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--common-file <FILE>] [--help] [--merge-file <FILE>] [--out-file <FILE>] [--overwrite]

$HELP_COMMONS_USAGE

reCluster configurations script.

Options:
  --common-file <FILE>  Common configuration file
                        Default: $COMMON_FILE
                        Values:
                          Any valid file

  --help                Show this help message and exit

  --merge-file <FILE>   Configuration file to merge
                        Default: $MERGE_FILE
                        Values:
                          Any valid file

  --output-file <FILE>  Output configuration file
                        Default: $OUT_FILE
                        Values:
                          Any valid file

  --overwrite           Overwrite merge file

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
      --common-file)
        # Common file
        parse_args_assert_value "$@"

        COMMON_FILE=$2
        _shifts=2
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --merge-file)
        # Merge file
        parse_args_assert_value "$@"

        MERGE_FILE=$2
        _shifts=2
        ;;
      --out-file)
        # Output file
        parse_args_assert_value "$@"

        OUT_FILE=$2
        _shifts=2
        ;;
      --overwrite)
        # Overwrite
        OVERWRITE=true
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

  [ "$OVERWRITE" = false ] || OUT_FILE=$MERGE_FILE
}

# Verify system
verify_system() {
  assert_cmd yq

  [ -f "$COMMON_FILE" ] || FATAL "Common file '$COMMON_FILE' does not exists"
  [ -f "$MERGE_FILE" ] || FATAL "Merge file '$MERGE_FILE' does not exists"
  if [ "$OVERWRITE" = false ] && [ -f "$OUT_FILE" ]; then FATAL "Output file '$OUT_FILE' already exists"; fi
}

# Merge files
merge_files() {
  _merged_file=

  INFO "Merging '$MERGE_FILE' with '$COMMON_FILE'"
  # shellcheck disable=SC2016
  _merged_file=$(yq eval-all '. as $item ireduce ({}; . * $item)' "$MERGE_FILE" "$COMMON_FILE") || FATAL "Error merging '$MERGE_FILE' with '$COMMON_FILE'"
  DEBUG "Merged file:" "$_merged_file"

  INFO "Saving merged file to '$OUT_FILE'"
  printf '%s\n' "$_merged_file" | tee "$OUT_FILE" > /dev/null
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  merge_files
}
