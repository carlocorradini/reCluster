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
. "$DIRNAME/../../scripts/__commons.sh"

# ================
# CONFIGURATION
# ================
# Configuration file
CONFIG_FILE="$DIRNAME/dependencies.config.yml"
# Root directory
ROOT_DIR="$(readlink -f "$DIRNAME/../..")"
# Synchronize flag
SYNC=false
# Synchronize force flag
SYNC_FORCE=false

# ================
# GLOBALS
# ================
# Configuration
CONFIG=

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--help] [--list] [--release <DEP> <VERSION>] [--update]

$HELP_COMMONS_USAGE

reCluster dependencies script.

Options:
  --help          Show this help message and exit

  --sync          Synchronize dependencies

  --sync-force    Synchronize dependencies replacing assets that are already present

$HELP_COMMONS_OPTIONS
EOF
}

# Assert dependency $1 exists
# @param $1 Dependency name
assert_dep() {
  echo "$CONFIG" | jq --exit-status --arg name "$1" 'has($name)' > /dev/null 2>&1 || FATAL "Dependency '$1' does not exists"
}

# Return dependency configuration
# @param $1 Dependency name
dep_config() {
  assert_dep "$1"
  echo "$CONFIG" | jq --arg name "$1" '.[$name]'
}

# Generate github api url
# @param $1 Dependency name
gen_github_api_url() {
  _config=$(dep_config "$1")
  _url=$(echo "$_config" | jq --raw-output '.url')
  _owner=$(echo "$_url" | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed 's#/[^/]*$##') || FATAL "Error reading owner from GitHub URL '$_url'"
  _repo=$(echo "$_url" | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed 's#^.*/\([^/]*\)$#\1#') || FATAL "Error reading repository from GitHub URL '$_url'"

  echo "https://api.github.com/repos/$_owner/$_repo/releases"
}

# Return dependency latest release
# @param $1 Dependency name
find_latest_release() {
  _github_api_url=$(gen_github_api_url "$1")

  download_print "$_github_api_url/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || FATAL "Download '$_github_api_url/latest' failed"
}

