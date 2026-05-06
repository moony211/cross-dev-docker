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
  "qt-host/6.7.3 qt-host-6.7.3"
  "qt-host/6.8.3 qt-host-6.8.3"
  "qt-target/6.7.3 qt-6.7.3-arm"
  "qt-target/6.8.3 qt-6.8.3-arm"
  "target-rfs deepstream7.1-arm"
)

# Build specific targets if provided as arguments, otherwise build all
targets_to_build=()
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    for entry in "${build_targets[@]}"; do
      path="${entry%% *}"
      if [[ "${path}" == "${arg}" ]]; then
        targets_to_build+=("${entry}")
      fi
    done
  done
  if [[ ${#targets_to_build[@]} -eq 0 ]]; then
    echo "No matching targets found for arguments: $*"
    exit 1
  fi
else
  targets_to_build=("${build_targets[@]}")
fi

for entry in "${targets_to_build[@]}"; do
  path="${entry%% *}"
  repo="${entry##* }"

  # Determine tag: Use VERSION file if it exists, otherwise use global IMAGE_TAG
  current_tag="${IMAGE_TAG}"
  if [[ -f "${path}/VERSION" ]]; then
    current_tag=$(cat "${path}/VERSION")
    # Handle optional subdirectory version in repo name (e.g., qt-host:6.7.3 -> qt-host:6.7.3-v1.0)
    if [[ "${repo}" == *:* ]]; then
      image="${REGISTRY_HOST}/${repo}-${current_tag}"
    else
      image="${REGISTRY_HOST}/${repo}:${current_tag}"
    fi
  else
    image="${REGISTRY_HOST}/${repo}:${IMAGE_TAG}"
  fi

  echo "Building ${image} from ${path}/Dockerfile (Tag: ${current_tag})"
  run docker build --pull -f "${path}/Dockerfile" -t "${image}" "${path}"
  echo "Pushing ${image}"
  run docker push "${image}"
  echo
 done
