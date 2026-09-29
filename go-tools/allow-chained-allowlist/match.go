package main

import "strings"

const (
	VerdictSilent = ""
	VerdictAllow  = "allow"
	VerdictAsk    = "ask"
)

type Decision struct {
	Verdict string
	Reason  string
}

var gitOptionsWithValue = map[string]bool{
	"-C":          true,
	"-c":          true,
	"--git-dir":   true,
	"--work-tree": true,
	"--namespace": true,
}

var gitStandaloneOptions = map[string]bool{
	"--no-pager": true,
	"--paginate": true,
	"--bare":     true,
}

var forbiddenTokens = map[string][]string{
	"find":       {"-delete", "-exec", "-execdir", "-ok", "-okdir", "-fprint", "-fprintf", "-fls"},
	"rg":         {"--pre", "--pre-glob", "--hostname-bin"},
	"git config": {"--global", "--system", "--replace-all", "--unset", "--unset-all", "--edit", "-e", "--add"},
}

var loopHeaders = map[string]bool{
	"for":    true,
	"select": true,
	"case":   true,
}

var controlKeywords = map[string]bool{
	"do":    true,
	"done":  true,
	"then":  true,
	"else":  true,
	"elif":  true,
	"fi":    true,
	"if":    true,
	"while": true,
	"until": true,
	"esac":  true,
	";;":    true,
	"{":     true,
	"}":     true,
	"!":     true,
}

var inertBuiltins = map[string]bool{
	"read":     true,
	"test":     true,
	"[":        true,
	"[[":       true,
	"true":     true,
	"false":    true,
	":":        true,
	"shift":    true,
	"break":    true,
	"continue": true,
}

func StripControlKeywords(normalized string) (string, bool) {
	tokens := strings.Fields(normalized)
	if len(tokens) == 0 {
		return "", true
	}

	if loopHeaders[tokens[0]] {
		return "", true
	}

	index := 0
	for index < len(tokens) && controlKeywords[tokens[index]] {
		index++
	}

	if index == 0 {
		return normalized, false
	}

	tokens = tokens[index:]

	if len(tokens) == 0 || isRedirectToken(tokens[0]) {
		return "", true
	}

	return strings.Join(tokens, " "), false
}

func isRedirectToken(token string) bool {
	if token == "" {
		return false
	}

	if token[0] == '<' || token[0] == '>' {
		return true
	}

	position := 0
	for position < len(token) && token[position] >= '0' && token[position] <= '9' {
		position++
	}

	return position > 0 && position < len(token) && token[position] == '>'
}

func IsAllowedCommand(command string, rules []Rule) bool {
	if MatchesAllow(command, rules) {
		return true
	}

	tokens := strings.Fields(command)

	return len(tokens) > 0 && inertBuiltins[tokens[0]]
}

func HasForbiddenToken(normalized string) string {
	tokens := strings.Fields(normalized)

	for command, forbidden := range forbiddenTokens {
		commandTokens := strings.Fields(command)

		if !hasTokenPrefix(tokens, commandTokens) {
			continue
		}

		for _, token := range tokens[len(commandTokens):] {
			name := token
			if equals := strings.Index(name, "="); equals > 0 {
				name = name[:equals]
			}

			for _, candidate := range forbidden {
				if name == candidate {
					return token
				}
			}
		}
	}

	return ""
}

func hasTokenPrefix(tokens []string, prefix []string) bool {
	if len(tokens) < len(prefix) {
		return false
	}

	for index, token := range prefix {
		if tokens[index] != token {
			return false
		}
	}

	return true
}

func NormalizeSegment(segment string) string {
	tokens := stripLeadingAssignments(strings.Fields(segment))

	if len(tokens) > 0 && tokens[0] == "git" {
		tokens = stripGitGlobalOptions(tokens)
	}

	return strings.Join(tokens, " ")
}

func stripLeadingAssignments(tokens []string) []string {
	index := 0

	for index < len(tokens) && isAssignment(tokens[index]) {
		index++
	}

	return tokens[index:]
}

func isAssignment(token string) bool {
	equals := strings.Index(token, "=")
	if equals <= 0 {
		return false
	}

	for position := 0; position < equals; position++ {
		char := token[position]

		if char == '_' || (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') {
			continue
		}

		if position > 0 && char >= '0' && char <= '9' {
			continue
		}

		return false
	}

	return true
}

func stripGitGlobalOptions(tokens []string) []string {
	normalized := []string{tokens[0]}
	index := 1

	for index < len(tokens) {
		token := tokens[index]

		if gitOptionsWithValue[token] {
			index += 2
			continue
		}

		if gitStandaloneOptions[token] {
			index++
			continue
		}

		if equals := strings.Index(token, "="); equals > 0 && gitOptionsWithValue[token[:equals]] {
			index++
			continue
		}

		break
	}

	return append(normalized, tokens[index:]...)
}

func MatchesAllow(normalized string, rules []Rule) bool {
	for _, rule := range rules {
		if normalized == rule.Pattern {
			return true
		}

		if rule.IsPrefix && strings.HasPrefix(normalized, rule.Pattern+" ") {
			return true
		}
	}

	return false
}

func Decide(command string, cwd string, home string, set RuleSet) Decision {
	segments, err := SplitCommand(command)
	if err != nil {
		return Decision{}
	}

	if len(segments) == 0 {
		return Decision{}
	}

	roots := WriteRoots(cwd, home, set.AdditionalDirectories)

	unmatched := ""
	blocked := Redirect{}
	forbidden := ""
	forbiddenSegment := ""

	for _, segment := range segments {
		command, scaffolding := StripControlKeywords(NormalizeSegment(segment))

		if !scaffolding {
			if !IsAllowedCommand(command, set.Allow) {
				if unmatched == "" {
					unmatched = segment
				}

				continue
			}

			if forbidden == "" {
				if token := HasForbiddenToken(command); token != "" {
					forbidden = token
					forbiddenSegment = segment
				}
			}
		}

		if blocked.Target != "" {
			continue
		}

		redirects, err := CheckRedirects(segment, cwd, home, roots)
		if err != nil {
			return Decision{}
		}

		for _, redirect := range redirects {
			if !redirect.Allowed {
				blocked = redirect
				break
			}
		}
	}

	if unmatched != "" {
		if len(segments) > 1 {
			return Decision{
				Verdict: VerdictAsk,
				Reason:  "not in permissions.allow: " + unmatched,
			}
		}

		return Decision{}
	}

	if blocked.Target != "" {
		return Decision{
			Verdict: VerdictAsk,
			Reason:  "writes outside your allowed directories: " + blocked.Target + " resolves to " + blocked.Resolved,
		}
	}

	if forbidden != "" {
		return Decision{
			Verdict: VerdictAsk,
			Reason:  forbidden + " can execute or delete, so this is not auto-approved: " + forbiddenSegment,
		}
	}

	return Decision{
		Verdict: VerdictAllow,
		Reason:  "every part of this command matches permissions.allow",
	}
}