# Clean dependencies environment
sync_deps_clean() {
  git_files "$ROOT_DIR"
  _git_files=$RETVAL

  set +o noglob

  # Clean dependency directories
  for _dep_fd in "$DIRNAME"/*; do
    _dep_fd_basename=$(basename "$_dep_fd")

    if [ -f "$_dep_fd" ]; then
      # File
      _dep_fd_git_file=$(echo "$_dep_fd" | sed -n -e 's#^.*'"$ROOT_DIR"'/##p')

      if ! git_has_file "$_git_files" "$_dep_fd_git_file"; then
        # Remove dependency file
        INFO "Removing file '$_dep_fd_basename'"
        rm -f "$_dep_fd"
      else
        DEBUG "Keeping file '$_dep_fd_basename'"
      fi
    elif [ -d "$_dep_fd" ]; then
      # Directory
      if ! echo "$CONFIG" | jq --exit-status --arg dep "$_dep_fd_basename" 'has($dep)' > /dev/null 2>&1; then
        # Remove dependency directory
        INFO "Removing dependency directory '$_dep_fd_basename'"
        rm -rf "$_dep_fd"
        continue
      fi

      # Dependency configuration
      _config=$(dep_config "$_dep_fd_basename")
      # Latest release version
      _latest_release=$(find_latest_release "$_dep_fd_basename")

      # Clean dependency
      for _fd in "$DIRNAME/$_dep_fd_basename"/*; do
        _fd_basename=$(basename "$_fd")

        if [ -f "$_fd" ]; then
          # Check file
          if ! echo "$_config" | jq --exit-status --arg file "$_fd_basename" '.files | has($file)' > /dev/null 2>&1; then
            # Remove file
            INFO "Removing '$_dep_fd_basename' file '$_fd_basename'"
            rm -f "$_fd"
            continue
          fi
        elif [ -d "$_fd" ]; then
          # Skip if 'latest' release and check release directory
          if ! { echo "$_config" | jq --exit-status '.releases | any(. == "latest")' > /dev/null 2>&1 && [ "$_fd_basename" = "$_latest_release" ]; } && ! echo "$_config" | jq --exit-status --arg dir "$_fd_basename" '.releases | any(. == $dir)' > /dev/null 2>&1; then
            # Remove release directory
            INFO "Removing '$_dep_fd_basename' release directory '$_fd_basename'"
            rm -rf "$_fd"
            continue
          fi

          # Clean remaining
          for _ufd in "$DIRNAME/$_dep_fd_basename/$_fd_basename"/*; do
            [ -f "$_ufd" ] || [ -d "$_ufd" ] || continue

            _ufd_basename=$(basename "$_ufd")

            if [ "$(echo "$_config" | jq --raw-output --arg asset "$_ufd_basename" 'any(.assets[]; ("^" + . + "$") as $keep | $asset | test($keep))')" = false ]; then
              # Remove
              INFO "Removing '$_dep_fd_basename' release '$_fd_basename' file/directory '$_ufd_basename'"
              rm -rf "$_ufd"
              continue
            fi
          done
        fi
      done
    fi
  done

  set -o noglob
}

# Synchronize dependency release
# @param $1 Dependency name
# @param $2 Release
sync_dep_release() {
  _dep_name=$1
  _release=$2
  _github_api_url=$(gen_github_api_url "$_dep_name")
  case "$_release" in
    latest) _is_release_latest=true ;;
    *) _is_release_latest=false ;;
  esac

  # If release is 'latest' find tag name
  if [ $_is_release_latest = true ]; then
    INFO "Finding '$_dep_name' latest release"
    _release=$(find_latest_release "$_dep_name")
    INFO "Latest '$_dep_name' release is '$_release'"
  fi

  # Release id
  _release_id=$(download_print "$_github_api_url/tags/$_release" | jq --raw-output .id) || FATAL "Download '$_github_api_url/tags/$_release' failed"
  DEBUG "'$_dep_name' release id '$_release_id'"

  # Release assets
  _assets=$(download_print "$_github_api_url/$_release_id/assets" | jq --compact-output 'map({name, "url": .browser_download_url})') || FATAL "Download '$_github_api_url/$_release_id/assets' failed"
  DEBUG "'$_dep_name' assets:\n$(echo "$_assets" | jq .)"

  # Create release directory if not exists
  _release_dir="$(readlink -f "$DIRNAME")/$_dep_name/$_release"
  if [ ! -d "$_release_dir" ]; then
    INFO "Creating '$_dep_name' directory '$_release_dir'"
    mkdir -p "$_release_dir"
  fi

  # Download assets
  while read -r _asset; do
    _asset_name=$(echo "$_asset" | jq --raw-output '.name')
    _asset_url=$(echo "$_asset" | jq --raw-output .url)
    _asset_path="$_release_dir/$_asset_name"

    # Skip if not force and asset already exists
    if [ "$SYNC_FORCE" = false ] && [ -f "$_asset_path" ]; then
      DEBUG "Skipping '$_dep_name' release '$_release' asset '$_asset_name' already exists"
      continue
    fi
    # Skip if ignored
    if [ "$(echo "$_config" | jq --raw-output --arg asset "$_asset_name" 'any(.assets[]; ("^" + . + "$") as $keep | $asset | test($keep))')" = false ]; then
      DEBUG "Skipping '$_dep_name' release '$_release' asset '$_asset_name' ignored"
      continue
    fi

    # Download
    INFO "Downloading '$_dep_name' release '$_release' asset '$_asset_name' into '$_asset_path'"
    download "$_asset_path" "$_asset_url"
  done << EOF
$(echo "$_assets" | jq --compact-output '.[]')
EOF
}

# Synchronize dependency
# @param $1 Dependency name
sync_dep_files() {
  _config=$(dep_config "$1")
  _dep_name=$1

  # Files
  while read -r _file; do
    _file_name=$(echo "$_file" | jq --raw-output '.key')
    _file_url=$(echo "$_file" | jq --raw-output '.value')
    _file_path="$(readlink -f "$DIRNAME")/$_dep_name/$_file_name"

    # Skip if not force and file already exists
    if [ "$SYNC_FORCE" = false ] && [ -f "$_file_path" ]; then
      DEBUG "Skipping '$_dep_name' file '$_file_name' already exists"
      continue
    fi

    # Download
    INFO "Downloading '$_dep_name' file '$_file_name' from '$_file_url' into '$_file_path'"
    download "$_file_path" "$_file_url"
  done << EOF
$(echo "$_config" | jq --compact-output '.files | to_entries[]')
EOF
}

# Synchronize dependency
# @param $1 Dependency name
sync_dep() {
  _config=$(dep_config "$1")
  _dep_name=$1

  # Releases
  while read -r _release; do
    _release=$(echo "$_release" | jq --raw-output '.')
    INFO "Syncing '$_dep_name' release '$_release'"
    sync_dep_release "$_dep_name" "$_release"
  done << EOF
$(echo "$_config" | jq --compact-output '.releases[]')
EOF

  # Files
  if echo "$_config" | jq --exit-status 'has("files")' > /dev/null 2>&1; then
    INFO "Syncing '$_dep_name' files"
    sync_dep_files "$_dep_name"
  fi
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
      --sync)
        # Synchronize
        SYNC=true
        ;;
      --sync-force)
        # Synchronize force
        SYNC=true
        SYNC_FORCE=true
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
  assert_cmd grep
  assert_cmd jq
  assert_cmd sed
  assert_cmd yq

  assert_downloader

  # Configuration
  [ -f "$CONFIG_FILE" ] || FATAL "Configuration file '$CONFIG_FILE' not found"
  INFO "Reading configuration file '$CONFIG_FILE'"
  CONFIG=$(yq e --output-format=json --no-colors '.' "$CONFIG_FILE") || FATAL "Error reading configuration file '$CONFIG_FILE'"
  DEBUG "Configuration:" "$CONFIG"
}

# Synchronize dependency
sync_deps() {
  [ "$SYNC" = true ] || return 0

  _num_deps=$(echo "$CONFIG" | jq --raw-output '. | length')

  INFO "Syncing $_num_deps dependencies"

  # Clean environment
  sync_deps_clean
  # Dependencies
  while read -r _dep; do
    _dep_name=$(echo "$_dep" | jq --raw-output '.key')
    INFO "Syncing '$_dep_name'"
    sync_dep "$_dep_name"
  done << EOF
$(echo "$CONFIG" | jq --compact-output 'to_entries[]')
EOF

  INFO "Successfully synced $_num_deps dependencies"
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  sync_deps
}
