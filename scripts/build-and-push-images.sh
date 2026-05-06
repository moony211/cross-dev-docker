#!/usr/bin/env bash
set -euo pipefail

REGISTRY_HOST="${REGISTRY_HOST:-docker-reg.posod.com:5000}"
IMAGE_TAG="${IMAGE_TAG:-${TAG:-latest}}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${DRY_RUN}" != "0" && "${DRY_RUN}" != "false" ]]; then
  echo "DRY RUN: commands will be printed but not executed"
  dry_run=true
else
  dry_run=false
fi

run() {
  echo "+ $*"
  if [[ "${dry_run}" == false ]]; then
    "$@"
  fi
}

if [[ -n "${DOCKER_USERNAME}" && -n "${DOCKER_PASSWORD}" && "${dry_run}" == false ]]; then
  echo "Logging in to ${REGISTRY_HOST}"
  echo "${DOCKER_PASSWORD}" | docker login "${REGISTRY_HOST}" --username "${DOCKER_USERNAME}" --password-stdin
fi

build_targets=(
  "jetpack-cross-dev jetpack-cross-dev"
  "qt-host/6.7.3 qt-host:6.7.3"
  "qt-host/6.8.3 qt-host:6.8.3"
  "qt-target/6.7.3 qt-target:6.7.3"
  "qt-target/6.8.3 qt-target:6.8.3"
  "target-rfs target-rfs"
)

for entry in "${build_targets[@]}"; do
  path="${entry%% *}"
  repo="${entry##* }"
  image="${REGISTRY_HOST}/${repo}:${IMAGE_TAG}"
  echo "Building ${image} from ${path}/Dockerfile"
  run docker build --pull -f "${path}/Dockerfile" -t "${image}" "${path}"
  echo "Pushing ${image}"
  run docker push "${image}"
  echo
 done
