#!/usr/bin/env bash
# Install (or refresh) the pr-review kit in a project.
#
#   ./install.sh <project-root>
#
# Copies the reviewer subagent, the /pr-review command, the posting script and the reminder hook
# into <project>/.claude/, registers the hook in <project>/.claude/settings.json without removing
# existing hooks, and scaffolds the review rules and the gh setup note only when absent.
# Safe to run repeatedly. Everything it writes belongs in the repository.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-}"

if [ -z "$PROJECT" ] || [ ! -d "$PROJECT" ]; then
  echo "usage: $0 <project-root>" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"
say() { printf '  %s\n' "$*"; }

echo "pr-review -> $PROJECT"

mkdir -p "$PROJECT/.claude/agents" "$PROJECT/.claude/commands" "$PROJECT/.claude/hooks" "$PROJECT/.claude/scripts"
cp "$KIT/agents/pr-reviewer.md" "$PROJECT/.claude/agents/pr-reviewer.md"
cp "$KIT/commands/pr-review.md" "$PROJECT/.claude/commands/pr-review.md"
cp "$KIT/scripts/pr-review-post.sh" "$PROJECT/.claude/scripts/pr-review-post.sh"
cp "$KIT/hooks/pr-review-reminder.sh" "$PROJECT/.claude/hooks/pr-review-reminder.sh"
chmod +x "$PROJECT/.claude/scripts/pr-review-post.sh" "$PROJECT/.claude/hooks/pr-review-reminder.sh"
say "agent    .claude/agents/pr-reviewer.md"
say "command  .claude/commands/pr-review.md"
say "script   .claude/scripts/pr-review-post.sh"
say "hook     .claude/hooks/pr-review-reminder.sh"

SETTINGS="$PROJECT/.claude/settings.json"
SNIPPET="$(cat "$KIT/hooks/settings.hooks.json")"
if ! command -v jq >/dev/null 2>&1; then
  say "settings jq not found: add this PostToolUse hook to $SETTINGS by hand:"
  printf '%s\n' "$SNIPPET"
elif [ ! -f "$SETTINGS" ]; then
  printf '%s\n' "$SNIPPET" > "$SETTINGS"
  say "settings .claude/settings.json created with the PostToolUse hook"
elif jq -e '[.hooks.PostToolUse[]?.hooks[]?.command // "" | select(contains("pr-review-reminder.sh"))] | length > 0' "$SETTINGS" >/dev/null; then
  say "settings hook already registered (unchanged)"
else
  ENTRY="$(printf '%s' "$SNIPPET" | jq '.hooks.PostToolUse[0]')"
  TMP="$(mktemp)"
  jq --argjson entry "$ENTRY" '.hooks = (.hooks // {}) | .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [$entry])' "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
  say "settings hook appended to existing .claude/settings.json"
fi

cp "$KIT/templates/pr-review-gh-setup.md" "$PROJECT/.claude/pr-review-gh-setup.md"
say "doc      .claude/pr-review-gh-setup.md"
if [ -f "$PROJECT/.claude/pr-review-rules.md" ]; then
  say "config   .claude/pr-review-rules.md exists (left untouched)"
else
  cp "$KIT/templates/pr-review-rules.template.md" "$PROJECT/.claude/pr-review-rules.md"
  say "config   .claude/pr-review-rules.md scaffolded from the template"
fi

cat <<EOF

Next steps (or run /pr-review-init in Claude Code, which does them):
  1. Fill .claude/pr-review-rules.md with what matters in this project's reviews.
  2. Make sure gh is authenticated: gh auth status (see .claude/pr-review-gh-setup.md).
  3. Run /pr-review <number> on an open pull request.
  4. Commit .claude/ so colleagues get the reviewer, the command and the script by cloning.
EOF
