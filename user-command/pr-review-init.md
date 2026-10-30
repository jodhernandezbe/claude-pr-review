---
description: Incorporate the pull request review workflow into the current project (reviewer subagent, /pr-review, posting script, review rules), committed so every colleague gets it by cloning
---

Incorporate the pr-review kit from `~/Documents/claude-pr-review` into the project in the
current working directory. Everything lands inside the project and is meant to be committed, so
colleagues need to install nothing beyond the GitHub CLI on their own machine.

1. **Check the repository has a GitHub remote.** `git remote -v` and `gh repo view` (if `gh` is
   installed). If the project is not on GitHub, say so and stop: this kit posts through
   GitHub's review API and has nothing to offer elsewhere.

2. **Run the installer**: `~/Documents/claude-pr-review/install.sh "$PWD"`. Report what it
   printed.

3. **Tell the user the subagent needs a new session.** Claude Code discovers `.claude/agents/`
   at session start, so `pr-reviewer` is not dispatchable in the session that installed it.
   Everything else, including the posting script's dry run, works immediately.

4. **Check the GitHub CLI.** Run `gh auth status`. If it is missing or unauthenticated, tell the
   user to run `! gh auth login` themselves and point at `.claude/pr-review-gh-setup.md`. Do not
   attempt the login. Everything else below works without it; only posting needs it.

5. **Fill the review rules.** Read the project's `CLAUDE.md`, its folder rules, its linter and
   formatter configuration, and a sample of recent pull request comments if any exist. From
   those write `.claude/pr-review-rules.md`: what matters most here, where the conventions live
   so a finding can cite a rule, what not to comment on (anything a tool already owns), and who
   may approve what. Show it to the user and **ask them to confirm** before going on.

6. **Prove the path works, without posting.** Pick an open pull request, or the most recent
   merged one if none is open. Run `/pr-review <number>` as far as the dry run: the reviewer's
   report, the questions, the proposed comments, and
   `.claude/scripts/pr-review-post.sh <pr> <payload> --dry-run`. Stop there and show the result.
   Post only if the user asks.

7. **Hand over.** List the files to commit (`.claude/agents/pr-reviewer.md`,
   `.claude/commands/pr-review.md`, `.claude/scripts/pr-review-post.sh`,
   `.claude/hooks/pr-review-reminder.sh`, `.claude/settings.json`,
   `.claude/pr-review-rules.md`, `.claude/pr-review-gh-setup.md`). Do not commit unless asked.
   Mention that each colleague needs `gh auth login` once on their own machine, and that reviews
   post from whichever account is authenticated there.
