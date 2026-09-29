package main

import (
	"context"
	"flag"
	"fmt"
	"os"
)

func main() {
	printOnly := flag.Bool("print", false, "print the PR list and exit instead of opening the picker")
	flag.Parse()

	if err := run(*printOnly); err != nil {
		fmt.Fprintf(os.Stderr, "prPicker: %v\n", err)
		os.Exit(1)
	}
}

func run(printOnly bool) error {
	cfg, err := loadConfig()
	fmt.Printf("cfg: %+v\n", cfg)
	if err != nil {
		return err
	}

	if printOnly {
		return printList(cfg)
	}

	return nil
}

func printList(cfg *config) error {
	ctx, cancel := context.WithTimeout(context.Background(), FETCH_TIMEOUT)
	defer cancel()

	f, err := newFetcher(ctx, cfg)
	if err != nil {
		return err
	}

	res, err := f.load(ctx)
	if err != nil {
		return err
	}

	fmt.Printf("res: %+v\n", res)

	return nil
}
