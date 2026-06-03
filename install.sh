#!/usr/bin/env bash
# Install the llm-council skill into Claude Code (macOS / Linux).
# Usage:
#   ./install.sh
# Or one-liner (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/install.sh | bash
set -euo pipefail

SKILL_NAME="llm-council"
DEST="${HOME}/.claude/skills/${SKILL_NAME}"
RAW_BASE="https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/skills/${SKILL_NAME}"

echo "Installing the '${SKILL_NAME}' skill into Claude Code..."
mkdir -p "${DEST}"

# If run from inside a cloned repo, copy locally; otherwise download.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LOCAL_SRC="${SCRIPT_DIR}/skills/${SKILL_NAME}/SKILL.md"

if [[ -f "${LOCAL_SRC}" ]]; then
  cp "${LOCAL_SRC}" "${DEST}/SKILL.md"
  echo "Copied from local clone."
else
  curl -fsSL "${RAW_BASE}/SKILL.md" -o "${DEST}/SKILL.md"
  echo "Downloaded SKILL.md."
fi

echo ""
echo "✅ Installed to: ${DEST}/SKILL.md"
echo "Start a new Claude Code session, then type /${SKILL_NAME} or say 'convene the council on: <question>'."
