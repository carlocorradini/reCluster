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
# shellcheck source=./__commons.sh
. "$DIRNAME/__commons.sh"

# ================
# CONFIGURATION
# ================
# Output directory
OUT_DIR="./"
# SSH comment
SSH_COMMENT=""
# SSH key name
SSH_NAME="ssh"
# SSH passphrase
SSH_PASSPHRASE=
# SSH rounds
SSH_ROUNDS=256
# Token bits
TOKEN_BITS=4096
# Token comment
TOKEN_COMMENT=""
# Token key name
TOKEN_NAME="token"
# Token passphrase
TOKEN_PASSPHRASE=

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
        [--ssh-comment <COMMENT>] [--ssh-name <NAME>] --ssh-passphrase <PASSPHRASE> [--ssh-rounds <ROUNDS>]
        [--token-bits <BITS>] [--token-comment <COMMENT>] [--token-name <NAME>] --token-passphrase <PASSPHRASE>

$HELP_COMMONS_USAGE

reCluster certificates script.

Options:
  --help                           Show this help message and exit

  --out-dir <DIRECTORY>            Output directory
                                   Default: $OUT_DIR
                                   Values:
                                     Any valid directory

  --ssh-comment <COMMENT>          SSH comment
                                   Default: $SSH_COMMENT
                                   Values:
                                     Any valid comment

  --ssh-name <NAME>                SSH key name
                                   Default: $SSH_NAME
                                   Values:
                                     Any valid name

  --ssh-passphrase <PASSPHRASE>    SSH passphrase
                                   Values:
                                     Any valid passphrase

  --ssh-rounds <ROUNDS>            SSH rounds
                                   Default: $SSH_ROUNDS
                                   Values:
                                     Any valid number of rounds

  --token-bits <BITS>              Token bits
                                   Default: $TOKEN_BITS
                                   Values:
                                     Any valid number of bits

  --token-comment <COMMENT>        Token comment
                                   Default: $TOKEN_COMMENT
                                   Values:
                                     Any valid comment

  --token-name <NAME>              Token key name
                                   Default: $TOKEN_NAME
                                   Values:
                                     Any valid name

  --token-passphrase <PASSPHRASE>  Token passphrase
                                   Values:
                                     Any valid passphrase

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
      --out-dir)
        # Output directory
        parse_args_assert_value "$@"

        OUT_DIR=$2
        _shifts=2
        ;;
      --ssh-comment)
        # SSH comment
        parse_args_assert_value "$@"

        SSH_COMMENT=$2
        _shifts=2
        ;;
      --ssh-name)
        # SSH key name
        parse_args_assert_value "$@"

        SSH_NAME=$2
        _shifts=2
        ;;
      --ssh-passphrase)
        # SSH passphrase
        parse_args_assert_value "$@"

        SSH_PASSPHRASE=$2
        _shifts=2
        ;;
      --ssh-rounds)
        # SSH rounds
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$@"

        SSH_ROUNDS=$2
        _shifts=2
        ;;
      --token-bits)
        # Token bits
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$@"

        TOKEN_BITS=$2
        _shifts=2
        ;;
      --token-comment)
        # Token comment
        parse_args_assert_value "$@"

        TOKEN_COMMENT=$2
        _shifts=2
        ;;
      --token-name)
        # Token key name
        parse_args_assert_value "$@"

        TOKEN_NAME=$2
        _shifts=2
        ;;
      --token-passphrase)
        # Token passphrase
        parse_args_assert_value "$@"

        TOKEN_PASSPHRASE=$2
        _shifts=2
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
  assert_cmd mktemp
  assert_cmd ssh-keygen

  [ -n "$SSH_PASSPHRASE" ] || FATAL "SSH passphrase is required"
  [ -n "$TOKEN_PASSPHRASE" ] || FATAL "Token passphrase is required"
  [ -d "$OUT_DIR" ] || FATAL "Output directory '$OUT_DIR' does not exists"
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

  ssh-keygen -t ed25519 -a "$SSH_ROUNDS" -f "$TMP_DIR/$SSH_NAME.key" -N "$SSH_PASSPHRASE" -C "$SSH_COMMENT"
  mv "$TMP_DIR/$SSH_NAME.key.pub" "$TMP_DIR/$SSH_NAME.pub"
  chmod 600 "$TMP_DIR/$SSH_NAME.key" "$TMP_DIR/$SSH_NAME.pub"
}

# Token certificate
cert_token() {
  INFO "Generating Token certificate"

  ssh-keygen -t rsa -b "$TOKEN_BITS" -f "$TMP_DIR/$TOKEN_NAME.key" -N "$TOKEN_PASSPHRASE" -C "$TOKEN_COMMENT" -m PEM
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
