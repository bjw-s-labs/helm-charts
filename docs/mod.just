set quiet := true
set shell := ["bash", "-euo", "pipefail", "-c"]

REPO_ROOT := justfile_dir()
DOCS_DIR := REPO_ROOT + "/docs"

[doc('Install bun dependencies')]
install:
    cd {{ DOCS_DIR }} && bun install

[doc('Start dev server')]
serve: install generate
    cd {{ DOCS_DIR }} && bun run dev

[doc('Build static site')]
build: install generate
    cd {{ DOCS_DIR }} && bun run build

[doc('Preview production build')]
preview: build generate
    cd {{ DOCS_DIR }} && bun run preview

[doc('Generate reference docs and schema from JSON schema')]
generate CHART="library/common":
    #!/usr/bin/env bash
    set -euo pipefail
    REPO_ROOT="{{ REPO_ROOT }}"
    CHART_DIR="$REPO_ROOT/charts/{{ CHART }}"
    REFERENCE_DIR="{{ DOCS_DIR }}/src/content/docs/app-template/reference"
    SCHEMA_DIR="{{ DOCS_DIR }}/public/schemas"
    TOOL="$REPO_ROOT/tools/helm-schema-tools/helm-schema-tools"

    [ -d "$CHART_DIR" ] || { echo "Chart directory not found: $CHART_DIR"; exit 1; }
    [ -x "$TOOL" ] || { echo "Build the Go tool first: cd tools/helm-schema-tools && go build -o helm-schema-tools ./cmd/helm-schema-tools/"; exit 1; }

    echo "Dereferencing schema to public/schemas..."
    mkdir -p "$SCHEMA_DIR"
    schematools-cli process dereference "$CHART_DIR/values.schema.json" \
      --to-file "$SCHEMA_DIR/values.schema.json"

    echo "Generating reference docs..."
    "$TOOL" generate docs \
      --schema "$CHART_DIR/values.schema.json" \
      --output "$REFERENCE_DIR"

    # Generate llms.txt
    echo "Generating llms.txt..."
    "$TOOL" generate llms-txt \
      --schema "$CHART_DIR/values.schema.json" \
      --output "{{ DOCS_DIR }}/public/llms.txt" \
      --base-url "https://bjw-s-labs.github.io/helm-charts/docs"

    echo "Done."
