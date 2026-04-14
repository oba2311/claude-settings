#!/bin/bash
# PostToolUse hook: auto-commits any change to ~/.claude/ after Claude writes/edits a file there.

set -e

HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only proceed if the file is inside ~/.claude/
if [[ "$FILE_PATH" != "$HOME/.claude/"* ]]; then
  exit 0
fi

cd "$HOME/.claude"

git add -A
git diff --cached --quiet && exit 0  # nothing changed

FILENAME=$(basename "$FILE_PATH")
git commit -m "sync: $FILENAME"
git push origin main

exit 0
