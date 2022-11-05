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
# K3d configuration file
K3D_CONFIG="$DIRNAME/../k3d.config.yml"
# npm prefix
NPM_PREFIX="$DIRNAME/.."
# Postgres version
POSTGRES_VERSION=15
# Postgres image
POSTGRES_IMAGE="docker.io/postgres:$POSTGRES_VERSION-alpine"
# Postgres port
POSTGRES_PORT=5432
# Postgres user
POSTGRES_USER=recluster
# Postgres password
POSTGRES_PASSWORD=password
# Postgres database
POSTGRES_DB=recluster
# Database seeding flag
DB_SEED=true

# ================
# GLOBALS
# ================
# Postgres container id
POSTGRES_CONTAINER_ID=

# Load commons
. "$DIRNAME/../../scripts/__commons.sh"

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Cluster
  if check_cmd k3d; then
    DEBUG "Deleting cluster"
    k3d cluster delete --config "$K3D_CONFIG" || WARN "Cluster deletion failed"
  fi

  # Destroy Docker container
  destroy_docker_container "$POSTGRES_CONTAINER_ID"

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  # Script name
  _script_name=$(basename "$0")
  # K3d config file name
  _k3d_config_file_name=$(basename "$K3D_CONFIG")

  cat << EOF
Usage: $_script_name [--help] [--k3d-config] [--skip-seed]

reCluster development server script.

Options:
  --help          Show this help message and exit

  --k3d-config    K3d configuration file
                  Default: $_k3d_config_file_name
                  Values:
                    Any valid file path

  --skip-seed     Skip database seeding
EOF
}

################################################################################################################################

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  _parse_args_assert_value() {
    if [ -z "$2" ]; then FATAL "Argument '$1' requires a non-empty value"; fi
  }

  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --k3d-config)
        # K3d configuration file
        _parse_args_assert_value "$@"

        _k3d_config=$2
        shift
        shift
        ;;
      --skip-seed)
        # Skip database seeding
        DB_SEED=false
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

  # K3d configuration file
  if [ -n "$_k3d_config" ]; then K3D_CONFIG=$_k3d_config; fi
}

# Verify system
verify_system() {
  assert_cmd docker
  assert_cmd k3d
  assert_cmd node
  assert_cmd npm
  assert_cmd timeout
  assert_cmd until

  assert_docker_image "$POSTGRES_IMAGE"
}

# Check system
check_system() {
  [ -f "$K3D_CONFIG" ] || FATAL "K3d configuration file '$K3D_CONFIG' not found"
}

# Create cluster
create_cluster() {
  INFO "Creating cluster"
  k3d cluster create --config "$K3D_CONFIG"
}

# Start database
start_database() {
  INFO "Starting Postgres '$POSTGRES_IMAGE'"
  POSTGRES_CONTAINER_ID=$(
    docker run \
      -p "$POSTGRES_PORT:5432" \
      -e POSTGRES_USER="$POSTGRES_USER" \
      -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
      -e POSTGRES_DB="$POSTGRES_DB" \
      -e TZ=Etc/UTC \
      -e PGTZ=Etc/UTC \
      --rm \
      --detach \
      --interactive \
      --tty \
      "$POSTGRES_IMAGE"
  )

  INFO "Waiting Postgres is ready"
  timeout 30s sh -c "until docker exec $POSTGRES_CONTAINER_ID pg_isready ; do sleep 3 ; done" || FATAL "Timed out waiting Postgres to be ready"
}

# Synchronize database
sync_database() {
  INFO "Synchronizing database"
  npm run --prefix "$NPM_PREFIX" db:sync
}

# Seed database
seed_database() {
  [ "$DB_SEED" = true ] || return 0
  INFO "Seeding database"
  npm run --prefix "$NPM_PREFIX" db:seed
}

# Start server
start_server() {
  INFO "Starting server"
  npm run --prefix "$NPM_PREFIX" start:dev
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  check_system
  create_cluster
  start_database
  sync_database
  seed_database
  start_server
}
