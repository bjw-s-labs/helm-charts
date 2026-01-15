set quiet := true
set shell := ["bash", "-euo", "pipefail", "-c"]

# Static vars
export REPO_CONFIG_FILE := justfile_dir() + "/.ci/repo-config.yaml"

[private]
default:
  just -l chart

[doc('Test a chart')]
test CHART GLOB="**/*_test.yaml":
  #!/usr/bin/env bash
  set -euo pipefail
  CHART_DIR="{{ justfile_dir() }}/charts/{{CHART}}"
  [ -d "$CHART_DIR" ]
  CHART_TYPE="$(yq eval '.type // "application"' "$CHART_DIR/Chart.yaml")"
  if [ "$CHART_TYPE" = "library" ]; then
    CHART_TEST_DIR="$CHART_DIR/test-chart"
  else
    CHART_TEST_DIR="$CHART_DIR"
  fi
  [ -d "$CHART_TEST_DIR" ]
  just log info "Testing chart..." "chart" "$CHART_DIR" "type" "$CHART_TYPE"
  just log debug "Dereferencing values schema"
  cp "$CHART_DIR/values.schema.json" "$CHART_DIR/values.schema.bak"
  trap 'mv "$CHART_DIR/values.schema.bak" "$CHART_DIR/values.schema.json"' EXIT
  schematools-cli process dereference "$CHART_DIR/values.schema.json" --to-file "$CHART_DIR/values.schema.json"
  just log debug "Updating helm dependencies"
  ( cd "$CHART_TEST_DIR" && helm dep update )
  just log debug "Running helm unit tests"
  ( cd "$CHART_TEST_DIR" && helm unittest -f "unittests/{{GLOB}}" . 2> >(grep -v 'found symbolic link' >&2))

[doc('Clean up chart dependency artifacts (Chart.lock files and nested charts/ dirs)')]
cleanup:
    @find charts/ -mindepth 1 -type f -name 'Chart.lock' -print0 | xargs -0 rm -f
    @find charts/ -mindepth 1 -type d -name charts -print0 | xargs -0 rm -rf
