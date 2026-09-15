set quiet := true
set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
  just -l chart

[doc('Run ct lint --config .ci/ct/ct.yaml --charts charts/CHART')]
lint CHART:
  #!/usr/bin/env bash
  set -euo pipefail
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }
  BACKUP_DIR="$(mktemp -d)"
  cp -a "$CHART_DIR" "$BACKUP_DIR/chart"
  restore() { status=$?; rm -rf "$CHART_DIR"; cp -a "$BACKUP_DIR/chart" "$CHART_DIR"; rm -rf "$BACKUP_DIR"; exit "$status"; }
  trap restore EXIT
  python3 "$REPO_ROOT/.ci/scripts/prepare-schema-refs.py" --repository bjw-s-labs/helm-charts --root "$REPO_ROOT" --path "charts/{{CHART}}"
  if [[ -n "${COMMON_LIBRARY_LOCATION:-}" ]]; then
    ( cd "$CHART_DIR" && bash "$REPO_ROOT/.ci/scripts/use-local-common.sh" )
  fi
  schematools-cli process dereference "$CHART_DIR/values.schema.json" --to-file "$CHART_DIR/values.schema.json"
  ( cd "$REPO_ROOT" && ct lint --config .ci/ct/ct.yaml --charts "charts/{{CHART}}" )

[doc('Run helm unittest -f "unittests/GLOB" against the chart test harness')]
unit-test CHART GLOB="**/*_test.yaml":
  #!/usr/bin/env bash
  set -euo pipefail
  PLUGIN_VERSION="1.1.2"
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }
  CHART_TYPE="$(yq eval '.type // "application"' "$CHART_DIR/Chart.yaml")"
  if [ "$CHART_TYPE" = "library" ]; then TEST_CHART="$CHART_DIR/test-chart"; else TEST_CHART="$CHART_DIR"; fi
  [ -d "$TEST_CHART" ] || { echo "Test chart directory not found: $TEST_CHART"; exit 1; }
  BACKUP_DIR="$(mktemp -d)"
  cp -a "$CHART_DIR" "$BACKUP_DIR/chart"
  restore() { status=$?; rm -rf "$CHART_DIR"; cp -a "$BACKUP_DIR/chart" "$CHART_DIR"; rm -rf "$BACKUP_DIR"; exit "$status"; }
  trap restore EXIT
  python3 "$REPO_ROOT/.ci/scripts/prepare-schema-refs.py" --repository bjw-s-labs/helm-charts --root "$REPO_ROOT" --path "charts/{{CHART}}"
  if [[ -n "${COMMON_LIBRARY_LOCATION:-}" ]]; then
    ( cd "$TEST_CHART" && bash "$REPO_ROOT/.ci/scripts/use-local-common.sh" )
  fi
  schematools-cli process dereference "$CHART_DIR/values.schema.json" --to-file "$CHART_DIR/values.schema.json"
  if ! helm plugin list | awk -v version="$PLUGIN_VERSION" '$1 == "unittest" && $2 == version { found=1 } END { exit !found }'; then
    helm plugin uninstall unittest || true
    helm plugin install https://github.com/helm-unittest/helm-unittest.git --version "v${PLUGIN_VERSION}" --verify=false
  fi
  ( cd "$TEST_CHART" && helm dep update )
  ( cd "$TEST_CHART" && helm unittest -f "unittests/{{GLOB}}" . )

[doc('Run ct install --config .ci/ct/ct.yaml --charts TEST_CHART')]
integration-test CHART:
  #!/usr/bin/env bash
  set -euo pipefail
  REPO_ROOT="{{ justfile_dir() }}"
  CHART_DIR="$REPO_ROOT/charts/{{CHART}}"
  [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }
  CHART_TYPE="$(yq eval '.type // "application"' "$CHART_DIR/Chart.yaml")"
  if [ "$CHART_TYPE" = "library" ]; then TEST_CHART="$CHART_DIR/test-chart"; TEST_CHART_RELATIVE="charts/{{CHART}}/test-chart"; else TEST_CHART="$CHART_DIR"; TEST_CHART_RELATIVE="charts/{{CHART}}"; fi
  [ -d "$TEST_CHART" ] || { echo "Test chart directory not found: $TEST_CHART"; exit 1; }
  BACKUP_DIR="$(mktemp -d)"
  cp -a "$CHART_DIR" "$BACKUP_DIR/chart"
  restore() { status=$?; rm -rf "$CHART_DIR"; cp -a "$BACKUP_DIR/chart" "$CHART_DIR"; rm -rf "$BACKUP_DIR"; exit "$status"; }
  trap restore EXIT
  python3 "$REPO_ROOT/.ci/scripts/prepare-schema-refs.py" --repository bjw-s-labs/helm-charts --root "$REPO_ROOT" --path "charts/{{CHART}}"
  if [[ -n "${COMMON_LIBRARY_LOCATION:-}" ]]; then
    ( cd "$TEST_CHART" && bash "$REPO_ROOT/.ci/scripts/use-local-common.sh" )
  fi
  schematools-cli process dereference "$CHART_DIR/values.schema.json" --to-file "$CHART_DIR/values.schema.json"
  ( cd "$REPO_ROOT" && ct install --config .ci/ct/ct.yaml --charts "$TEST_CHART_RELATIVE" )

[doc('DEPRECATED: alias for chart::unit-test with the same chart and glob')]
test CHART GLOB="**/*_test.yaml":
  just chart::unit-test "{{CHART}}" "{{GLOB}}"

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
