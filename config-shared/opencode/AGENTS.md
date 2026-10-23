### Knowledgebase
 - The basic-memory hooks are where you can access information about user.
 - User's projects, the lessons you have learned, user's company specific information, your ongoing tasks with user...
 - Everything is accessible there and should be updated there.
 - When you are asked information about user's specific information, use basic-memory.
 - If anything, before doing ANYTHING even as simple as answering questions, use the basic-memory tools, chances are you have relevant information in user notes.
 - You can list the folder structure of the knowledgebase via basic-memory, search notes, write notes, edit notes...etc via basic-memory to the knowledgebase.
 - After a conversation goes on for more than a couple of messages and some changes (note worthy) are written to a codebase, add a decision knowledge about it using the template.
 - If user mentions knowledgebase, they mean to use the basic-memory hooks.
#### Writing learnings (mandatory)
 - When the user corrects you, write it as a lesson immediately using basic-memory write_note to `lessons/agent-corrections/`. Do not wait until later.
 - When an architectural or implementation decision is made during a session, write it as a decision note to `decisions/<service-name>/` using the decision template.
 - When you discover a project-specific convention, quirk, or gotcha that would help future sessions, write it to `lessons/conventions/`.
 - When a debugging session reveals a non-obvious root cause, write it to `lessons/debugging/`.
 - Do NOT batch these at the end of the session. Write each learning at the moment it happens.
 - A SessionEnd hook runs on `/new` to analyze transcripts and extract missed learnings automatically, but that is a safety net not a replacement for writing learnings in real time.
### Mandatory verification before completion
- Run `npm run tsc`.
- Run `npm run lint`.
- If tests were written/changed, run related tests and confirm they pass.
- `npm run build` will always fail for you due to sandboxing issues. It doesn't mean it's actually broken. If you genuinely suspect that the builds may be broken due to your changes, ask user to run the command.
- When running tests in most cases npm run test:unit exists as a command, use that. Integration tests will fail unless user runs the local DB for backend services so do not attempt it without prompting the user.
### Workflow orchestration
- For non-trivial tasks (3+ steps or architectural decisions), start in plan mode.
- If approach fails, stop and re-plan before further edits.
- Delegate to the `general` subagent whenever the work is open-ended: reviewing a diff or a module, researching how something works, finding where a behavior lives, surveying an API. It runs in a fresh child session, so its exploration never lands in this context, only its answer does.
- Do the work yourself when the target is already known: reading a file you were pointed at, grepping a symbol you are mid-rename on, checking one config value. A handful of targeted reads is cheaper than a handoff.
- The test is whether you know what you are looking for. If you know, look. If you are about to go find out, delegate.
- If you catch yourself on a third speculative grep, stop and hand the whole question to `general` instead of continuing.
- Keep one focused objective per subagent, and say what you want back: file:line references, a summary, or a verdict.
- When you require up-to-date information to accomplish a task, use the context7 plugin, if you can not find information there, think about cli tools user might have and how you can obtain information via those, if that also doesn't work search online via your WebSearch tool.
### Inspecting the codebase
- Default to Read / Grep / Glob for everything: file contents, config values, structure, symbol locations. They are inert, their output is visible to me, and they are auto-approved.
- Never execute code to find something out. This covers inline evaluation in any language (`-e`, `-c`, `-p`, `--eval`, `eval`), throwaway scripts, and `sed`/`awk`/`head`/`tail` used for reading. The prohibition is on the act of executing in order to inspect — it applies whatever the language, runtime, or tool, including ones not named here. Do not treat an unlisted tool as permitted.
- Never use `sed`, `awk`, or shell redirection to write or bulk-edit. Use Edit / Write. Such requests WILL be rejected.
- Running the project's own commands is expected and fine: `npm run tsc`, `npm run lint`, `npm run test:unit`, `git log`/`git diff`, `ls`.
- Executing code is not evidence. A wrong inspection script produces confident garbage. Reading the source and citing `file:line` is stronger, because I can check it.
- If a value genuinely only exists at runtime — computed at import time, or an aggregate over a file too large to read say so, say why Read/Grep can't get it, and ask before executing anything.
- A PreToolUse hook blocks inline evaluation. If you hit it, switch to Read/Grep. Do not look for a variant that slips past it.
- Prefer targeted Read/Grep on specific files over broad filesystem scanning; converge on the relevant code quickly.
### Task tracking location and shape (knowledgebase-only)
- Create/update task files in knowledgebase vault only: `tasks/<task-name>/todo.md`.
- Required structure:
  - `# <Task name>`
  - `## Plan` with checkable items
  - `## Review` with outcomes and verification notes
