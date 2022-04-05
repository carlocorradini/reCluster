#!/usr/bin/env bash

# Current directory
DIRNAME="$(dirname "$(readlink -f "$0")")"
readonly DIRNAME
# Apollo Router version
readonly APOLLO_ROUTER_VERSION="v0.1.0-preview.2"

# Commons
source "$DIRNAME/__commons.sh"

# Assert
assert_tool docker

# Apollo Router
INFO "Starting Apollo Router $APOLLO_ROUTER_VERSION"
docker run \
  -p 4000:4000 \
  --mount "type=bind,source=$DIRNAME/../router/router.yaml,target=/dist/config/router.yaml" \
  --mount "type=bind,source=$DIRNAME/../router/supergraph.graphql,target=/dist/config/supergraph.graphql" \
  --rm \
  "ghcr.io/apollographql/router:$APOLLO_ROUTER_VERSION" \
  --config config/router.yaml \
  --supergraph config/supergraph.graphql
