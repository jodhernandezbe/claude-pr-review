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

## Install

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

## Limits

- GitHub only. The review API it posts to has no equivalent elsewhere.
- It reads code; it does not run it or check out the branch.
- It does not merge, and does not offer to.
- A very large pull request is reviewed in parts, and the parts can miss an interaction between
  them. The report says what was not reviewed.
