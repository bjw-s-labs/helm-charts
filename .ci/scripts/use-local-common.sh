#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${COMMON_LIBRARY_LOCATION:-}" ]]; then
  printf 'COMMON_LIBRARY_LOCATION is required\n' >&2
  exit 1
fi

if [[ ! -f Chart.yaml ]]; then
  printf 'Chart.yaml not found in current directory: %s\n' "$PWD" >&2
  exit 1
fi

yq -i '(.dependencies[] | select(.name == "common" and .repository == "https://bjw-s-labs.github.io/helm-charts")) |= (.version = ">0.0.0-0" | .repository = "file://" + strenv(COMMON_LIBRARY_LOCATION))' Chart.yaml

printf '::group::Modified Chart.yaml\n'
cat Chart.yaml
printf '::endgroup::\n'
