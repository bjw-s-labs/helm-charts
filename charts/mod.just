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

[doc('Build the helm-schema-tools binary')]
build-tools:
  #!/usr/bin/env bash
  set -euo pipefail
  TOOL_DIR="{{ justfile_dir() }}/tools/helm-schema-tools"
  just log info "Building helm-schema-tools..."
  cd "$TOOL_DIR"
  go build -o helm-schema-tools ./cmd/helm-schema-tools

[doc('Generate values.yaml from JSON schema')]
generate-values CHART="library/common": build-tools
  #!/usr/bin/env bash
  set -euo pipefail
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }
  echo "Generating values.yaml for $CHART_DIR..."
  cd "$CHART_DIR"
  "$REPO_ROOT/tools/helm-schema-tools/helm-schema-tools" generate values \
    --schema values.schema.json \
    --output values.yaml

[doc('Check that committed values.yaml is up-to-date with the schema')]
check-values CHART="library/common": build-tools
  #!/usr/bin/env bash
  set -euo pipefail
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  TOOL="$REPO_ROOT/tools/helm-schema-tools/helm-schema-tools"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }

  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  cd "$CHART_DIR"
  "$TOOL" generate values --schema values.schema.json --output "$TMPFILE"
  if ! diff -q values.yaml "$TMPFILE" > /dev/null 2>&1; then
    echo "values.yaml is out of date. Run: just chart::generate-values {{CHART}}"
    diff --color values.yaml "$TMPFILE" || true
    exit 1
  fi
  echo "values.yaml is up-to-date."

[doc('Run helm lint against the generated values.yaml via the chart test-harness')]
lint CHART="library/common":
  #!/usr/bin/env bash
  set -euo pipefail
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }

  CHART_TYPE="$(yq eval '.type // "application"' "$CHART_DIR/Chart.yaml")"
  if [ "$CHART_TYPE" = "library" ]; then
    TEST_DIR="$CHART_DIR/test-chart"
  else
    TEST_DIR="$CHART_DIR"
  fi
  [ -d "$TEST_DIR" ] || { echo "Test chart directory not found: $TEST_DIR"; exit 1; }

  just log info "Dereferencing values schema"
  cp "$CHART_DIR/values.schema.json" "$CHART_DIR/values.schema.bak"
  trap 'mv "$CHART_DIR/values.schema.bak" "$CHART_DIR/values.schema.json"' EXIT
  schematools-cli process dereference "$CHART_DIR/values.schema.json" --to-file "$CHART_DIR/values.schema.json"

  just log info "Rebuilding chart dependencies"
  ( cd "$TEST_DIR" && helm dep update 2> >(grep -v 'found symbolic link' >&2) >/dev/null )

  just log info "Running helm lint" "chart" "$CHART_DIR"
  helm lint "$TEST_DIR" -f "$CHART_DIR/values.yaml" 2> >(grep -v 'found symbolic link' >&2)
