#!/bin/bash
# Triggered after Claude writes/edits a skill file.
# Evaluates the new skill against existing projects and appends to skills_mapping.md memory.

set -e

HOOK_INPUT=$(cat)
FILE_PATH=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only proceed for skill files
if [[ "$FILE_PATH" != "$HOME/.claude/skills/"* ]] && [[ "$FILE_PATH" != "$HOME/.claude/plugins/"*"/SKILL.md" ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

MEMORY_FILE="$HOME/.claude/projects/-Users-obamain/memory/skills_mapping.md"
SKILL_CONTENT=$(cat "$FILE_PATH")
SKILL_NAME=$(basename "$(dirname "$FILE_PATH")")

# List projects dynamically
PROJECTS=$(ls -d "$HOME/projects"/*/ 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ')

EVALUATION=$(claude -p "You are updating a memory file that maps Claude Code skills to projects.

New skill name: $SKILL_NAME
Skill file content:
$SKILL_CONTENT

Existing projects: $PROJECTS

For each project, write one sentence on whether and how this skill applies. Be specific and actionable. If it doesn't apply, skip that project.

Output format (markdown list, no preamble):
## $SKILL_NAME (new skill — review and merge into skills_mapping.md)
- project-name: one sentence on how to use it
" 2>/dev/null)

if [ -n "$EVALUATION" ]; then
  echo "" >> "$MEMORY_FILE"
  echo "$EVALUATION" >> "$MEMORY_FILE"

  cd "$HOME/.claude"
  git add -A
  git diff --cached --quiet || git commit -m "sync: skills_mapping.md (new skill: $SKILL_NAME)" && git push origin main
fi

exit 0
