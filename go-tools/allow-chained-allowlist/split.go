package main

import (
	"errors"
	"strings"
)

const substitutionPlaceholder = "$()"

func SplitCommand(command string) ([]string, error) {
	outer, inner, err := extractSubstitutions(command)
	if err != nil {
		return nil, err
	}

	segments, err := splitOperators(outer)
	if err != nil {
		return nil, err
	}

	for _, nested := range inner {
		nestedSegments, err := SplitCommand(nested)
		if err != nil {
			return nil, err
		}

		segments = append(segments, nestedSegments...)
	}

	return segments, nil
}

func extractSubstitutions(command string) (string, []string, error) {
	outer := strings.Builder{}
	inner := []string{}

	inSingle := false
	index := 0

	for index < len(command) {
		char := command[index]

		if char == '\\' && !inSingle && index+1 < len(command) {
			outer.WriteByte(char)
			outer.WriteByte(command[index+1])
			index += 2
			continue
		}

		if char == '\'' {
			inSingle = !inSingle
			outer.WriteByte(char)
			index++
			continue
		}

		if !inSingle && char == '$' && index+1 < len(command) && command[index+1] == '(' {
			body, next, err := readSubstitution(command, index+2, '(', ')')
			if err != nil {
				return "", nil, err
			}

			inner = append(inner, body)
			outer.WriteString(substitutionPlaceholder)
			index = next
			continue
		}

		if !inSingle && char == '`' {
			body, next, err := readSubstitution(command, index+1, 0, '`')
			if err != nil {
				return "", nil, err
			}

			inner = append(inner, body)
			outer.WriteString(substitutionPlaceholder)
			index = next
			continue
		}

		outer.WriteByte(char)
		index++
	}

	if inSingle {
		return "", nil, errors.New("unbalanced single quote")
	}

	return outer.String(), inner, nil
}

func readSubstitution(command string, start int, open byte, close byte) (string, int, error) {
	body := strings.Builder{}
	depth := 1

	for index := start; index < len(command); index++ {
		char := command[index]

		if open != 0 && char == open {
			depth++
		}

		if char == close {
			depth--
			if depth == 0 {
				return body.String(), index + 1, nil
			}
		}

		body.WriteByte(char)
	}

	return "", 0, errors.New("unterminated command substitution")
}

func splitOperators(command string) ([]string, error) {
	segments := []string{}
	current := strings.Builder{}

	inSingle := false
	inDouble := false
	index := 0

	flush := func() {
		segment := strings.TrimSpace(current.String())
		if segment != "" {
			segments = append(segments, segment)
		}

		current.Reset()
	}

	for index < len(command) {
		char := command[index]

		if char == '\\' && !inSingle && index+1 < len(command) {
			current.WriteByte(char)
			current.WriteByte(command[index+1])
			index += 2
			continue
		}

		if char == '\'' && !inDouble {
			inSingle = !inSingle
			current.WriteByte(char)
			index++
			continue
		}

		if char == '"' && !inSingle {
			inDouble = !inDouble
			current.WriteByte(char)
			index++
			continue
		}

		if inSingle || inDouble {
			current.WriteByte(char)
			index++
			continue
		}

		rest := command[index:]

		if strings.HasPrefix(rest, "<<") {
			return nil, errors.New("heredoc is not supported")
		}

		if strings.HasPrefix(rest, "<(") || strings.HasPrefix(rest, ">(") {
			return nil, errors.New("process substitution is not supported")
		}

		if strings.HasPrefix(rest, "&&") || strings.HasPrefix(rest, "||") {
			flush()
			index += 2
			continue
		}

		if char == ';' || char == '\n' || char == '|' {
			flush()
			index++
			continue
		}

		if char == '&' && !isRedirectAmpersand(command, index) {
			flush()
			index++
			continue
		}

		current.WriteByte(char)
		index++
	}

	if inSingle {
		return nil, errors.New("unbalanced single quote")
	}

	if inDouble {
		return nil, errors.New("unbalanced double quote")
	}

	flush()

	return segments, nil
}

func isRedirectAmpersand(command string, index int) bool {
	if index > 0 && command[index-1] == '>' {
		return true
	}

	if index+1 < len(command) && command[index+1] == '>' {
		return true
	}

	return false
}
