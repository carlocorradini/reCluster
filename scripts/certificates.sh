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
. "$DIRNAME/__commons.sh"

# ================
# CONFIGURATION
# ================
# Output directory
OUT_DIR="./"
# SSH key name
SSH_NAME="ssh"
# SSH passphrase
SSH_PASSPHRASE=
# SSH bits
SSH_BITS=2048
# Token key name
TOKEN_NAME="token"
# Token passphrase
TOKEN_PASSPHRASE=
# Token bits
TOKEN_BITS=4096

# ================
# GLOBALS
# ================
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
Usage: $(basename "$0") [--help] [--out-dir <DIRECTORY>]
        [--ssh-bits <BITS>] [--ssh-name <NAME>] --ssh-passphrase <PASSPHRASE>
        [--token-bits <BITS>] [--token-name <NAME>] --token-passphrase <PASSPHRASE>

reCluster certificates script.

Options:
  --help                            Show this help message and exit

  --out-dir <DIRECTORY>             Output directory
                                    Default: $OUT_DIR
                                    Values:
                                      Any valid directory

  --ssh-bits <BITS>                 Number of bits in the SSH key
                                    Default: $SSH_BITS
                                    Values:
                                      Any valid number of bits

  --ssh-name <NAME>                 SSH key name
                                    Default: $SSH_NAME
                                    Values:
                                      Any valid name

  --ssh-passphrase <PASSPHRASE>     SSH passphrase
                                    Values:
                                      Any valid passphrase

  --token-bits <BITS>               Number of bits in the Token key
                                    Default: $TOKEN_BITS
                                    Values:
                                      Any valid number of bits

  --token-name <NAME>               Token key name
                                    Default: $TOKEN_NAME
                                    Values:
                                      Any valid name

  --token-passphrase <PASSPHRASE>   Token passphrase
                                    Values:
                                      Any valid passphrase
EOF
}

################################################################################################################################

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
      --out-dir)
        # Output directory
        parse_args_assert_value "$@"

        _out_dir=$2
        shift
        shift
        ;;
      --ssh-bits)
        # SSH bits
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$@"

        _ssh_bits=$2
        shift
        shift
        ;;
      --ssh-name)
        # SSH key name
        parse_args_assert_value "$@"

        _ssh_name=$2
        shift
        shift
        ;;
      --ssh-passphrase)
        # SSH passphrase
        parse_args_assert_value "$@"

        _ssh_passphrase=$2
        shift
        shift
        ;;
      --token-name)
        # Token key name
        parse_args_assert_value "$@"

        _token_name=$2
        shift
        shift
        ;;
      --token-passphrase)
        # Token passphrase
        parse_args_assert_value "$@"

        _token_passphrase=$2
        shift
        shift
        ;;
      --token-bits)
        # Token bits
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$@"

        _token_bits=$2
        shift
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

  # Output directory
  if [ -n "$_out_dir" ]; then OUT_DIR=$_out_dir; fi
  # SSH bits
  if [ -n "$_ssh_bits" ]; then SSH_BITS=$_ssh_bits; fi
  # SSH key name
  if [ -n "$_ssh_name" ]; then SSH_NAME=$_ssh_name; fi
  # SSH passphrase
  if [ -n "$_ssh_passphrase" ]; then SSH_PASSPHRASE=$_ssh_passphrase; fi
  # Token bits
  if [ -n "$_token_bits" ]; then TOKEN_BITS=$_token_bits; fi
  # Token key name
  if [ -n "$_token_name" ]; then SSH_NAME=$_token_name; fi
  # Token passphrase
  if [ -n "$_token_passphrase" ]; then TOKEN_PASSPHRASE=$_token_passphrase; fi
}

# Verify system
verify_system() {
  assert_cmd mktemp
  assert_cmd ssh-keygen

  [ -n "$SSH_PASSPHRASE" ] || FATAL "SSH passphrase is required"
  [ -n "$TOKEN_PASSPHRASE" ] || FATAL "Token passphrase is required"
  [ -d "$OUT_DIR" ] || FATAL "Output directory '$OUT_DIR' is invalid"
}

# Setup system
setup_system() {
  # Temporary directory
  TMP_DIR=$(mktemp --directory)
  DEBUG "Created temporary directory '$TMP_DIR'"
}

# SSH certificate
cert_ssh() {
  INFO "Generating SSH certificate"

  ssh-keygen -b "$SSH_BITS" -t rsa -f "$TMP_DIR/$SSH_NAME.key" -N "$SSH_PASSPHRASE"
  mv "$TMP_DIR/$SSH_NAME.key.pub" "$TMP_DIR/$SSH_NAME.pub"
  chmod 600 "$TMP_DIR/$SSH_NAME.key" "$TMP_DIR/$SSH_NAME.pub"
}

# Token certificate
cert_token() {
  INFO "Generating Token certificate"

  ssh-keygen -b "$TOKEN_BITS" -t rsa -f "$TMP_DIR/$TOKEN_NAME.key" -N "$TOKEN_PASSPHRASE" -m PEM
  ssh-keygen -e -m PEM -f "$TMP_DIR/$TOKEN_NAME.key" -P "$TOKEN_PASSPHRASE" > "$TMP_DIR/$TOKEN_NAME.pub"
  rm "$TMP_DIR/$TOKEN_NAME.key.pub"
  chmod 600 "$TMP_DIR/$TOKEN_NAME.key" "$TMP_DIR/$TOKEN_NAME.pub"
}

# Move certificates
move_certs() {
  DEBUG "Moving certificates from '$TMP_DIR' to '$OUT_DIR'"

  set +o noglob
  mv "$TMP_DIR"/* "$OUT_DIR"
  set -o noglob
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  cert_ssh
  cert_token
  move_certs
}
