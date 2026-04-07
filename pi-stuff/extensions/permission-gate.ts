import type {
  BashToolInput,
  EditToolInput,
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

// prettier-ignore
const WHITELISTED_EXECUTABLES = new Set([
  "ls", "cat", "echo", "pwd", "which", "whoami",
  "find", "grep", "rg", "fd", "eza", "bat",
  "git", "go", "node", "tsc", "npx",
  "ps", "top", "htop", "df", "du", "free",
  "wc", "head", "tail", "sort", "uniq", "cut", "awk", "sed",
]);

function extractExecutables(command: string): string[] {
  // Split on pipes, &&, ||, ;, backticks, $()
  // This is intentionally rough — good enough for the purpose
  return command
    .split(/[|&;`]|\$\(/)
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => {
      // Strip leading env vars like FOO=bar cmd
      const tokens = part.split(/\s+/).filter((t) => !t.includes("="));
      return tokens[0] ?? "";
    })
    .filter(Boolean);
}

function isBashCommandWhitelisted(command: string): boolean {
  const executables = extractExecutables(command);
  if (executables.length === 0) return false;
  return executables.every((exe) => {
    // Handle paths like /usr/bin/ls → ls
    const base = exe.split("/").at(-1) ?? exe;
    return WHITELISTED_EXECUTABLES.has(base);
  });
}

async function confirmAnEdit(
  ctx: ExtensionContext,
  path: string,
  edit: { newText: string; oldText: string },
): Promise<boolean> {
  const ok = await ctx.ui.confirm(
    "Allow file edit?",
    `${path}\n\n- ${edit.oldText}\n+ ${edit.newText}`,
  );
  if (!ok) return false;
  return true;
}

export default function (pi: ExtensionAPI) {
  pi.on(
    "tool_call",
    async (event, ctx): Promise<{ block: boolean; reason: string } | void> => {
      const { toolName, input } = event;

      if (toolName === "bash") {
        const thisInput = input as BashToolInput;
        if (!isBashCommandWhitelisted(thisInput.command)) {
          const ok = await ctx.ui.confirm(
            "Allow bash command?",
            input.command as string,
          );
          if (!ok) return { block: true, reason: "Blocked by user" };
        }
      }

      if (toolName === "write") {
        const ok = await ctx.ui.confirm(
          "Allow file write?",
          input.path as string,
        );
        if (!ok) return { block: true, reason: "Blocked by user" };
      }

      if (toolName === "edit") {
        const thisInput = input as EditToolInput;
        if (thisInput.edits.length > 1) {
          for (const thisEdit of thisInput.edits) {
            const ok = await confirmAnEdit(ctx, thisInput.path, thisEdit);
            if (!ok) return { block: true, reason: "Blocked by user" };
          }
        } else {
          const ok = await confirmAnEdit(
            ctx,
            thisInput.path,
            thisInput.edits[0],
          );
          if (!ok) return { block: true, reason: "Blocked by user" };
        }
      }
    },
  );
}