- Use [[90 - Templates/Template - Task Todo]] as the default shape.
- Mark progress as work proceeds; do not batch-complete at the end.
- Use basic-memory hooks to get templates and write notes
### Lessons loop (after user corrections / knowledgebase-only)
- Each lesson must capture:
  - What the agent did wrong
  - How the user corrected it
  - The prevention rule for future tasks
- For detailed session retros, use [[90 - Templates/Template - Agent Session Lesson]].
- Use basic-memory hooks to get templates and write notes
### Decision quality bar
- Simplicity first.
- Root-cause fixes only (no temporary patching).
- Minimal impact: touch only necessary files and behavior.
- Ask: would a staff engineer approve this change?
### Coding Conventions
- Always use plain objects (`Record<string, T>` / `{ [key]: value }`) for key-value lookups, never the native `Map` class. Use `mapByKey` from `@lendis-tech/microservice` when building these from arrays (when possible).
- Always check if there is a utility function for commonly done operations at `@lendis-tech/microservice` library. (e.g. hasItems for array has items checks or isNullish/isNotNullish for nullishness checks...etc)
- Since we would like to keep our bundle size low, whenever something is imported to be used as a type, use `import type { Something }` or `import { type Something }` so that it can be optimized out.
- Never use `any`; prefer strict typing.
- In tests, `as unknown as ...` is allowed when it avoids unnecessary complexity.
- Never add code comments.
- Never publish shared-libraries modules.
- Never run deployment commands (`deploy:*`, `cdk deploy`) in any repository.
- Never perform migration work (generate, edit, structure, run, or revert migrations); migration operations are user-owned.
- When doing your cross project explorations, the use of cd ... && .. or cd ... & .. type of operations must be mitigated because those are considered dangerous commands. Hence they prevent the auto-approved commands from being auto approved. (e.g. find would be auto approved but cd ... && find is not because of the danger of &&) So this is a huge slow down factor for you since the user has to manually approve every single bash command. Try to use your native tools or grep, rg after you cd somewhere.
### Node/npm version resolution (Volta)
- My shell uses Volta. Volta's shims pick the node/npm version from the `volta` config of the **current working directory** at the moment the command is invoked — not from whatever path is passed as an argument.
- Therefore `npm --prefix <path> <command>` (and the equivalents: `yarn --cwd <path>`, `pnpm -C <path>`, `npx --prefix`) is wrong here. `--prefix` only tells the package manager where `package.json` and `node_modules` live; it does not move the working directory, so Volta still resolves the toolchain from the directory the shell happens to be in. The command then runs against the target project under the **default/global** node and npm versions instead of the versions that project pins. This silently produces wrong lockfile formats, wrong engine behavior, confusing install/build failures, and results that don't reproduce for me.
- Correct pattern: change directory first, then run the command from inside the project so Volta picks up that directory's pinned toolchain.
  - Preferred: issue a standalone `cd /absolute/path/to/project` as its own Bash call — the working directory persists across calls — and then run `npm run tsc`, `npm run lint`, `npm run test:unit`, etc. as separate calls. This keeps commands auto-approvable, unlike `cd ... && ...` chains.
  - If the tool exposes a working-directory option for the command, use that instead of building a `cd` chain.
- Never reach for `--prefix`/`--cwd`/`-C` as a shortcut to avoid changing directory. If you believe a case genuinely requires it, say so and ask before running it.
### Git operations
- When you are asked to commit changes to a branch, do it with reasonable commit messages of what is being changed. Keep the commits somewhat atomic with the strategy of changes for one purpose gets grouped and gets committed the atomicity here should be coming from the intent not from the amount of changes or files. My style is that I don't use conventional commits, I don't use capital letters and I don't mention the language keywords usually (like class) with the exception of functions when it's necessary

<!-- context7 -->
Use Context7 MCP to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Always start with `resolve-library-id` using the library name and what to look up in the library's documentation, unless the user provides an exact library ID in `/org/project` format
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question). Use version-specific IDs when the user mentions a version
3. `query-docs` with the selected library ID and what to look up in the library's documentation (not single words), scoped to a single concept. If the question spans multiple distinct concepts (e.g. routing and auth and caching), make a separate `query-docs` call per concept with the same library ID, unless the question is about how the concepts interact — combined queries dilute ranking and return shallow results for each topic
4. Answer using the fetched docs
<!-- context7 -->
