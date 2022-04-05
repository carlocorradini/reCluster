#!/usr/bin/env bash

# Current directory
DIRNAME="$(dirname "$(readlink -f "$0")")"
readonly DIRNAME
# Supergraph input
readonly SUPERGRAPH_INPUT="$DIRNAME/../router/supergraph.yaml"
# Supergraph output
readonly SUPERGRAPH_OUTPUT="$DIRNAME/../router/supergraph.graphql"

# Commons
source "$DIRNAME/__commons.sh"

# Assert
assert_tool rover

# Rover
INFO "Generating supergraph '$SUPERGRAPH_OUTPUT' from '$SUPERGRAPH_INPUT'"
rover fed2 supergraph compose --config "$SUPERGRAPH_INPUT" > "$SUPERGRAPH_OUTPUT"
