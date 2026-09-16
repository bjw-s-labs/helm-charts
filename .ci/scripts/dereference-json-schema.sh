#!/usr/bin/env bash
set -euo pipefail

schema_file=''
output_file=''
allow_missing=false

usage() {
  printf 'Usage: %s --schema-file PATH --output-file PATH [--allow-missing]\n' "$0" >&2
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

exec schematools-cli process dereference "$schema_file" --to-file "$output_file"
