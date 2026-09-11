#!/usr/bin/env python3
"""Rewrite repository schema URLs to the immutable pull request revision."""

import argparse
import re
from pathlib import Path


def rewrite_schema_refs(root: Path, path: str, repository: str, revision: str) -> int:
    schema_root = (root / path).resolve()
    url_pattern = re.compile(
        rb"(https://raw\.githubusercontent\.com/"
        + re.escape(repository.encode("ascii"))
        + rb"/)[^/\"']+(/)"
    )
    changed = 0
    for schema_file in schema_root.rglob("*.json"):
        if not schema_file.is_file():
            continue
        original = schema_file.read_bytes()
        rewritten = url_pattern.sub(
            rb"\g<1>" + revision.encode("ascii") + rb"\g<2>", original
        )
        if rewritten != original:
            schema_file.write_bytes(rewritten)
            changed += 1
    return changed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--path", default="charts")
    args = parser.parse_args()
    rewrite_schema_refs(args.root, args.path, args.repository, args.revision)


if __name__ == "__main__":
    main()
