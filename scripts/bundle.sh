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
CONFIG_FILE="bundle.config.yml"
# Output file
OUT_FILE="bundle.tar.gz"
# Root directory
ROOT_DIR="$(readlink -f "$DIRNAME/..")"
# Skip run
SKIP_RUN=false

# ================
# GLOBALS
# ================
# Configuration
CONFIG=
# Git files
GIT_FILES=
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
Usage: $(basename "$0") [--help] [--out-file <FILE>] [--skip-run]

$HELP_COMMONS_USAGE

reCluster bundle script.

Options:
  --config-file <FILE>  Configuration file
                        Default: $CONFIG_FILE
                        Values:
                          Any valid file

  --help                Show this help message and exit

  --out-file <FILE>     Output file
                        Default: $OUT_FILE
                        Values:
                          Any valid file

  --skip-run            Skip run

$HELP_COMMONS_OPTIONS
EOF
}

# Configuration __
config__() {
  printf '%s\n' "$CONFIG" | jq 'map(select(.key | contains("/__/")))'
}

# Configuration without __
config_no__() {
  printf '%s\n' "$CONFIG" | jq 'map(select(.key | (contains("/__/") | not)))'
}

# Prepare bundle
bundle_prepare() {
  _config=$(config__)

  while read -r _entry; do
    _path="$(printf '%s\n' "$_entry" | jq --raw-output '.key | sub("(\/__\/).*"; "")')"
    _path_src="$ROOT_DIR/$_path"
    _has_run="$(printf '%s\n' "$_entry" | jq --raw-output 'any(.key; endswith("run"))')"

    INFO "Preparing '$_path'"

    # Check __/run
    [ "$SKIP_RUN" = false ] || {
      WARN "Skipping 'run' of '$_path'"
      continue
    }
    [ "$_has_run" = true ] || {
      WARN "'run' of '$_path' not found"
      continue
    }

    # Run
    _runs="$(printf '%s\n' "$_entry" | jq --raw-output --arg root "$ROOT_DIR" '.value | split("\n") | map(select(length > 0) | sub("^\\."; $root))')"
    INFO "'run' of '$_path'"
    (
      # Change working directory
      cd "$_path_src"

      while read -r _run; do
        _run="$(printf '%s\n' "$_run" | jq --raw-output '.')"

        INFO "Executing '$_run' of '$_path'"
        eval "$_run" || FATAL "Error executing '$_run' of '$_path'"
      done << EOF
$(printf '%s\n' "$_runs" | jq --compact-output '.[]')
EOF
    ) || FATAL "Error 'run' of '$_path'"
  done << EOF
$(printf '%s\n' "$_config" | jq --compact-output '.[]')
EOF
}

# Bundle files
bundle_files() {
  _config=$(config_no__)
  _files="[]"

  while read -r _entry; do
    _path="$(echo "$_entry" | jq --raw-output '.key')"
    _path_src="$ROOT_DIR/$_path"
    _skip=$(echo "$_entry" | jq --raw-output '.value | type == "boolean" and . | not')

    INFO "Checking '$_path'"

    [ "$_skip" = false ] || {
      WARN "Skipping '$_path' from bundle files"
      continue
    }
    [ -f "$_path_src" ] || [ -d "$_path_src" ] || FATAL "File or directory '$_path_src' does not exists"

    # Add path to bundle
    if [ -f "$_path_src" ]; then
      # File
      DEBUG "Adding file '$_path' to bundle files"
      _files=$(echo "$_files" | jq --arg file "$_path" '. += [$file]')
    elif [ -d "$_path_src" ]; then
      # Directory
      DEBUG "Adding directory '$_path' to bundle files"
      _new_files=

      # Check Git
      if git_has_directory "$GIT_FILES" "$_path"; then
        # Git
        DEBUG "Directory '$_path' in Git"
        _new_files=$(echo "$GIT_FILES" | jq --arg dir "$_path" 'map(select(startswith($dir) and (contains(".gitignore") | not) and (contains(".gitkeep") | not)))')
      else
        # No Git
        DEBUG "Directory '$_path' not in Git"
        _new_files=$(find "$_path_src" -type f | sed -n -e 's#^.*'"$ROOT_DIR"'/##p' | jq --raw-input --null-input '[inputs | select(length > 0)]')
      fi

      # Skip if no new files
      { [ "$_new_files" != "" ] && [ "$_new_files" != "[]" ]; } || {
        WARN "Directory '$_path' is empty"
        continue
      }

      DEBUG "Bundle files from '$_path':" "$_new_files"
      # Add to files
      _files=$(echo "$_files" | jq --argjson files "$_new_files" '. + $files')
    fi
  done << EOF
$(echo "$_config" | jq --compact-output '.[]')
EOF

  # Remove duplicates and sort
  _files=$(echo "$_files" | jq 'unique | sort')

  # Return
  RETVAL=$_files
}

