#!/bin/bash
# Regenerates the App Store screenshots from the app's real EyeballView drawing
# code. Requires Pillow (pip3 install pillow).
set -euo pipefail
cd "$(dirname "$0")"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cp render.swift "$TMP/main.swift"  # top-level code must live in main.swift
swiftc -O -o "$TMP/render" "$TMP/main.swift" ../../Sources/EyeballView.swift
RENDERER="$TMP/render" TMPDIR_RENDER="$TMP" python3 compose.py
