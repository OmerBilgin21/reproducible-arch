---
name: merge-branch
description: Use when asked to merge main, the default branch, or this branch's base/parent branch into the current branch, and to resolve the merge conflicts that come with it. Merges through a guard script, resolves conflicts, verifies, and concludes with git merge --continue. Never pushes.
---

# Merge Branch

Merge a base branch into the **current branch**, resolve every conflict, verify the result, and conclude the merge. The merge commit stays local; pushing is the user's call.

## Steps

1. **Start.** `cd` to the repository in its own Bash call, then:

   ```
   ~/.local/bin/merge-branch.sh start              # PR base, else the default branch
   ~/.local/bin/merge-branch.sh start <branch>     # a branch the user named
   ```

   Pass a branch only when the user named one: "merge main" → `main`, "merge feature-x into this" → `feature-x`. "Merge the base" or "the parent" → no argument; the script uses the PR's base and falls back to the default branch.

   Relay the `base:` line so the user sees what was picked and why. Then act on the `result:` line:

   - `up-to-date` or `fast-forward` — report it and stop.
   - `ready-to-continue` — no conflicts. Go to step 3.
   - `conflicts` — the conflicted paths follow, each with its porcelain code. Go to step 2.

   If the script refuses (dirty tree, default branch, merge already in progress, diverged base, ...), report its message and stop. Do not work around it.

2. **Resolve each conflict.** Files carry zdiff3 markers: `<<<<<<<` ours, `|||||||` common ancestor, `=======`, `>>>>>>>` theirs (the base).

   Before editing a file, understand what each side did:

   ```
   git log --merge --oneline -- <path>     # commits on both sides that touch it
   git show :1:<path>                      # common ancestor
   git show :2:<path>                      # this branch
   git show :3:<path>                      # the base
   ```

   Resolve to keep the intent of **both** sides:

   - Combine both changes when they touch the same code for different reasons.
   - Take one side whole only when the other side's change is superseded, e.g. the same fix already landed on the base.
   - If one side moved or renamed code the other side edited, carry the edit to the new location.
   - Delete/modify conflicts (`DU`, `UD`): keep the file with the right content, or `git rm -- <path>` when the deletion should win.
   - `package-lock.json`: never hand-merge it. Resolve the sibling `package.json` first, then run `~/.local/bin/merge-branch.sh lockfile <path>`. It takes the base's lockfile and regenerates it against the merged `package.json`.
   - Remove every marker. Edit with Edit/Write.
   - If git printed `Resolved '<path>' using previous resolution` (rerere), the file has no markers but is still listed as conflicted. Review it like any other conflict before concluding.

   Ask the user with the `ask_user` tool only when the two sides contradict and the code can't show which should win. Otherwise decide.

3. **Verify before concluding.** While the merge is still open, run the project's checks where the scripts exist: `npm run tsc`, `npm run lint`, and `npm run test:unit` for the files you touched.

   Fix failures the merge introduced, including in files that had no conflict, e.g. the base renamed a function that this branch calls. Keep a list of those extra paths. Failures that also exist on both parents are not yours to fix; report them.

4. **Conclude.**

   ```
   ~/.local/bin/merge-branch.sh continue [<fixed-path>...]
   ```

   It stages every conflicted path plus the extra paths you name, refuses with `file:line` if any conflict marker is left, then runs `git merge --continue` with git's merge message. Hooks run. If it refuses, fix the cause and run it again.

5. **Report.** Keep it short:
   - base merged and the merge commit (`<short sha> <subject>`)
   - one line per conflict: path → how it was resolved
   - extra files fixed for merge fallout
   - verification results
   - anything left uncommitted, as printed by the script

   No push, and no offer to push.

## Constraints

- **Never push.** Not when asked mid-skill, not "to be safe". The user pushes.
- The script is the only thing that changes git state, plus `git rm` for delete resolutions. Never run raw `git merge`, `git commit`, `git add`, `git checkout`, `git reset`, `git stash`, or `git merge --abort`.
- Do not combine `cd` with any other command in one Bash call.
- If you get stuck, leave the merge in progress and say what is unresolved. Mention that `git merge --abort` is the user's option to back out. Do not run it.
