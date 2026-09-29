package main

import (
	"context"
	"fmt"

	"github.com/google/go-github/v90/github"
)

func getSearchQuery(ctx context.Context) string {
	return "-is:draft is:open is:pr archived:false review-requested:@me"
}

func (f *fetcher) search(ctx context.Context, query string, categorizedPRs *CategorizedPRs) error {
	opts := &github.SearchOptions{ListOptions: github.ListOptions{PerPage: 100}}

	for {
		result, resp, err := f.client.Search.Issues(ctx, query, opts)
		if err != nil {
			return fmt.Errorf("searching %q: %w", query, err)
		}
		f.classify(ctx, result.Issues, categorizedPRs)
		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return nil
}
