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

export const ChainAllowlistPlugin = async (ctx) => {
  const commandByCall = new Map()
  let lastCommand = ""

  const callKey = (input) =>
    input?.callID ?? input?.permission?.callID ?? input?.id ?? input?.permission?.id

  return {
    "tool.execute.before": async (input, output) => {
      debug("tool.execute.before", { input, args: output?.args })
      if (input.tool !== "bash") return

      const command = output?.args?.command
      if (!command) return

      lastCommand = command
      const key = callKey(input)
      if (key) commandByCall.set(key, command)
    },

    "permission.ask": async (input, output) => {
      debug("permission.ask", { input, output })
      const type = input?.permission?.type ?? input?.type
      if (type !== "bash") return

      const key = callKey(input)
      const command = (key && commandByCall.get(key)) || lastCommand
      if (!command) return

      const payload = JSON.stringify({
        cwd: ctx.directory,
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
        output.status = "allow"
      }
    },
  }
}

export default ChainAllowlistPlugin
