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
# Git directory
GIT_DIR=$(readlink -f "$DIRNAME/../.git")
readonly GIT_DIR
# Update dependencies flag
UPDATE_DEPS=false
# Dependency release
declare -A RELEASE_DEP=(
  [name]=""
  [release]=""
)

# Commons
source "$DIRNAME/__commons.sh"

# ================
# DEPENDENCIES
# ================
declare -a deps_name=("k3s" "node_exporter" "node_exporter_installer")
declare -a deps_path=("dependencies/k3s" "dependencies/node_exporter" "dependencies/node_exporter_installer")
declare -a deps_url=("https://github.com/k3s-io/k3s" "https://github.com/prometheus/node_exporter" "https://github.com/carlocorradini/node_exporter_installer")
declare -a deps_ref=("master" "master" "main")

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: dependencies.sh [--help] [--list] [--release <DEP> <VERSION>] [--update]

reCluster dependencies management script.

Options:
  --help                       Show this help message and exit

  --list                       List known dependencies

  --release <DEP> <VERSION>    Download release <VERSION> of dependency <DEP>
                               <DEP> values:
                                 Dependency name
                               <VERSION> values:
                                 Any <DEP> version released
                                 'latest' to download latest release

  --update                     Update dependencies
EOF
}
# List known dependencies
list_dependencies() {
  for i in "${!deps_name[@]}"; do
    cat << EOF
${deps_name[i]}:
    name -> ${deps_name[i]}
    path -> ${deps_path[i]}
    url  -> ${deps_url[i]}
    ref  -> ${deps_ref[i]}
EOF
  done
}

# Return dependency $1 index
# @param $1 Dependency name
dep_idx() {
  for i in "${!deps_name[@]}"; do
    if [ "${deps_name[i]}" = "$1" ]; then echo "$i"; return; fi
  done

  FATAL "Dependency '$1' does not exists"
}

# Assert dependency $1 exists
# @param $1 Dependency name
assert_dep() {
  dep_idx "$1" > /dev/null 2>&1
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
      --list)
        # List known dependencies
        list_dependencies
        exit 0
      ;;
      --release)
        # Dependency release(s)
        if [ -z "$2" ]; then FATAL "Argument '$1' requires a non-empty dependency value"; fi
        if [ -z "$3" ]; then FATAL "Argument '$1' requires a non-empty version value"; fi
        assert_dep "$2"

        RELEASE_DEP[name]=$2
        RELEASE_DEP[version]=$3

        shift
        shift
        shift
      ;;
      --update)
        # Update dependencies
        UPDATE_DEPS=true
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

# Update dependencies
update_deps() {
  INFO "Updating '${#deps_name[@]}' dependencies"

  for i in "${!deps_name[@]}"; do
    local name=${deps_name[i]}
    local path="${deps_path[i]}/source"
    local url="${deps_url[i]}.git"
    local ref=${deps_ref[i]}

    INFO "Updating '$name'"
    DEBUG "Updating '$name' located in '$path' from '$url' in branch '$ref'"
    git --git-dir="$GIT_DIR" subtree pull --prefix "$path" "$url" "$ref" --squash
  done

  INFO "Successfully updated '${#deps_name[@]}' dependencies"
}

# Download dependency release
release_dep() {
  assert_dep "${RELEASE_DEP[name]}"

  local idx
  idx=$(dep_idx "${RELEASE_DEP[name]}")
  local dep_name=${deps_name[idx]}
  local dep_version=${RELEASE_DEP[version]}
  local dep_path
  dep_path=$(readlink -f "$DIRNAME/../${deps_path[idx]}")
  local dep_url=${deps_url[idx]}
  [[ $dep_url =~ ^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+)(.git)*$ ]] || FATAL "Unable to extract username and repository from '$dep_url'"
  local github_api_url="https://api.github.com/repos/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}/releases"
  local release_id
  local assets
  local release_dir

  # If version is 'latest' find release tag name
  if [ "$dep_version" = "latest" ]; then
    INFO "Finding '$dep_name' latest release"
    dep_version=$(download_print "$github_api_url/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    INFO "Latest '$dep_name' release is '$dep_version'"
  fi

  # Release id
  release_id=$(download_print "$github_api_url/tags/$dep_version" | jq --raw-output .id)
  DEBUG "'$dep_name' release id '$release_id'"

  # Release assets
  assets=$(download_print "$github_api_url/$release_id/assets" | jq --raw-output 'map({name, "url": .browser_download_url})')
  DEBUG "'$dep_name' assets:\n$(echo "$assets" | jq .)"

  # Create release directory
  release_dir="$dep_path/releases/$dep_version"
  if [ -d "$release_dir" ]; then
    WARN "Release directory '$release_dir' already exists"
  else
    INFO "Creating '$dep_name' release directory '$release_dir'"
    mkdir -p "$release_dir"
  fi

  # Download assets
  local asset_name
  local asset_url
  local asset_output
  while read -r asset; do
    asset_name=$(echo "$asset" | jq --raw-output .name)
    asset_url=$(echo "$asset" | jq --raw-output .url)
    asset_output="$release_dir/$asset_name"

    # Skip download if file already exists
    if [ -f "$asset_output" ]; then
      WARN "File '$asset_output' already exists"
      continue
    fi

    # Download
    INFO "Downloading '$asset_name' into '$asset_output'"
    DEBUG "Downloading '$asset_name' into '$asset_output' from '$asset_url'"
    download "$asset_output" "$asset_url"
  done <<< "$(echo "$assets" | jq --compact-output '.[]')"
}

# ================
# MAIN
# ================
{
  verify_system
  parse_args "$@"

  [ "$UPDATE_DEPS" = true ] && update_deps
  [ -n "${RELEASE_DEP[name]}" ] && [ -n "${RELEASE_DEP[version]}" ] && release_dep
}
