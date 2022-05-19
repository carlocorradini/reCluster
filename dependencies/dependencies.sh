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
DEPS_CONFIG_FILE="$DIRNAME/dependencies.json"
readonly DEPS_CONFIG_FILE
# Dependencies configuration file content
DEPS=
# Synchronize flag
SYNC=false
# Synchronize force flag
SYNC_FORCE=false

# Commons
source "$DIRNAME/../scripts/__commons.sh"

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
  [ "$(jq --raw-output --arg name "$1" 'any(.[]; .name == $name)' <<< "$DEPS")" = true ] || FATAL "Dependency '$1' does not exists"
}

# Return dependency configuration
# @param $1 Dependency name
dep_config() {
  assert_dep "$1"
  jq --arg name "$1" '.[] | select(.name == $name)' <<< "$DEPS"
}

# Clean dependencies environment
sync_deps_clean() {
  local -
  set +o noglob

  local name
  local found
  local dd_basename
  local rd_basename

  # Clean dependency directories
  for dd in "$DIRNAME"/*/; do
    # Skip if not directory
    [ -d "$dd" ] || continue

    # Set found to false
    found=false
    # Dependency directory basename
    dd_basename=$(basename "$dd")

    # Dependencies
    while read -r dep; do
      name=$(jq --raw-output '.name' <<< "$dep")

      # Check if dependency exists
      if [ "$dd_basename" = "$name" ]; then
        # Clean release directories
        for rd in "$DIRNAME/$name"/*/; do
          # Skip if not directory
          [ -d "$rd" ] || continue

          # Set found to false
          found=false
          # Release directory basename
          rd_basename=$(basename "$rd")

          # Releases
          while read -r release; do
            release=$(jq --raw-output '.' <<< "$release")

            # Check if release exists
            if [ "$rd_basename" = "$release" ]; then
              # Found
              found=true
              break
            fi
          done <<< "$(dep_config "$name" | jq --compact-output '.releases[]')"

          # Skip if found
          if [ "$found" = true ]; then continue; fi

          # Remove directory
          INFO "Removing '$name' release directory '$rd_basename'"
          rm -rf "$rd"
        done

        # Found
        found=true
        break
      fi
    done <<< "$(jq --compact-output '.[]' <<< "$DEPS")"

    # Skip if found
    if [ "$found" = true ]; then continue; fi

    # Remove directory
    INFO "Removing '$dd_basename' dependency directory"
    rm -rf "$dd"
  done
}

# Synchronize dependency
# @param $1 Name
# @param $2 Release
sync_dep() {
  [ $# -eq 2 ] || FATAL "sync_dep requires exactly 2 arguments but '$#' found"
  assert_dep "$1"

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
  local asset_name
  local asset_url
  local asset_output
  while read -r asset; do
    asset_name=$(jq --raw-output .name <<< "$asset")
    asset_url=$(jq --raw-output .url <<< "$asset")
    asset_output="$release_dir/$asset_name"

    # Skip if not force and asset already exists
    if [ "$SYNC_FORCE" = false ] && [ -f "$asset_output" ]; then
      DEBUG "Skipping '$name' release '$release' asset '$asset_name' already exists"
      continue
    fi
    # Skip if ignored
    if jq --exit-status '.assets.ignore' >/dev/null 2>&1 <<< "$config" \
      && [ "$(jq --raw-output --arg asset "$asset_name" 'any(.assets.ignore[]; ("^" + . + "$") as $ignore | $asset | test($ignore))' <<< "$config")" = true ]; then
      DEBUG "Skipping '$name' release '$release' asset '$asset_name' ignored"
      continue
    fi

    # Download
    INFO "Downloading '$name' release '$release' asset '$asset_name' into '$asset_output'"
    download "$asset_output" "$asset_url"
  done <<< "$(jq --compact-output '.[]' <<< "$assets")"
}

################################################################################################################################

# Verify system
verify_system() {
  assert_cmd grep
  assert_cmd jq
  assert_cmd sed

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
        exit 1
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
  DEPS=$(<"$DEPS_CONFIG_FILE")

  # Check JSON
  jq --exit-status . >/dev/null 2>&1 <<< "$DEPS" || FATAL "Configuration file contains invalid JSON"
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
    name=$(jq --raw-output '.name' <<< "$dep")
    INFO "Syncing '$name'"
    # Releases
    while read -r release; do
      release=$(jq --raw-output '.' <<< "$release")
      INFO "Syncing '$name' release '$release'"
      sync_dep "$name" "$release"
    done <<< "$(jq --compact-output '.releases[]' <<< "$dep")"
  done <<< "$(jq --compact-output '.[]' <<< "$DEPS")"

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
