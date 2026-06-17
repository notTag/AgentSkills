#!/usr/bin/env bash
# Bootstrap global Claude config onto a machine.
# Symlinks ~/.claude/{CLAUDE,RTK}.md to this repo's globalAgentMDs/ so the
# repo is the single source of truth: edit here, every machine follows.
# Re-runnable. Backs up any existing real file to *.bak-<ts> before linking.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/globalAgentMDs" && pwd)"
DEST="$HOME/.claude"
TS="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DEST"

link() {
  local target="$1" linkpath="$2"
  if [[ -e "$linkpath" && ! -L "$linkpath" ]]; then
    mv "$linkpath" "$linkpath.bak-$TS"
    echo "  backed up existing $linkpath -> $linkpath.bak-$TS"
  fi
  ln -sfn "$target" "$linkpath"
  echo "  linked $linkpath -> $target"
}

link "$SRC/CLAUDE.md" "$DEST/CLAUDE.md"
link "$SRC/RTK.md"    "$DEST/RTK.md"

echo "Done. Source of truth: $SRC"
