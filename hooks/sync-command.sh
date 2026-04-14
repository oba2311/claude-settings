#!/bin/bash
# Triggered after Claude writes/edits a file in ~/.claude/commands/
# Generalizes the file using Claude CLI, then syncs to claude-settings repo

set -e

HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only proceed if file is in ~/.claude/commands/
if [[ "$FILE_PATH" != "$HOME/.claude/commands/"* ]]; then
  exit 0
fi

# Only process .md files
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")
REPO_DIR="$HOME/.claude-settings-repo"
DEST="$REPO_DIR/commands/$FILENAME"

# Generalize using Claude CLI
GENERALIZED=$(claude -p "You are generalizing a Claude Code slash command for reuse across projects. Read the following command file and rewrite it with all project-specific references removed or replaced with generic placeholders. Keep the structure, intent, and instructions intact. Output only the file content, no commentary.

$(cat "$FILE_PATH")" 2>/dev/null)

if [ -z "$GENERALIZED" ]; then
  # Fallback: copy as-is if Claude CLI fails
  cp "$FILE_PATH" "$DEST"
else
  echo "$GENERALIZED" > "$DEST"
fi

# Commit and push
cd "$REPO_DIR"
git add "commands/$FILENAME"
git diff --cached --quiet && exit 0  # nothing changed, skip
git commit -m "sync: add/update command $FILENAME"
git push origin main

exit 0
