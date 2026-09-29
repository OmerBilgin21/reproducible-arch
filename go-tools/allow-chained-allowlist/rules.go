package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

type Rule struct {
	Pattern  string
	IsPrefix bool
}

type IgnoredEntry struct {
	Entry  string
	Reason string
}

type RuleSet struct {
	Allow                 []Rule
	Ignored               []IgnoredEntry
	AdditionalDirectories []string
}

type permissionsBlock struct {
	Allow                 []string `json:"allow"`
	AdditionalDirectories []string `json:"additionalDirectories"`
}

type settingsDocument struct {
	Permissions permissionsBlock `json:"permissions"`
}

func LoadRules() (RuleSet, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return RuleSet{}, err
	}

	claudeSettings := filepath.Join(home, ".claude", "settings.json")

	raw, err := os.ReadFile(claudeSettings)
	if err != nil {
		return RuleSet{}, err
	}

	var document settingsDocument
	if err := json.Unmarshal(raw, &document); err != nil {
		return RuleSet{}, err
	}

	allow, ignored := collectRules(document.Permissions.Allow)

	return RuleSet{
		Allow:                 allow,
		Ignored:               ignored,
		AdditionalDirectories: document.Permissions.AdditionalDirectories,
	}, nil
}

func collectRules(entries []string) ([]Rule, []IgnoredEntry) {
	rules := []Rule{}
	ignored := []IgnoredEntry{}

	for _, entry := range entries {
		rule, reason := parseBashRule(entry)
		if reason != "" {
			ignored = append(ignored, IgnoredEntry{Entry: entry, Reason: reason})
			continue
		}

		rules = append(rules, rule)
	}

	return rules, ignored
}

func parseBashRule(entry string) (Rule, string) {
	trimmed := strings.TrimSpace(entry)

	if !strings.HasPrefix(trimmed, "Bash(") || !strings.HasSuffix(trimmed, ")") {
		return Rule{}, "not a Bash rule"
	}

	body := strings.TrimSpace(trimmed[len("Bash(") : len(trimmed)-1])
	if body == "" {
		return Rule{}, "empty rule body"
	}

	for _, suffix := range []string{":*", " *"} {
		if !strings.HasSuffix(body, suffix) {
			continue
		}

		pattern := strings.TrimSpace(strings.TrimSuffix(body, suffix))
		if pattern == "" {
			return Rule{}, "empty rule body"
		}

		return Rule{Pattern: pattern, IsPrefix: true}, ""
	}

	return Rule{Pattern: body, IsPrefix: false}, ""
}
