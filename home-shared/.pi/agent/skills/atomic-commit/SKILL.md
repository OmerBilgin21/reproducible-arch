---
name: atomic-commit
description: Use when asked to commit the current working-tree changes, or to commit atomically/by topic. Groups uncommitted changes into logically-cohesive commits on the current branch — one commit per purpose, not per file.
---

# Atomic Commit

Commit everything currently uncommitted to the **current branch**, split into commits that each serve a single purpose.

## Grouping rule

Atomicity comes from **intent**, not from size or file count. One commit = one reason the change exists.

- A commit may touch 1 file or 20 — if they all serve the same purpose, they belong together.
- A single file may serve two purposes; that is fine, put it in whichever commit it mostly belongs to. **Do not** split hunks within a file, do not use `git add -p`, do not stage partial files. No surgical work.
- Prefer fewer, coherent commits over many tiny ones. If unsure whether two changes are one topic, ask yourself: would a reviewer want to see them together? If yes, one commit.

Typical topic boundaries:
- a feature and the code it directly needs (types, DTOs, wiring)
- a bugfix and its regression test
- a refactor / rename sweep
- config, tooling, dependency, or CI changes
- docs
- tests added for existing behavior

## Steps

1. **Branch gate — do this first, before anything else.**

   Determine the current branch and the repository's default branch:

   ```
   git branch --show-current
   git symbolic-ref --quiet --short refs/remotes/origin/HEAD   # prints e.g. "origin/main"; strip the "origin/" prefix
   ```

   If `symbolic-ref` exits non-zero (origin/HEAD not set locally, or no remote), fall back to:

   ```
   gh repo view --json defaultBranchRef -q .defaultBranchRef.name
   ```

   If both fail, treat `main` and `master` as default branches.

   **If the current branch is the default branch, stop. Do not commit anything.** There is no permission to ask for. Report and end the skill:

   > On `<branch>`, which is this repository's default branch. Not committing. Move these changes to a feature branch first.

   Then stop. Nothing else in this skill runs.

2. **Survey.** Run `git status --porcelain` and `git diff` / `git diff --staged` to see everything uncommitted, including untracked files. Read enough of the diff to understand *why* each change exists.

3. **Plan the groups.** Assign every changed file to exactly one topic group. Show the user the plan as a short list (group → files → intended message) before committing.

4. **Commit each group in turn**, using the guard script — one call per group:

   ```
   ~/.local/bin/commit-group.sh "<message>" <path> [<path>...]
   ```

   It stages exactly the paths you name and commits exactly those paths, so a dirty index cannot contaminate a group. It refuses on the default branch, on an empty, multi-line or over-90-character message, and when the named paths stage nothing. There are no flags — it cannot amend, skip hooks, or push.

   Do not use bare `git add` / `git commit`; the script is the supported path. If the script refuses, read its message and fix the cause rather than reaching for raw git.

5. **Verify.** End with `git status` (should be clean or only intentionally-left files) and `git log --oneline -n <count>` showing the new commits. Report what was committed.

## Commit message style

**Write plainly. No literary flourish of any kind.** No metaphors, no dramatic framing, no "elegantly", "gracefully", "seamlessly", "robust", "comprehensive", "properly". No selling the change. State the mechanics and stop. If a sentence would sound at home in a blog post, delete it.

**Be short.** The shortest message that identifies the change is the correct one. Real examples from this codebase: `add util`, `use new func`, `bump microservice`, `remove console debugs to not disrupt tests`, `use format date`. Do not pad a small change into a big sentence.

**One line, at most 90 characters. No body.** Never write a description, a second paragraph, or an explanation under the subject, however substantial the change. If the reasoning feels important, fold the short form of it into the subject or leave it out. The script rejects multi-line messages and anything over 90 characters.

### Subject line

- lowercase throughout, imperative verb first, no trailing period
- **no** conventional-commit prefixes — never `feat:`, `fix:`, `chore:`, `refactor:`
- **never prefix with a ticket id.** No `PHO-5739`, no `SALE-2403`, no `SALE-000`. Such prefixes exist in the history but they were written by AI or came from squashed PR titles — they are not the user's style. The branch name already carries the ticket.
- domain language, not type-system language. Say what the code does, not that a class or interface changed.
- identifiers inline in their real casing when they sharpen the message: `implement exponentialBackoff to read only calls of google api`
- everyday abbreviations are fine: dto, impl, func, cli, dlq, api
- joining two related changes with "and" is idiomatic here: `reject duplicate single instance document types and compose document add with delete`
- stating the reasoning inline is also idiomatic when it is short: `no need to guard by type on deletion as if we can match the id we delete is good enough`

Real subjects, for calibration:

```
enforce order document rules only on the documents a patch changes
move dto to shared model
set and remove order documents inside a locked transaction
validate documents through one validator per entity
make archimedes strategy respect the sent enforced bracket
skip order document removal when the deleted file is not the current one
improve jest setup to avoid memory issues
```

Wrong shapes:

```
feat: Add email validation          -> prefix, capital
PHO-5739 add email validation       -> ticket prefix, never
Update UserService class            -> capital, says "class", says nothing
Introduce a robust and elegant      -> adjectives, selling
  validation layer
fix stuff                           -> says nothing
```

## Reporting back

Be concise in the chat too. When done, list the commits as `<short sha> <subject>` and one line on anything intentionally left uncommitted. No preamble, no recap of the grouping rationale, no summary table, no closing offer of further help. If nothing went wrong, the report is a few lines.

## Constraints

- **Never commit to the default branch.** Not with a warning, not with confirmation, not "just this once", not if the user asks again in the same breath. If you are on it, the answer is no — report it and stop. The fix is always a feature branch, and creating that branch is the user's call, not yours.
- Commit to the current branch as-is — do not create, switch, or rebase branches.
- Never run `git push` unless the user explicitly asks.
- Never `git reset --hard`, `git checkout --`, `git stash`, or otherwise discard uncommitted work.
- Do not amend or rewrite existing commits unless asked.
- Do not combine `cd` with a `git` command in one Bash call — `cd` first, then run the git command separately.
- Leave secrets, `.env` files, and credentials uncommitted; flag them to the user instead.
- If the working tree is clean, say so and stop.
