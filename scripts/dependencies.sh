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

# Current directory
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIRNAME
# Git directory
GIT_DIR=$(readlink -f "$DIRNAME/../.git")
readonly GIT_DIR

# Commons
source "$DIRNAME/__commons.sh"

# ================
# DEPENDENCIES
# ================
# k3s
# shellcheck disable=2034
declare -A dependencies0=(
  [name]=k3s
  [path]=dependencies/k3s/source
  [url]=https://github.com/k3s-io/k3s.git
  [ref]=master
)
# node_exporter_installer
# shellcheck disable=2034
declare -A dependencies1=(
  [name]=node_exporter_installer
  [path]=dependencies/node_exporter_installer/source
  [url]=https://github.com/carlocorradini/node_exporter_installer.git
  [ref]=main
)

# Merge dependencies
declare -n dependencies

# ================
# MAIN
# ================
# Update
for dependencies in ${!dependencies@}; do
  _name=${dependencies[name]}
  _path=${dependencies[path]}
  _url=${dependencies[url]}
  _ref=${dependencies[ref]}

  INFO "Updating '$_name'"
  DEBUG "Updating '$_name' located in '$_path' from '$_url' in branch '$_ref'"
  git --git-dir="$GIT_DIR" subtree pull --prefix "$_path" "$_url" "$_ref" --squash
done

INFO "Successfully updated '${!dependencies#}' dependencies"
