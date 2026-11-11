---
name: custom-review
description: Use when reviewing code changes in a branch, conducting a PR review, or when asked to check what changed in the current branch.
---

# Custom Review

## Overview
Performs a structured code review of branch changes using the `agent_review_diff` script to isolate diffs, then evaluates them against quality, security, and architecture criteria.

## Steps

1. **Analyze Recent Changes**: Run `~/.local/bin/agent_review_diff` to get modified files.
   - Diffs are saved to `/tmp/magicv2_chunks/` — each `.diff` file maps to one source file (underscores = path separators)
   - Review only changed files and lines
   - Reference related code only to confirm suspected critical issues or understand public contracts

2. **Conduct Comprehensive Review** against:
   - **Readability & Simplicity**: Self-documenting code, clear intent
   - **Naming**: Descriptive names following TypeScript/Node.js conventions
   - **Duplication**: Repeated logic that should be abstracted
   - **Error Handling**: try-catch, propagation, meaningful messages
   - **Input Validation**: External data validated and sanitized
   - **Performance**: Bottlenecks, inefficient queries
   - **Security**: SQL injection, XSS, auth bypasses, sensitive data exposure
   - **Architecture**: Clean architecture, DDD principles
   - **TypeScript**: Proper typing, interfaces, type safety

3. **Categorize Findings**:
   - **Critical**: Security vulnerabilities, system-breaking bugs, core architectural violations → must fix immediately
   - **Warnings**: Quality issues, potential bugs, performance/maintainability concerns → fix before merge
   - **Suggestions**: Style, optimizations, best practices → future improvement

4. **Provide Actionable Feedback**: For each issue — file + line, why it's problematic, concrete fix example.

5. **Verify Critical Issues**: Re-read the actual code for each critical issue found. Check related code if needed. Drop the issue if it doesn't hold up with full context.

Use a direct, professional tone. Be firm on critical issues. Avoid hedging language.
