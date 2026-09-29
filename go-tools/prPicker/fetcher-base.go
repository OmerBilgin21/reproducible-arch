package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/google/go-github/v90/github"
)

func splitRepositoryURL(url string) (string, string, error) {
	parts := strings.Split(strings.TrimSuffix(url, "/"), "/")
	if len(parts) < 2 {
		return "", "", fmt.Errorf("unexpected repository url %q", url)
	}
	owner, repo := parts[len(parts)-2], parts[len(parts)-1]
	if owner == "" || repo == "" {
		return "", "", fmt.Errorf("unexpected repository url %q", url)
	}
	return owner, repo, nil
}

func resolveToken() (string, error) {
	token := os.Getenv("PR_PICKER_GH_TOKEN")
	if token == "" {
		return "", errors.New("PR_PICKER_GH_TOKEN env var not found please export it")
	}
	return token, nil
}

func newFetcher(ctx context.Context, cfg *config) (*fetcher, error) {
	token, err := resolveToken()
	if err != nil {
		return nil, err
	}

	client, err := github.NewClient(github.WithAuthToken(token))
	if err != nil {
		return nil, fmt.Errorf("creating github client: %w", err)
	}

	user, _, err := client.Users.Get(ctx, "")
	if err != nil {
		return nil, fmt.Errorf("resolving the authenticated user: %w", err)
	}

	login := user.GetLogin()
	if login == "" {
		return nil, errors.New("github returned an empty login for the authenticated user")
	}

	fmt.Printf("login: %+v\n", login)

	return &fetcher{client: client, cfg: cfg, login: login}, nil
}

func (f *fetcher) load(ctx context.Context) (*CategorizedPRs, error) {
	query := getSearchQuery(ctx)
	result := CategorizedPRs{}

	err := f.search(ctx, query, &result)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

func (p pullRequest) key() string {
	return fmt.Sprintf("%s/%s#%d", p.owner, p.repo, p.number)
}

func toPullRequest(issue issueWithReviewThreads) (pullRequest, error) {
	owner, repo, err := splitRepositoryURL(issue.GetRepositoryURL())
	if err != nil {
		return pullRequest{}, err
	}
	return pullRequest{
		owner:     owner,
		repo:      repo,
		number:    issue.GetNumber(),
		title:     issue.GetTitle(),
		author:    issue.GetUser().GetLogin(),
		updatedAt: issue.GetUpdatedAt().Time,
	}, nil
}
