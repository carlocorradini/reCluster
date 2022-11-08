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
# Certificates directory
CERTS_DIR="$DIRNAME/../certs"
# Certificates passphrase
CERTS_PASSPHRASE=password
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

# Load commons
. "$DIRNAME/../../scripts/__commons.sh"

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Certificates
  if [ -d "$CERTS_DIR" ]; then
    DEBUG "Removing certificates directory '$CERTS_DIR'"
    rm -rf "$CERTS_DIR" || WARN "Failed to remove certificates directory '$CERTS_DIR'"
  fi

  # Cluster
  if check_cmd k3d; then
    DEBUG "Deleting cluster"
    k3d cluster delete --config "$K3D_CONFIG" || WARN "Failed to delete cluster"
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

  cat << EOF
Usage: $_script_name [--help] [--k3d-config <PATH>] [--skip-certs]
        [--skip-cluster] [--skip-db] [--skip-db-seed] [--skip-server]

reCluster development server script.

Options:
  --help                Show this help message and exit

  --k3d-config <PATH>   K3d configuration file
                        Default: $K3D_CONFIG
                        Values:
                          Any valid file path

  --skip-certs          Skip certificates

  --skip-cluster        Skip cluster

  --skip-db             Skip database

  --skip-db-seed        Skip database seed

  --skip-server         Skip server
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
      --skip-certs)
        # Skip certificates
        SKIP_CERTS=true
        shift
        ;;
      --skip-cluster)
        # Skip cluster
        SKIP_CLUSTER=true
        shift
        ;;
      --skip-db)
        # Skip database
        SKIP_DB=true
        shift
        ;;
      --skip-db-seed)
        # Skip database seed
        SKIP_DB_SEED=true
        shift
        ;;
      --skip-server)
        # Skip server
        SKIP_SERVER=true
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
  assert_cmd chmod
  assert_cmd docker
  assert_cmd k3d
  assert_cmd node
  assert_cmd npm
  assert_cmd ssh-keygen
  assert_cmd timeout
  assert_cmd until

  assert_docker_image "$POSTGRES_IMAGE"
}

# Check system
check_system() {
  [ -f "$K3D_CONFIG" ] || FATAL "K3d configuration file '$K3D_CONFIG' not found"
  recreate_dir "$CERTS_DIR" || FATAL "Error recreating certificates directory '$CERTS_DIR'"
}

# Setup certificates
setup_certs() {
  [ "$SKIP_CERTS" = false ] || { WARN "Skipping certificates" && return 0; }

  _ssh_key_name=ssh
  _token_key_name=token

  INFO "Generating SSH certificate"
  ssh-keygen -b 2048 -t rsa -f "$CERTS_DIR/$_ssh_key_name.key" -N "$CERTS_PASSPHRASE"
  mv "$CERTS_DIR/$_ssh_key_name.key.pub" "$CERTS_DIR/$_ssh_key_name.pub"
  chmod 600 "$CERTS_DIR/$_ssh_key_name.key" "$CERTS_DIR/$_ssh_key_name.pub"

  INFO "Generating Token certificate"
  ssh-keygen -b 4096 -t rsa -f "$CERTS_DIR/$_token_key_name.key" -N "$CERTS_PASSPHRASE" -m PEM
  ssh-keygen -e -m PEM -f "$CERTS_DIR/$_token_key_name.key" > "$CERTS_DIR/$_token_key_name.pub"
  rm "$CERTS_DIR/$_token_key_name.key.pub"
  chmod 600 "$CERTS_DIR/$_token_key_name.key" "$CERTS_DIR/$_token_key_name.pub"
}

# Setup cluster
setup_cluster() {
  [ "$SKIP_CLUSTER" = false ] || { WARN "Skipping cluster" && return 0; }

  INFO "Creating cluster"
  k3d cluster create --config "$K3D_CONFIG"
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
  check_system
  setup_certs
  setup_cluster
  setup_database
  setup_server
}
