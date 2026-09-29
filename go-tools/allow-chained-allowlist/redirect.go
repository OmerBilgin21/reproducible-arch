package main

import (
	"errors"
	"path/filepath"
	"strings"
)

type Redirect struct {
	Target   string
	Resolved string
	Allowed  bool
}

func FindRedirectTargets(segment string) ([]string, error) {
	targets := []string{}

	inSingle := false
	inDouble := false
	index := 0

	for index < len(segment) {
		char := segment[index]

		if char == '\\' && !inSingle && index+1 < len(segment) {
			index += 2
			continue
		}

		if char == '\'' && !inDouble {
			inSingle = !inSingle
			index++
			continue
		}

		if char == '"' && !inSingle {
			inDouble = !inDouble
			index++
			continue
		}

		if inSingle || inDouble || char != '>' {
			index++
			continue
		}

		cursor := index + 1

		if cursor < len(segment) && segment[cursor] == '>' {
			cursor++
		}

		if cursor < len(segment) && segment[cursor] == '|' {
			cursor++
		}

		if cursor < len(segment) && segment[cursor] == '&' {
			after := cursor + 1
			if after < len(segment) && (isDigit(segment[after]) || segment[after] == '-') {
				index = after + 1
				continue
			}
		}

		target, next, err := readRedirectTarget(segment, cursor)
		if err != nil {
			return nil, err
		}

		targets = append(targets, target)
		index = next
	}

	if inSingle {
		return nil, errors.New("unbalanced single quote")
	}

	if inDouble {
		return nil, errors.New("unbalanced double quote")
	}

	return targets, nil
}

func readRedirectTarget(segment string, start int) (string, int, error) {
	index := start

	for index < len(segment) && (segment[index] == ' ' || segment[index] == '\t') {
		index++
	}

	token := strings.Builder{}
	inSingle := false
	inDouble := false

	for index < len(segment) {
		char := segment[index]

		if char == '\\' && !inSingle && index+1 < len(segment) {
			token.WriteByte(segment[index+1])
			index += 2
			continue
		}

		if char == '\'' && !inDouble {
			inSingle = !inSingle
			index++
			continue
		}

		if char == '"' && !inSingle {
			inDouble = !inDouble
			index++
			continue
		}

		if !inSingle && !inDouble && (char == ' ' || char == '\t' || char == '>' || char == '<') {
			break
		}

		token.WriteByte(char)
		index++
	}

	if inSingle || inDouble {
		return "", 0, errors.New("unbalanced quote in redirect target")
	}

	if token.Len() == 0 {
		return "", 0, errors.New("redirect without a target")
	}

	return token.String(), index, nil
}

func ResolvePath(path string, cwd string, home string) string {
	resolved := path

	if resolved == "~" {
		resolved = home
	} else if strings.HasPrefix(resolved, "~/") {
		resolved = filepath.Join(home, resolved[2:])
	}

	if !filepath.IsAbs(resolved) {
		resolved = filepath.Join(cwd, resolved)
	}

	return filepath.Clean(resolved)
}

func WriteRoots(cwd string, home string, additional []string) []string {
	roots := []string{filepath.Clean(cwd)}

	for _, directory := range additional {
		roots = append(roots, ResolvePath(directory, cwd, home))
	}

	return roots
}

func IsWriteAllowed(resolved string, roots []string) bool {
	if resolved == "/dev/null" {
		return true
	}

	for _, root := range roots {
		if resolved == root {
			return true
		}

		if strings.HasPrefix(resolved, root+string(filepath.Separator)) {
			return true
		}
	}

	return false
}

func CheckRedirects(segment string, cwd string, home string, roots []string) ([]Redirect, error) {
	targets, err := FindRedirectTargets(segment)
	if err != nil {
		return nil, err
	}

	redirects := []Redirect{}

	for _, target := range targets {
		resolved := ResolvePath(target, cwd, home)

		redirects = append(redirects, Redirect{
			Target:   target,
			Resolved: resolved,
			Allowed:  IsWriteAllowed(resolved, roots),
		})
	}

	return redirects, nil
}

func isDigit(char byte) bool {
	return char >= '0' && char <= '9'
}
