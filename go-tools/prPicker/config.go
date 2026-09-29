package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type config struct {
	ProjectsDir    string            `json:"projectsDir"`
	ExceptionRepos []string          `json:"exceptionRepos"`
	RepoDirs       map[string]string `json:"repoDirs"`

	exceptions map[string]struct{}
}

func loadConfig() (*config, error) {
	cfg := &config{}

	path, err := configPath()
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("no config or broken structure %s: %w", path, err)
	}

	if err := json.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}

	cfg.ProjectsDir, err = expandHome(cfg.ProjectsDir)
	if err != nil {
		return nil, err
	}

	cfg.exceptions = make(map[string]struct{}, len(cfg.ExceptionRepos))
	for _, repo := range cfg.ExceptionRepos {
		repo = strings.ToLower(strings.TrimSpace(repo))
		if repo != "" {
			cfg.exceptions[repo] = struct{}{}
		}
	}

	return cfg, nil
}

func (c *config) isException(repo string) bool {
	_, ok := c.exceptions[strings.ToLower(repo)]
	return ok
}

func (c *config) repoDir(repo string) (string, error) {
	target := repo
	if override, ok := c.RepoDirs[repo]; ok && strings.TrimSpace(override) != "" {
		target = strings.TrimSpace(override)
	}

	expanded, err := expandHome(target)
	if err != nil {
		return "", err
	}
	if filepath.IsAbs(expanded) {
		return expanded, nil
	}
	return filepath.Join(c.ProjectsDir, expanded), nil
}

func configPath() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolving home directory: %w", err)
	}
	return filepath.Join(home, ".prPicker", "config.json"), nil
}

func expandHome(path string) (string, error) {
	if path != "~" && !strings.HasPrefix(path, "~/") {
		return path, nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolving home directory: %w", err)
	}
	return filepath.Join(home, strings.TrimPrefix(strings.TrimPrefix(path, "~"), "/")), nil
}
