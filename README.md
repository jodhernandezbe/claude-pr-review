# claude-pr-review

Reviews a pull request from the command line, inside Claude Code: an independent reviewer reads
the diff, you answer its questions about anything suspicious, and the agreed comments are posted
to GitHub from your own account. Approval is yours, every time.

This is not the security audit. That is a separate kit (`claude-security-audit`) with its own
auditor and its own gate. This one covers correctness, contracts, project conventions, tests,
data modelling and efficiency that matters at real scale.

## The pieces

| Piece | File | What it does |
| --- | --- | --- |
| Reviewer subagent | `.claude/agents/pr-reviewer.md` | Read-only, separate context. Reports findings anchored to `file:line` with a concrete failure, and raises up to five questions only the author can answer. |
| Command | `.claude/commands/pr-review.md` | `/pr-review <number>`: reads the pull request, dispatches the reviewer, asks you about the suspicious things, shows the exact comments, posts and optionally approves. |
| Posting script | `.claude/scripts/pr-review-post.sh` | Posts the review through `gh`. Checks every comment anchors to a line the diff touches and moves the rest into the review body. |
| Reminder hook | `.claude/hooks/pr-review-reminder.sh` | After a push or `gh pr create`, one line reminding that `/pr-review` exists. It never posts anything. |

Plus `pr-review-rules.md` (what matters in this project's reviews) and `pr-review-gh-setup.md`
(the one-time GitHub CLI setup for each reviewer).

## The one command

Once per machine, link the user-level init command:

```sh
ln -sf ~/Documents/claude-pr-review/user-command/pr-review-init.md ~/.claude/commands/pr-review-init.md
```

It is a symlink, so editing the kit updates the command everywhere. A new command appears in the
next Claude Code session.

On Windows, copy instead of linking (`cp user-command/*.md ~/.claude/commands/` from Git
Bash) and re-copy after kit changes. See **Windows** below.


Then, in any project:

```
/pr-review-init
```

It runs the installer, writes the review rules from the project's own conventions, checks the
GitHub CLI, proves the path as far as a dry run, and lists the files to commit.

## Install by hand

```sh
./install.sh /path/to/project
```

Then fill `.claude/pr-review-rules.md`, check `gh auth status`, and commit `.claude/`. In Claude
Code, `/pr-review-init` does all of it, including writing the rules from the project's own
conventions.

**Start a new Claude Code session before the first review**: subagents in `.claude/agents/` are
discovered at session start, so the reviewer is not dispatchable in the session that installed
it.

Colleagues get the reviewer, the command and the script by cloning. Each of them runs
`gh auth login` once on their own machine, because a review is posted from a real account.

## The human stays in the loop

This is the part that matters, and it is enforced in the command, not left to good intentions:

- The reviewer subagent cannot post. It has no write path at all.
- Nothing reaches GitHub until you have seen the exact text of every comment.
- Questions come to you **before** anything is drafted, so an explanation you give never becomes
  a public comment.
- Approval is never chosen by the agent. You pick comment, approve, request changes or post
  nothing, in that turn.
- The dry run shows the full payload before it is sent.

An approval posted this way is your signature on the change. It does not bypass branch
protection, required reviewers or code owners.

**You cannot give a verdict on your own pull request.** GitHub rejects both approval and a
request for changes when the author and the reviewing account are the same, with a 422. The
script checks this before sending and says so; the findings still post as a comment with the
intended verdict stated in the body. Testing the workflow on your own pull request therefore
exercises everything except the verdict.

## Why a separate reviewer

A model that just wrote the code is the worst judge of it, and a model handed a conclusion
returns it confirmed. The reviewer gets the diff, the repository and the project's rules, and
nothing of the conversation that produced the change. The command says so explicitly and
forbids reviewing the diff in parallel with the dispatch.

## Keeping the comments worth reading

A review that comments on everything gets skimmed. The reviewer is told to anchor every finding
to a line, name a concrete failure, and cite a project rule or a neighbouring pattern rather than
taste. Formatting and lint are excluded by default because a tool already owns them. When a
class of comment turns out to be noise here, add a line to `.claude/pr-review-rules.md` saying so
and why.

## Windows

Everything here is shell scripts, so Windows needs a bash. Git for Windows provides one, and
Claude Code works with it. WSL also works and behaves like Linux throughout.

**1. Install the prerequisites.** [Git for Windows](https://gitforwindows.org/) gives you Git
Bash plus `sed`, `awk`, `grep`, `cut`, `mktemp` and `xargs`. Add `jq` as well
(`winget install jqlang.jq`): the scripts fall back to text parsing without it, but the
installer cannot merge hook settings and will print a snippet for you to paste instead.

**2. Run the installer from Git Bash,** not PowerShell or `cmd`:

```sh
./install.sh /c/Users/you/code/your-project
```

Git Bash paths start `/c/` rather than `C:\`.

**3. Link the init command by copying it.** `ln -sf` needs Developer Mode or an elevated shell
on Windows, so copy instead, from Git Bash:

```sh
cp user-command/*.md ~/.claude/commands/
```

A copy does not track kit updates the way a symlink does, so re-run that `cp` after you change
the kit. If you would rather have a real link, PowerShell as administrator can make one:

```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\.claude\commands\<name>.md" -Target "<kit>\user-command\<name>.md"
```

**4. Hooks need `bash` on the system PATH.** The hook entries run
`bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<script>.sh"`. Git Bash installs `bash.exe` under
`C:\Program Files\Git\bin`; if that is not on PATH, the hook silently does nothing. Check from
PowerShell with `where.exe bash`, and add that folder to PATH if it is missing.

**5. Line endings.** If `core.autocrlf` rewrites the scripts to CRLF, bash fails with
`bad interpreter: /usr/bin/env bash^M`. The kit ships a `.gitattributes` that keeps `*.sh` as LF.
If you hit it anyway, run `git config core.autocrlf input` and re-checkout.

## Limits

- GitHub only. The review API it posts to has no equivalent elsewhere.
- It reads code; it does not run it or check out the branch.
- It does not merge, and does not offer to.
- A very large pull request is reviewed in parts, and the parts can miss an interaction between
  them. The report says what was not reviewed.
