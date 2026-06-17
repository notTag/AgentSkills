#!/usr/bin/env bash
# Bootstrap global Claude config onto a new machine.
# Installs the committed global config into ~/.claude/ so agents run with
# the same rules everywhere. Re-runnable (overwrites the two target files).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude"

mkdir -p "$DEST"
cp "$DIR/global-CLAUDE.md" "$DEST/CLAUDE.md"
cp "$DIR/global-RTK.md"    "$DEST/RTK.md"

echo "Installed global config -> $DEST/"
echo "  CLAUDE.md ($(wc -l < "$DEST/CLAUDE.md") lines)"
echo "  RTK.md    ($(wc -l < "$DEST/RTK.md") lines)"
