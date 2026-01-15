#!/usr/bin/env bash
set -euo pipefail

: "${MIN_K8S_VERSION:?MIN_K8S_VERSION is required}"

if [[ ! "${MIN_K8S_VERSION}" =~ ^v?([0-9]+)\.([0-9]+) ]]; then
  echo "Invalid minimum version: ${MIN_K8S_VERSION}" >&2
  exit 1
fi
MIN_MAJOR="${BASH_REMATCH[1]}"
MIN_MINOR="${BASH_REMATCH[2]}"

versions_json="$(
  gh release list \
    --repo k3s-io/k3s \
    --limit 300 \
    --json tagName,publishedAt,isDraft,isPrerelease \
  | jq \
      --arg min_major "${MIN_MAJOR}" \
      --arg min_minor "${MIN_MINOR}" \
      '
        def parsed($t):
          ($t | capture("^v?(?<maj>\\d+)\\.(?<min>\\d+)\\.(?<patch>\\d+)")?);

        map(select(.isDraft == false))
        | map(select(.isPrerelease == false))
        | map(. + (parsed(.tagName) // {}))
        | map(select(has("maj")))
        | map(select(
            (.maj|tonumber > ($min_major|tonumber))
            or
            ((.maj|tonumber == ($min_major|tonumber)) and (.min|tonumber >= ($min_minor|tonumber)))
          ))
        | sort_by(.publishedAt)
        | group_by(.maj + "." + .min)
        | map(.[-1])
        | map({
            k8s_version: ("v" + .maj + "." + .min + "." + .patch),
            k3s_tag: (.tagName | gsub("\\+"; "-"))
          })
      '
)"

echo "${versions_json}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "versions=${versions_json}" >> "${GITHUB_OUTPUT}"
fi
