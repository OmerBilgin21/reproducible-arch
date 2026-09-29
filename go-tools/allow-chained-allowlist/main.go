package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
)

func main() {
	dumpRules := flag.Bool("dump-rules", false, "print the permission rules parsed from settings and exit")
	splitTarget := flag.String("split", "", "split a command into its segments and print them")
	redirectTarget := flag.String("redirects", "", "split a command and report the write target of every redirect")
	decideTarget := flag.String("decide", "", "print the decision this hook would return for a command")
	cwdFlag := flag.String("cwd", "", "working directory used to resolve relative paths")
	flag.Parse()

	if *splitTarget != "" {
		printSplit(*splitTarget)
		return
	}

	if *redirectTarget != "" {
		printRedirects(*redirectTarget, *cwdFlag)
		return
	}

	if *decideTarget != "" {
		printDecision(*decideTarget, *cwdFlag)
		return
	}

	if *dumpRules {
		set, err := LoadRules()
		if err != nil {
			log.Fatal("cannot load rules: ", err)
		}

		printRuleSet(os.Stdout, set, *cwdFlag)
		return
	}

	RunHook()
}

func resolveContext(cwdFlag string) (string, string) {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatal("cannot resolve home directory: ", err)
	}

	cwd := cwdFlag
	if cwd == "" {
		resolved, err := os.Getwd()
		if err != nil {
			log.Fatal("cannot resolve working directory: ", err)
		}

		cwd = resolved
	}

	return cwd, home
}

func printSplit(command string) {
	segments, err := SplitCommand(command)
	if err != nil {
		fmt.Fprintln(os.Stderr, "cannot split:", err)
		os.Exit(1)
	}

	for index, segment := range segments {
		fmt.Printf("%d  %s\n", index+1, segment)
	}
}

func printDecision(command string, cwdFlag string) {
	cwd, home := resolveContext(cwdFlag)

	set, err := LoadRules()
	if err != nil {
		log.Fatal("cannot load rules: ", err)
	}

	decision := Decide(command, cwd, home, set)

	if decision.Verdict == VerdictSilent {
		fmt.Println("verdict: silent (Claude Code decides, you get today's behaviour)")
		return
	}

	fmt.Printf("verdict: %s\n", decision.Verdict)
	fmt.Printf("reason:  %s\n", decision.Reason)
}

func printRedirects(command string, cwdFlag string) {
	cwd, home := resolveContext(cwdFlag)

	segments, err := SplitCommand(command)
	if err != nil {
		fmt.Fprintln(os.Stderr, "cannot split:", err)
		os.Exit(1)
	}

	set, err := LoadRules()
	if err != nil {
		log.Fatal("cannot load rules: ", err)
	}

	roots := WriteRoots(cwd, home, set.AdditionalDirectories)

	for index, segment := range segments {
		fmt.Printf("%d  %s\n", index+1, segment)

		redirects, err := CheckRedirects(segment, cwd, home, roots)
		if err != nil {
			fmt.Printf("   redirect error: %s\n", err)
			continue
		}

		if len(redirects) == 0 {
			fmt.Println("   no redirect")
			continue
		}

		for _, redirect := range redirects {
			verdict := "BLOCKED"
			if redirect.Allowed {
				verdict = "allowed"
			}

			fmt.Printf("   %-8s %s -> %s\n", verdict, redirect.Target, redirect.Resolved)
		}
	}
}

func printRuleSet(out io.Writer, set RuleSet, cwdFlag string) {
	cwd, home := resolveContext(cwdFlag)
	roots := WriteRoots(cwd, home, set.AdditionalDirectories)

	fmt.Fprintf(out, "write roots (%d)\n", len(roots))
	for _, root := range roots {
		fmt.Fprintf(out, "  %s\n", root)
	}

	printRules(out, "allow", set.Allow)

	fmt.Fprintf(out, "\nignored (%d)\n", len(set.Ignored))
	for _, entry := range set.Ignored {
		fmt.Fprintf(out, "  %-38s %s\n", entry.Reason, entry.Entry)
	}
}

func printRules(out io.Writer, name string, rules []Rule) {
	fmt.Fprintf(out, "\n%s (%d)\n", name, len(rules))
	for _, rule := range rules {
		kind := "exact"
		if rule.IsPrefix {
			kind = "prefix"
		}

		fmt.Fprintf(out, "  %-6s %s\n", kind, rule.Pattern)
	}
}
