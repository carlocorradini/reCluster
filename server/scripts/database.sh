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
# PostgreSQL version
POSTGRESQL_VERSION=14.2
# PostgreSQL image
POSTGRESQL_IMAGE="docker.io/postgres:$POSTGRESQL_VERSION"
# PostgreSQL port
POSTGRESQL_PORT=5432
# PostgreSQL user
POSTGRESQL_USER=recluster
# PostgreSQL password
POSTGRESQL_PASSWORD=password
# PostgreSQL database
POSTGRESQL_DATABASE=recluster

# Load commons
. "$DIRNAME/../../scripts/__commons.sh"

# Assert
assert_cmd docker

# ================
# MAIN
# ================
{
  INFO "Starting PostgreSQL '$POSTGRESQL_IMAGE'"
  docker run \
    -p "$POSTGRESQL_PORT:5432" \
    -e POSTGRES_USER="$POSTGRESQL_USER" \
    -e POSTGRES_PASSWORD="$POSTGRESQL_PASSWORD" \
    -e POSTGRES_DB="$POSTGRESQL_DATABASE" \
    --rm \
    "$POSTGRESQL_IMAGE"
}
