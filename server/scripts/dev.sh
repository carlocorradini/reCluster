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
# K3d configuration file
K3D_CONFIG_FILE="k3d.config.yml"
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
# Certificates directory
CERTS_DIR="$DIRNAME/../certs"
# Certificates passphrase
CERTS_PASSPHRASE=password
# Certificates script
CERTS_SCRIPT="$DIRNAME/../../scripts/certs.sh"
# Skip certificates
SKIP_CERTS=false
# Skip cluster
SKIP_CLUSTER=false
# Skip database
SKIP_DB=false
# Skip database seeding
SKIP_DB_SEED=false
# Skip server
SKIP_SERVER=false

# ================
# GLOBALS
# ================
# Postgres container id
POSTGRES_CONTAINER_ID=

# ================
# CLEANUP
# ================
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Cleanup cluster
  if [ "$SKIP_CLUSTER" = false ] && check_cmd k3d; then
    DEBUG "Deleting cluster"
    k3d cluster delete --config "$K3D_CONFIG_FILE" || :
  fi
  # Cleanup certificates directory
  cleanup_dir "$CERTS_DIR"
  # Cleanup Docker container
  cleanup_docker_container "$POSTGRES_CONTAINER_ID"

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
Usage: $(basename "$0") [--help] [--k3d-config <FILE>] [--skip-certs]
        [--skip-cluster] [--skip-db] [--skip-db-seed] [--skip-server]

$HELP_COMMONS_USAGE

reCluster development server script.

Options:
  --help                     Show this help message and exit

  --k3d-config-file <FILE>   K3d configuration file
                             Default: $K3D_CONFIG_FILE
                             Values:
                               Any valid file

  --skip-certs               Skip certificates

  --skip-cluster             Skip cluster

  --skip-db                  Skip database

  --skip-db-seed             Skip database seed

  --skip-server              Skip server

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
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --k3d-config-file)
        # K3d configuration file
        parse_args_assert_value "$@"

        K3D_CONFIG_FILE=$2
        _shifts=2
        ;;
      --skip-certs)
        # Skip certificates
        SKIP_CERTS=true
        ;;
      --skip-cluster)
        # Skip cluster
        SKIP_CLUSTER=true
        ;;
      --skip-db)
        # Skip database
        SKIP_DB=true
        ;;
      --skip-db-seed)
        # Skip database seed
        SKIP_DB_SEED=true
        ;;
      --skip-server)
        # Skip server
        SKIP_SERVER=true
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
  assert_cmd chmod
  assert_cmd docker
  assert_cmd k3d
  assert_cmd node
  assert_cmd npm
  assert_cmd timeout
  assert_cmd until

  assert_docker_image "$POSTGRES_IMAGE"

  [ -f "$K3D_CONFIG_FILE" ] || FATAL "K3d configuration file '$K3D_CONFIG_FILE' not found"
}

# Setup system
setup_system() {
  recreate_dir "$CERTS_DIR" || FATAL "Error recreating certificates directory '$CERTS_DIR'"
}

# Setup certificates
setup_certs() {
  [ "$SKIP_CERTS" = false ] || { WARN "Skipping certificates" && return 0; }

  $CERTS_SCRIPT \
    --out-dir "$CERTS_DIR" \
    --ssh-passphrase "$CERTS_PASSPHRASE" \
    --token-passphrase "$CERTS_PASSPHRASE"
}

# Setup cluster
setup_cluster() {
  [ "$SKIP_CLUSTER" = false ] || { WARN "Skipping cluster" && return 0; }

  INFO "Creating cluster"
  k3d cluster create --config "$K3D_CONFIG_FILE"
}

# Setup database
setup_database() {
  [ "$SKIP_DB" = false ] || { WARN "Skipping database" && return 0; }

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

  INFO "Synchronizing database"
  npm run --prefix "$NPM_PREFIX" db:sync

  if [ "$SKIP_DB_SEED" = false ]; then
    INFO "Seeding database"
    npm run --prefix "$NPM_PREFIX" db:seed
  else
    WARN "Skipping database seed"
  fi
}

# Setup server
setup_server() {
  [ "$SKIP_SERVER" = false ] || { WARN "Skipping server" && return 0; }

  INFO "Starting server"
  npm run --prefix "$NPM_PREFIX" start:dev
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  setup_certs
  setup_cluster
  setup_database
  setup_server
}
