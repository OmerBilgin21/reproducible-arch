import { spawnSync } from "node:child_process"
import { appendFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const BINARY = join(homedir(), ".local", "bin", "allow-chained-allowlist")
const DEBUG_LOG = process.env.OPENCODE_CHAIN_ALLOWLIST_DEBUG
  ? join(homedir(), ".cache", "opencode-chain-allowlist-debug.log")
  : null

const debug = (label, data) => {
  if (!DEBUG_LOG) return
  appendFileSync(DEBUG_LOG, `${new Date().toISOString()} ${label} ${JSON.stringify(data)}\n`)
}

// Plugin.define is an identity function (returns its argument unchanged), so a
// plain { id, setup } default export works without resolving the @opencode/plugin
// package from this loose, non-npm plugin file.
export default {
  id: "chain-allowlist",
  async setup(ctx) {
    const commandById = new Map()
    let lastCommand = ""

    await ctx.tool.hook("execute.before", (event) => {
      debug("tool.execute.before", event)
      if (event.tool !== "bash") return

      const command = event.input?.command
      if (!command) return

      lastCommand = command
      if (event.id) commandById.set(event.id, command)
    })

    await ctx.permission.hook("evaluate", async (event) => {
      debug("permission.evaluate", event)
      if (event.effect !== "ask") return
      if (event.action !== "shell" && event.action !== "bash") return

      const callId = event.source?.id
      const command = (callId && commandById.get(callId)) || lastCommand
      if (!command) return

      const payload = JSON.stringify({
        cwd: ctx.location?.directory,
        tool_name: "Bash",
        tool_input: { command },
      })

      const result = spawnSync(BINARY, [], { input: payload, encoding: "utf8" })
      if (result.status !== 0 || !result.stdout) return

      let decision
      try {
        decision = JSON.parse(result.stdout)
      } catch {
        return
      }

      if (decision?.hookSpecificOutput?.permissionDecision === "allow") {
        event.effect = "allow"
      }
    })
  },
}
