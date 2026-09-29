package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

const nvimStartCommand = `lua vim.schedule(function() require("custom.pr-review").start() end)`

func openReview(cfg *config, pr pullRequest) error {
	dir, err := cfg.repoDir(pr.repo)
	if err != nil {
		return err
	}

	info, err := os.Stat(dir)
	if err != nil || !info.IsDir() {
		return fmt.Errorf("%s is not a directory — clone %s/%s there first", dir, pr.owner, pr.repo)
	}

	if err := verifyRemote(dir, pr); err != nil {
		return err
	}
	if err := ensureClean(dir); err != nil {
		return err
	}

	step("checking out %s", pr.key())
	if err := runStreamed(dir, "gh", "pr", "checkout", strconv.Itoa(pr.number)); err != nil {
		return fmt.Errorf("gh pr checkout: %w", err)
	}

	if _, err := os.Stat(filepath.Join(dir, "package.json")); err == nil {
		step("npm i")
		if err := runStreamed(dir, "npm", "i"); err != nil {
			return fmt.Errorf("npm i: %w", err)
		}
	} else {
		step("no package.json, skipping npm i")
	}

	return launchNvim(dir, pr)
}

func verifyRemote(dir string, pr pullRequest) error {
	out, err := exec.Command("git", "-C", dir, "remote", "get-url", "origin").Output()
	if err != nil {
		return fmt.Errorf("%s has no origin remote", dir)
	}

	want := strings.ToLower(pr.owner + "/" + pr.repo)
	got := strings.ToLower(strings.TrimSuffix(strings.TrimSpace(string(out)), ".git"))
	if !strings.HasSuffix(got, want) {
		return fmt.Errorf("%s points at %s, not %s", dir, strings.TrimSpace(string(out)), want)
	}
	return nil
}

func ensureClean(dir string) error {
	out, err := exec.Command("git", "-C", dir, "status", "--porcelain").Output()
	if err != nil {
		return fmt.Errorf("git status in %s: %w", dir, err)
	}

	dirty := strings.TrimSpace(string(out))
	if dirty == "" {
		return nil
	}
	return fmt.Errorf("%s has uncommitted changes, not checking out over them:\n%s", dir, dirty)
}

func launchNvim(dir string, pr pullRequest) error {
	nvim, err := exec.LookPath("nvim")
	if err != nil {
		return fmt.Errorf("nvim not found in PATH: %w", err)
	}

	if os.Getenv("TMUX") != "" {
		name := fmt.Sprintf("%s#%d", pr.repo, pr.number)
		command := fmt.Sprintf("%s -c %s", shellQuote(nvim), shellQuote(nvimStartCommand))
		step("opening tmux window %s", name)
		return runStreamed("", "tmux", "new-window", "-c", dir, "-n", name, command)
	}

	if err := os.Chdir(dir); err != nil {
		return fmt.Errorf("entering %s: %w", dir, err)
	}
	return syscall.Exec(nvim, []string{"nvim", "-c", nvimStartCommand}, os.Environ())
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func runStreamed(dir, name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func step(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "prPicker: "+format+"\n", args...)
}
