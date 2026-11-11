---
name: pr-comments-report
description: Use when asked to pull, collect, or triage the comments on a pull request — review comments, inline threads, and conversation comments. Produces a report classifying which feedback is worth implementing, which should be pushed back on (with draft reasoning), and which is noise, then asks the user yes/no for each Implement item and implements the approved ones. Never replies, resolves, commits, or pushes.
---

# PR Comments Report

Collect **every** comment on a pull request, work out which ones actually ask for something, produce a triage report, then implement the Implement items the user approves one by one.

## Hard boundary

- **Never** post a reply, review, or comment. Not with `gh pr comment`, not with `gh api ... -X POST`, not any other way.
- **Never** resolve, unresolve, or minimize a thread.
- **Never** stage, commit, or push.
- **Never** edit code before Step 5 is complete, and only for Implement items the user answered **Yes** to.
- The draft reasoning you write for pushback is *for the user to read and decide on*. Hand it over as text in the report; do not send it anywhere.

## Step 1 — Pull everything

One command. It is read-only:

```
~/.local/bin/pr-comments.sh              # PR for the current branch
~/.local/bin/pr-comments.sh 123          # by number, current repo
~/.local/bin/pr-comments.sh <pr-url>     # by URL, any repo
```

It returns one JSON object with everything, already paginated:

- `meta` — number, title, state, isDraft, url, branches, author
- `reviewThreads[]` — inline threads with `isResolved`, `isOutdated`, and per-comment `path`, `line`, `diffHunk`, `author.login`, `body`, `url`
- `comments[]` — top-level conversation comments
- `reviews[]` — review summaries with `state` (APPROVED / CHANGES_REQUESTED / COMMENTED)

All three collections matter — inline threads carry most real feedback, but review summary bodies and conversation comments regularly carry the rest. Read the full body of every comment; do not triage from the first line.

If the script exits with "No pull request found", report that and stop.

**Do not reach for raw `gh` commands.** If the script is missing something you need, say so in your report rather than working around it.

## Step 2 — Filter to what's actionable

Drop from consideration (but count them, and list them compactly in the Noise section):

- resolved threads (`isResolved: true`) — unless the resolution looks premature, then flag it
- pure acknowledgements: "LGTM", "nice", "👍", "thanks"
- CI/bot status chatter with no finding: coverage bots, deploy previews, changeset reminders

Keep, and treat as real feedback:

- anything requesting a change, however politely phrased ("might be worth…", "could we…", "nit:")
- questions about behavior, edge cases, or intent
- disagreements about approach
- bot review findings with an actual claim (CodeRabbit, Sonar, CodeQL, Copilot) — these are frequently wrong, so verify them like any other comment, but do not dismiss them by virtue of being a bot

Mark `isOutdated: true` threads clearly — the code they point at has moved, so they may already be handled.

## Step 3 — Verify before you judge

For each kept comment, look at the code it refers to **as it currently stands** (`path` + `line` from the thread; read the file, and check `git log`/`git diff` on the base if the thread is outdated). A reviewer's claim may already be addressed by a later commit, or may be factually wrong about the code. Your recommendation must be based on the current state of the branch, not on the comment's assertion.

## Step 4 — Write the report

Group by verdict, most consequential first. Every entry carries the `file:line`, the author, and a link.

```
# PR #<n> — <title>
<state> · <k> threads (<r> resolved, <o> outdated) · <c> conversation comments · <v> reviews
Reviewers: <logins>  ·  Bots: <logins>

## Implement — <count>
### 1. <one-line summary>
- **Where:** `src/foo/bar.ts:42` · @author · [link]
- **Asks for:** <what they want, in your words>
- **Verified:** <what the code actually does today>
- **Verdict:** agree — <why>
- **Change:** <concretely what to do>
- **Effort:** trivial | small | needs design

## Push back — <count>
### 1. <one-line summary>
- **Where / who / link**
- **Asks for:** …
- **Verified:** …
- **Why not:** <the actual reason>
- **Draft reply (not sent):**
  > <a reply the user could paste, explaining the reasoning — respectful, specific, no hedging>

## Needs your call — <count>
Feedback where the right answer depends on context or intent you do not have. State the options and what you would pick.

## Already handled — <count>
One line each: comment → the commit or code that addresses it.

## Noise — <count>
One line each. Resolved, acknowledgements, bot status.

## Suggested order of work
Short numbered list of the Implement items, grouped so related ones land together.
```

Rules for the report:

- Be decisive. "Implement" vs "push back" is a judgement — make it, and give the reason. Do not hedge every item into "Needs your call".
- If a reviewer is right and the change is wrong, say so plainly.
- Quote the reviewer only when the exact wording matters; otherwise paraphrase.
- If two reviewers contradict each other, put it in **Needs your call** and lay out both positions.
- If the PR has no actionable feedback at all, say that in one line and list the noise counts. Don't manufacture findings.

Output the full report as text before moving on. It is unchanged by what follows.

## Step 5 — Ask about each Implement item

If the Implement section is empty, stop after the report.

Otherwise ask with the `ask_user` tool, one question per Implement item, in the report's numbering. Independent questions can be batched: put up to 4 questions in one call via the `questions` array, and keep calling until every item has an answer.

- **question:** `Should #<n> be implemented? <one-line summary> (<file:line>)`
- **options:** `Yes` (description: the **Change** line) and `No` (description: `Skip it`)
- Free-form text is available by default (`allowFreeform`), so do not add a "Other" option yourself. Handle what the user types there for that item:
  - an instruction to do it differently → implement it that way
  - a question → answer it, then ask about that item again
  - a reason to skip → treat it as No

Only Implement items are asked about. Push back, Needs your call, Already handled, and Noise are not.

## Step 6 — Implement the approved items

If every answer was No, stop.

Work through the Yes items following the **Suggested order of work**, skipping the ones answered No.

- Make the change described in the item's **Change** line, adjusted by any notes the user gave.
- Re-read the code before editing; it is the current state that matters, not what you saw during verification.
- If an item turns out to need a decision the report did not settle, ask before editing rather than guessing (use `ask_user`).
- Run the project's mandatory verification (tsc, lint, related tests) once all items are done.

## Finishing

End with a short summary: each item implemented with the files touched, each item skipped, and the verification results. No posting, no committing. If the user wants the replies sent or the changes committed, that is a separate, explicit request.
