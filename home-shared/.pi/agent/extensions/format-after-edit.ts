import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Best-effort formatting after the model writes or edits a file.
 *
 * Fires on every successful write/edit, picks a formatter by extension and
 * runs it in the background. Every formatter below leaves the file untouched
 * when it cannot parse it, so a half-written or broken file is never modified
 * by this extension. Failures are swallowed silently.
 */

const FORMATTERS: Record<
  string,
  { cmd: string; args: (path: string) => string[] }
> = {
  ".ts": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".tsx": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".js": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".jsx": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".mjs": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".cjs": { cmd: "npx", args: (p) => ["prettier", "--write", p] },
  ".go": { cmd: "gofmt", args: (p) => ["-w", p] },
  ".lua": { cmd: "stylua", args: (p) => ["-q", p] },
};

const DEDUPE_MS = 500;

export default function (pi: ExtensionAPI) {
  // path -> timer for coalescing rapid successive edits to the same file
  const pending = new Map<string, NodeJS.Timeout>();

  const format = (path: string) => {
    const dot = path.lastIndexOf(".");
    const ext = dot >= 0 ? path.slice(dot) : "";
    const fmt = FORMATTERS[ext];
    if (!fmt) return;
    try {
      // Fire-and-forget: the agent keeps moving; the formatter either
      // rewrites the file or leaves it alone on parse errors.
      execFile(
        fmt.cmd,
        fmt.args(path),
        { timeout: 60_000, windowsHide: true },
        () => {
          /* swallowed: best effort */
        },
      );
    } catch {
      // execFile spawn failed (e.g. command missing) — leave the file alone
    }
  };

  const schedule = (path: string) => {
    const existing = pending.get(path);
    if (existing) clearTimeout(existing);
    pending.set(
      path,
      setTimeout(() => {
        pending.delete(path);
        format(path);
      }, DEDUPE_MS),
    );
  };

  pi.on("tool_execution_end", (event) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return;
    if (event.isError) return;
    const path = (event.args as { path?: string } | undefined)?.path;
    if (typeof path !== "string" || path.length === 0) return;
    if (path.startsWith("~")) return; // not expanded; skip rather than guess
    schedule(path);
  });
}
