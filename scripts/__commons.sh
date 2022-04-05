#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$(readlink -f "$0")")"
readonly __DIRNAME

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Prevents errors in a pipeline from being masked
set -o pipefail
# Disable wildcard character expansion
set -o noglob

# Logger
source "$__DIRNAME/__logger.sh"
# Default log level
B_LOG --log-level 500

# Check installed tool
function assert_tool() {
    command -v "$1" >/dev/null 2>&1 || { FATAL "'$1' is not installed"; exit 1; }
    DEBUG "'$1' found at $(command -v "$1")"
}
