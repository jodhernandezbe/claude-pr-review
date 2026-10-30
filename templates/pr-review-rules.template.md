# Project review rules

Read by the `pr-reviewer` subagent and by `/pr-review`. Keep it short; it is applied on every
review.

## What matters most in this project

<!-- Two to five lines. The classes of defect that actually hurt here, in order. For example:
     a value shown to a user that the API did not send; a layer importing one it must not;
     a new tool without a test. Cite the rule's home (CLAUDE.md, a folder rule, a spec). -->

## Conventions a reviewer should cite

<!-- Where the project's rules live, so a finding points at a rule rather than at taste. -->

## Do not comment on

<!-- Classes of comment this project has decided are noise. One line each, with the reason.
     Formatting and lint belong here: a tool already owns them. -->

- Formatting, import order and anything the formatter or linter rewrites.

## Approval

<!-- Who may approve, and what must be true first. For example: never approve a change that
     touches the public API without a spec update; never approve your own work. -->
