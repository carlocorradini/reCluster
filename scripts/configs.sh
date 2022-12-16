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
# Configuration file
CONFIG_FILE="configs.config.yaml"
# Input directory
IN_DIR="configs"
# Output directory
OUT_DIR="./"
# Overwrite flag
OVERWRITE=false

# ================
# GLOBALS
# ================
# Configuration
CONFIG=
# Temporary directory
TMP_DIR=

# ================
# CLEANUP
# ================
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Cleanup temporary directory
  cleanup_dir "$TMP_DIR"

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--config-file <FILE>] [--help] [--in-dir <DIR>] [--out-dir <DIR>] [--overwrite]

$HELP_COMMONS_USAGE

reCluster configurations script.

Options:
  --config-file <FILE>  Configuration file
                        Default: $CONFIG_FILE
                        Values:
                          Any valid file

  --help                Show this help message and exit

  --in-dir <DIR>        Input directory
                        Default: $IN_DIR
                        Values:
                          Any valid directory

  --out-dir <DIR>       Output directory
                        Default: $OUT_DIR
                        Values:
                          Any valid directory

  --overwrite           Overwrite input directory

$HELP_COMMONS_OPTIONS
EOF
}

# Configuration __
config__() {
  printf '%s\n' "$CONFIG" | jq 'map(select(.key | contains(".__.")))'
}

# Configuration without __
config_no__() {
  printf '%s\n' "$CONFIG" | jq 'map(select(.key | (contains(".__.") | not)))'
}

# Prepare configs
configs_prepare() {
  while read -r _entry; do
    _config="$(printf '%s\n' "$_entry" | jq --raw-output '.key | sub("(.__.).*"; "")')"
    _has_run="$(printf '%s\n' "$_entry" | jq --raw-output 'any(.key; endswith("run"))')"

    INFO "Preparing '$_config'"

    # Check __/run
    [ "$_has_run" = true ] || {
      WARN "'run' of '$_config' not found"
      continue
    }

    # Run
    _runs="$(printf '%s\n' "$_entry" | jq --raw-output --arg root "$TMP_DIR" '.value | split("\n") | map(select(length > 0) | sub("\\."; $root))')"
    _run_result=
    INFO "'run' of '$_config'"
    while read -r _run; do
      _run="$(printf '%s\n' "$_run" | jq --raw-output '.')"

      INFO "Executing '$_run' of '$_config'"
      _run_result=$(eval "$_run") || FATAL "Error executing '$_run' of '$_config'"
    done << EOF
$(printf '%s\n' "$_runs" | jq --compact-output '.[]')
EOF
    DEBUG "'run' of '$_config' result:\n$_run_result"

    # Update configuration
    CONFIG=$(printf '%s\n' "$CONFIG" | jq --arg key "$_config" --arg value "$_run_result" '. += [{ key: $key, value: $value }]')
  done \
    << EOF
$(printf '%s\n' "$(config__)" | jq --compact-output '.[]')
EOF
}

# Move configurations
configs_move() {
  _in_dir="$IN_DIR.old"
  [ ! -d "$_in_dir" ] || FATAL "Directory '$_in_dir' already exists"

  DEBUG "Renaming '$IN_DIR' to '$_in_dir'"
  mv "$IN_DIR" "$_in_dir"

  [ -d "$OUT_DIR" ] || {
    DEBUG "Creating directory '$OUT_DIR'"
    mkdir -p "$OUT_DIR"
  }

  INFO "Moving configurations from '$TMP_DIR' to '$OUT_DIR'"
  set +o noglob
  mv "$TMP_DIR"/* "$OUT_DIR"
  set -o noglob

  DEBUG "Removing directory '$_in_dir'"
  rm -rf "$_in_dir"
}

################################################################################################################################

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  while [ $# -gt 0 ]; do
    # Number of shift
    _shifts=1

    case $1 in
      --config-file)
        # Configuration file
        parse_args_assert_value "$@"

        CONFIG_FILE=$2
        _shifts=2
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --in-dir)
        # Input directory
        parse_args_assert_value "$@"

        IN_DIR=$2
        _shifts=2
        ;;
      --out-dir)
        # Output directory
        parse_args_assert_value "$@"

        OUT_DIR=$2
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

  [ "$OVERWRITE" = false ] || OUT_DIR=$IN_DIR
}

# Verify system
verify_system() {
  assert_cmd find
  assert_cmd grep
  assert_cmd jq
  assert_cmd sed
  assert_cmd yq

  [ -d "$IN_DIR" ] || FATAL "Configuration directory '$IN_DIR' does not exists"

  # Configuration
  [ -f "$CONFIG_FILE" ] || FATAL "Configuration file '$CONFIG_FILE' does not exists"
  INFO "Reading configuration file '$CONFIG_FILE'"
  CONFIG=$(yq e --output-format=json --no-colors '.' "$CONFIG_FILE") || FATAL "Error reading configuration file '$CONFIG_FILE'"
  DEBUG "Configuration:" "$CONFIG"
}

# Setup system
setup_system() {
  # Temporary directory
  TMP_DIR=$(mktemp --directory)
  DEBUG "Created temporary directory '$TMP_DIR'"

  # Copy
  DEBUG "Copying '$IN_DIR' to '$TMP_DIR'"
  cp -a "$IN_DIR/." "$TMP_DIR"

  # Configuration
  CONFIG=$(printf '%s\n' "$CONFIG" | jq '[paths([scalars] != []) as $path | {"key": $path | join("."), "value": getpath($path)}]')
}

# Configs
configs() {
  _regex='.*(\$\{\{[[:space:]]*)(.*?)([[:space:]]*\}\}).*'
  _configs=

  # Prepare configs
  configs_prepare

  # Read configuration
  _configs=$(config_no__)

  while read -r _file; do
    INFO "Analyzing file '$_file'"

    grep -q -E "$_regex" "$_file" || continue

    while read -r _line; do
      DEBUG "Analyzing line '$_line' of '$_file'"
      _line_original=$_line

      # Replace line string
      while printf '%s\n' "$_line" | grep -q -E "$_regex"; do
        DEBUG "Configuration from '$_line'"

        _config=$(printf '%s\n' "$_line" | sed -n -r "s/$_regex/\1\2\3/p")
        _config_key=$(printf '%s\n' "$_line" | sed -n -r "s/$_regex/\2/p" | sed -r 's/\s+//g')

        [ "$(printf '%s\n' "$_configs" | jq --raw-output --arg key "$_config_key" 'any(.[]; .key == $key)')" = true ] || {
          WARN "No corresponding value for '$_config' of '$_file'"
          break
        }

        _config_value=$(printf '%s\n' "$_configs" | jq --raw-output --arg key "$_config_key" '.[] | select(.key == $key) | .value')
        _line=$(printf '%s\n' "$_line" | sed "s^$_config^$_config_value^")

        DEBUG "Configuration to '$_line'"
      done

      [ "$_line_original" != "$_line" ] || {
        WARN "Line '$_line' of '$_file' is unchanged"
        continue
      }

      # Replace line file
      DEBUG "Replacing '$_line_original' with '$_line'"
      sed -i "s^$_line_original^$_line^" "$_file"
    done << EOF
$(grep -E "$_regex" "$_file")
EOF
  done << EOF
$(find "$TMP_DIR" -type f)
EOF

  # Move configurations
  configs_move
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  configs
}
