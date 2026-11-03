#!/usr/bin/env bash
# Run one headless Godot test script and fail on hidden engine errors.
# Godot keeps running after a GDScript runtime error, so a test can print PASS
# while _draw() or a format string silently failed. This wrapper treats those
# messages as failures. Usage: tools/run_godot_test.sh <godot-binary> <res://tests/x.gd>
set -uo pipefail
godot="$1"; script="$2"
log="$(mktemp)"
timeout 180s "$godot" --headless --path . --script "$script" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if grep -qE 'SCRIPT ERROR|Parse Error|String formatting error' "$log"; then
  echo "::error::$script produced Godot script/format errors:" >&2
  grep -nE -A1 'SCRIPT ERROR|Parse Error|String formatting error' "$log" | head -20 >&2
  status=1
fi
rm -f "$log"
exit "$status"