# Bundle tarball
bundle_tarball() {
  INFO "Generating tarball '$OUT_FILE'"

  find "$TMP_DIR" -printf "%P\n" \
    | tar \
      --create \
      --verbose \
      --gzip \
      --no-recursion \
      --file="$OUT_FILE" \
      --directory="$TMP_DIR" \
      --files-from=-
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
        _shifts=$2
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --out-file)
        # Output file
        parse_args_assert_value "$@"
        OUT_FILE=$2
        _shifts=2
        ;;
      --skip-run)
        # Skip run
        SKIP_RUN=true
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
  assert_cmd find
  assert_cmd git
  assert_cmd jq
  assert_cmd mktemp
  assert_cmd printf
  assert_cmd sed
  assert_cmd tar
  assert_cmd yq

  [ ! -f "$OUT_FILE" ] || WARN "Output file '$OUT_FILE' already exists"

  # Configuration
  [ -f "$CONFIG_FILE" ] || FATAL "Configuration file '$CONFIG_FILE' not found"
  INFO "Reading configuration file '$CONFIG_FILE'"
  CONFIG=$(yq e --output-format=json --no-colors '.' "$CONFIG_FILE") || FATAL "Error reading configuration file '$CONFIG_FILE'"
  DEBUG "Configuration:" "$CONFIG"
}

# Setup system
setup_system() {
  # Temporary directory
  TMP_DIR=$(mktemp --directory)
  DEBUG "Created temporary directory '$TMP_DIR'"

  # Configuration
  CONFIG=$(printf '%s\n' "$CONFIG" | jq '[paths([scalars] != []) as $path | {"key": $path | join("/"), "value": getpath($path)}]')

  # Git files
  git_files "$ROOT_DIR"
  GIT_FILES=$RETVAL
  DEBUG "Git files:" "$GIT_FILES"
}

# Bundle
bundle() {
  _files=

  # Prepare bundle
  bundle_prepare

  # Files
  bundle_files
  _files=$RETVAL
  DEBUG "Bundle files:" "$_files"

  while read -r _file; do
    _file="$(echo "$_file" | jq --raw-output '.')"
    _file_src="$ROOT_DIR/$_file"
    _file_dst="$TMP_DIR/$_file"
    _file_dst_dir=$(dirname "$_file_dst")

    INFO "Bundling '$_file'"

    # Create destination directory if not exists
    [ -d "$_file_dst_dir" ] || {
      DEBUG "Creating directory '$_file_dst_dir'"
      mkdir -p "$_file_dst_dir"
    }

    # Copy
    DEBUG "Copying '$_file_src' to '$_file_dst'"
    cp "$_file_src" "$_file_dst" || FATAL "Error copying '$_file_src' to '$_file_dst'"
  done << EOF
$(echo "$_files" | jq --compact-output '.[]')
EOF

  # Generate bundle tarball
  bundle_tarball
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  bundle
}
