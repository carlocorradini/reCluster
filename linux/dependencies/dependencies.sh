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

# ================
# CONFIGURATION
# ================
# Current directory
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIRNAME
# Dependencies configuration file
DEPS_CONFIG_FILE="$DIRNAME/dependencies.yml"
readonly DEPS_CONFIG_FILE
# Dependencies configuration file content
DEPS=
# Synchronize flag
SYNC=false
# Synchronize force flag
SYNC_FORCE=false

# Commons
source "$DIRNAME/../../scripts/__commons.sh"

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: dependencies.sh [--help] [--list] [--release <DEP> <VERSION>] [--update]

reCluster dependencies management script.

Options:
  --help          Show this help message and exit

  --sync          Synchronize dependencies

  --sync-force    Synchronize dependencies replacing assets that are already present
EOF
}

# Assert dependency $1 exists
# @param $1 Dependency name
assert_dep() {
  jq --exit-status --arg name "$1" 'has($name)' <<< "$DEPS" > /dev/null 2>&1 || FATAL "Dependency '$1' does not exists"
}

# Return dependency configuration
# @param $1 Dependency name
dep_config() {
  assert_dep "$1"
  jq --arg name "$1" '.[$name]' <<< "$DEPS"
}

# Clean dependencies environment
sync_deps_clean() {
  local -
  set +o noglob

  # TODO Better names
  local dep_fd_basename
  local fd_basename
  local ufd_basename
  local config

  # Clean dependency directories
  for dep_fd in "$DIRNAME"/*; do
    dep_fd_basename=$(basename "$dep_fd")

    if [ -f "$dep_fd" ]; then
      # Check files

      case $dep_fd_basename in
        .gitignore | dependencies.sh | dependencies.yml | README.md)
          # Keep
          ;;
        *)
          # Remove dependency directory
          INFO "Removing '$dep_fd_basename' file"
          rm -f "$dep_fd"
          ;;
      esac
    elif [ -d "$dep_fd" ]; then
      # Check directories
      if ! jq --exit-status --arg dep "$dep_fd_basename" 'has($dep)' <<< "$DEPS" > /dev/null 2>&1; then
        # Remove dependency directory
        INFO "Removing '$dep_fd_basename' dependency directory"
        rm -rf "$dep_fd"
        continue
      fi

      # Dependency configuration
      config=$(dep_config "$dep_fd_basename")

      # Clean dependency
      for fd in "$DIRNAME/$dep_fd_basename"/*; do
        fd_basename=$(basename "$fd")

        if [ -f "$fd" ]; then
          # Check file
          if ! jq --exit-status --arg file "$fd_basename" '.files | has($file)' <<< "$config" > /dev/null 2>&1; then
            # Remove file
            INFO "Removing '$dep_fd_basename' file '$fd_basename'"
            rm -f "$fd"
            continue
          fi
        elif [ -d "$fd" ]; then
          # Check release directory
          if ! jq --exit-status --arg dir "$fd_basename" '.releases | any(. == $dir)' <<< "$config" > /dev/null 2>&1; then
            # Remove release directory
            INFO "Removing '$dep_fd_basename' release directory '$fd_basename'"
            rm -rf "$fd"
            continue
          fi

          # Clean remaining
          for ufd in "$DIRNAME/$dep_fd_basename/$fd_basename"/*; do
            [ -f "$ufd" ] || [ -d "$ufd" ] || continue

            ufd_basename=$(basename "$ufd")

            if [ "$(jq --raw-output --arg asset "$ufd_basename" 'any(.assets[]; ("^" + . + "$") as $keep | $asset | test($keep))' <<< "$config")" = false ]; then
              # Remove
              INFO "Removing '$dep_fd_basename' release '$fd_basename' file/directory '$ufd_basename'"
              rm -rf "$ufd"
              continue
            fi
          done
        fi
      done
    fi
  done
}

# Synchronize dependency release
# @param $1 Name
# @param $2 Release
sync_dep_release() {
  [ $# -eq 2 ] || FATAL "sync_dep_release requires exactly 2 arguments but '$#' found"

  local config
  config=$(dep_config "$1")
  local name=$1
  local release=$2
  local url
  url=$(jq --raw-output '.url' <<< "$config")
  [[ $url =~ ^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$ ]] || FATAL "Unable to extract owner and repository from '$url'"
  local github_api_url="https://api.github.com/repos/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}/releases"
  local release_id
  local assets
  local release_dir

  # If release is 'latest' find tag name
  if [ "$release" = "latest" ]; then
    INFO "Finding '$name' latest release"
    release=$(download_print "$github_api_url/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || FATAL "Download '$github_api_url/latest' failed"
    INFO "Latest '$name' release is '$release'"
  fi

  # Release id
  release_id=$(download_print "$github_api_url/tags/$release" | jq --raw-output .id) || FATAL "Download '$github_api_url/tags/$release' failed"
  DEBUG "'$name' release id '$release_id'"

  # Release assets
  assets=$(download_print "$github_api_url/$release_id/assets" | jq --compact-output 'map({name, "url": .browser_download_url})') || FATAL "Download '$github_api_url/$release_id/assets' failed"
  DEBUG "'$name' assets:\n$(echo "$assets" | jq .)"

  # Create release directory if not exists
  release_dir="$(readlink -f "$DIRNAME")/$name/$release"
  if [ ! -d "$release_dir" ]; then
    INFO "Creating '$name' directory '$release_dir'"
    mkdir -p "$release_dir"
  fi

  # Download assets
  while read -r asset; do
    local asset_name
    local asset_url
    local asset_path
    asset_name=$(jq --raw-output .name <<< "$asset")
    asset_url=$(jq --raw-output .url <<< "$asset")
    asset_path="$release_dir/$asset_name"

    # Skip if not force and asset already exists
    if [ "$SYNC_FORCE" = false ] && [ -f "$asset_path" ]; then
      DEBUG "Skipping '$name' release '$release' asset '$asset_name' already exists"
      continue
    fi
    # Skip if ignored
    if [ "$(jq --raw-output --arg asset "$asset_name" 'any(.assets[]; ("^" + . + "$") as $keep | $asset | test($keep))' <<< "$config")" = false ]; then
      DEBUG "Skipping '$name' release '$release' asset '$asset_name' ignored"
      continue
    fi

    # Download
    INFO "Downloading '$name' release '$release' asset '$asset_name' into '$asset_path'"
    download "$asset_path" "$asset_url"
  done <<< "$(jq --compact-output '.[]' <<< "$assets")"
}

# Synchronize dependency
# @param $1 Name
sync_dep_files() {
  [ $# -eq 1 ] || FATAL "sync_dep_files requires exactly 1 arguments but '$#' found"

  local config
  config=$(dep_config "$1")
  local name=$1

  # Files
  while read -r file; do
    local file_name
    local file_url
    local file_path
    file_name=$(jq --raw-output '.key' <<< "$file")
    file_url=$(jq --raw-output '.value' <<< "$file")
    file_path="$(readlink -f "$DIRNAME")/$name/$file_name"

    # Skip if not force and file already exists
    if [ "$SYNC_FORCE" = false ] && [ -f "$file_path" ]; then
      DEBUG "Skipping '$name' file '$file_name' already exists"
      continue
    fi

    # Download
    INFO "Downloading '$name' file '$file_name' from '$file_url' into '$file_path'"
    download "$file_path" "$file_url"
  done <<< "$(jq --compact-output '.files | to_entries[]' <<< "$config")"
}

# Synchronize dependency
# @param $1 Name
sync_dep() {
  [ $# -eq 1 ] || FATAL "sync_dep requires exactly 1 arguments but '$#' found"

  local config
  config=$(dep_config "$1")
  local name=$1

  # Releases
  while read -r release; do
    release=$(jq --raw-output '.' <<< "$release")
    INFO "Syncing '$name' release '$release'"
    sync_dep_release "$name" "$release"
  done <<< "$(jq --compact-output '.releases[]' <<< "$config")"

  # Files
  if jq --exit-status 'has("files")' <<< "$config" > /dev/null 2>&1; then
    INFO "Syncing '$name' files"
    sync_dep_files "$name"
  fi
}

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd grep
  assert_cmd jq
  assert_cmd sed
  assert_cmd yq

  assert_downloader
}

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --sync)
        # Synchronize
        SYNC=true
        shift
        ;;
      --sync-force)
        # Synchronize force
        SYNC=true
        SYNC_FORCE=true
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
}

# Read configuration file
read_config() {
  # Check config file exists
  [ -f "$DEPS_CONFIG_FILE" ] || FATAL "Dependencies configuration file not found at '$DEPS_CONFIG_FILE'"

  # Read config file
  DEPS=$(yq e --output-format=json --no-colors '.' "$DEPS_CONFIG_FILE") || FATAL "Configuration file '$DEPS_CONFIG_FILE' is invalid"
  DEBUG "Configuration:\n$(jq '.' <<< "$DEPS")"
}

# Synchronize dependency
sync_deps() {
  local num_deps
  num_deps=$(jq --raw-output '. | length' <<< "$DEPS")
  local name

  INFO "Syncing '$num_deps' dependencies"

  # Clean environment
  sync_deps_clean
  # Dependencies
  while read -r dep; do
    name=$(jq --raw-output '.key' <<< "$dep")
    INFO "Syncing '$name'"
    sync_dep "$name"
  done <<< "$(jq --compact-output 'to_entries[]' <<< "$DEPS")"

  INFO "Successfully synced '$num_deps' dependencies"
}

# ================
# MAIN
# ================
{
  verify_system
  parse_args "$@"
  read_config
  if [ "$SYNC" = true ]; then sync_deps; fi
}
