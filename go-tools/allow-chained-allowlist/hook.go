package main

import (
	"encoding/json"
	"io"
	"os"
)

type hookInput struct {
	CWD       string `json:"cwd"`
	ToolName  string `json:"tool_name"`
	ToolInput struct {
		Command string `json:"command"`
	} `json:"tool_input"`
}

type hookSpecificOutput struct {
	HookEventName            string `json:"hookEventName"`
	PermissionDecision       string `json:"permissionDecision"`
	PermissionDecisionReason string `json:"permissionDecisionReason"`
}

type hookOutput struct {
	HookSpecificOutput hookSpecificOutput `json:"hookSpecificOutput"`
}

func RunHook() {
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return
	}

	var input hookInput
	if err := json.Unmarshal(raw, &input); err != nil {
		return
	}

	if input.ToolName != "Bash" || input.ToolInput.Command == "" {
		return
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return
	}

	cwd := input.CWD
	if cwd == "" {
		cwd = home
	}

	set, err := LoadRules()
	if err != nil {
		return
	}

	decision := Decide(input.ToolInput.Command, cwd, home, set)
	if decision.Verdict == VerdictSilent {
		return
	}

	encoded, err := json.Marshal(hookOutput{
		HookSpecificOutput: hookSpecificOutput{
			HookEventName:            "PreToolUse",
			PermissionDecision:       decision.Verdict,
			PermissionDecisionReason: decision.Reason,
		},
	})
	if err != nil {
		return
	}

	os.Stdout.Write(encoded)
}
