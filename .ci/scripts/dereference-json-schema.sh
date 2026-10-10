#!/usr/bin/env bash
set -euo pipefail

schema_file=''
output_file=''
allow_missing=false
schema_roots=()
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tool="$repo_root/tools/helm-schema-tools/helm-schema-tools"

usage() {
  printf 'Usage: %s --schema-file PATH --output-file PATH [--schema-root PATH]... [--allow-missing]\n' "$0" >&2
}

while (($# > 0)); do
  case "$1" in
    --schema-file)
      (($# >= 2)) || { usage; exit 2; }
      schema_file=$2
      shift 2
      ;;
    --output-file)
      (($# >= 2)) || { usage; exit 2; }
      output_file=$2
      shift 2
      ;;
    --schema-root)
      (($# >= 2)) || { usage; exit 2; }
      schema_roots+=("$2")
      shift 2
      ;;
    --allow-missing)
      allow_missing=true
      shift
      ;;
    --)
      shift
      (($# == 0)) || { usage; exit 2; }
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$schema_file" || -z "$output_file" ]]; then
  usage
  exit 2
fi

if [[ ! -f "$schema_file" ]]; then
  if [[ "$allow_missing" == true ]]; then
    exit 0
  fi
  printf 'Schema file not found: %s\n' "$schema_file" >&2
  exit 1
fi

if [[ ! -x "$tool" ]]; then
  printf 'Schema tool not found: %s\nBuild it with: just chart::build-tools\n' "$tool" >&2
  exit 1
fi

args=(dereference --schema "$schema_file" --output "$output_file")
for schema_root in "${schema_roots[@]}"; do
  args+=(--schema-root "$schema_root")
done

exec "$tool" "${args[@]}"
