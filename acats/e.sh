#!/usr/bin/env bash

for zip in *.zip; do
  [ -e "$zip" ] || continue
  tmpdir=$(mktemp -d)
  unzip -q "$zip" -d "$tmpdir"
  # move contents of the first (outer) directory into current dir
  inner=$(find "$tmpdir" -mindepth 1 -maxdepth 1)
  mv "$inner"/* .
  rm -rf "$tmpdir"
done
