package main

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"sync"

	"github.com/google/go-github/v90/github"
)

func (f *fetcher) reviewThreadWorker(ctx context.Context, issue *github.Issue, out *threadResult, wg *sync.WaitGroup) {
	defer wg.Done()

	threads, err := f.reviewThreads(ctx, issue)
	if err != nil {
		out.err = err
		return
	}

	comments, err := f.conversationComments(ctx, issue)
	if err != nil {
		out.err = err
		return
	}

	out.issue = issueWithReviewThreads{
		Issue:                issue,
		reviewThreads:        threads,
		conversationComments: comments,
	}
}

func (f *fetcher) getAllReviewComments(ctx context.Context, issues []*github.Issue) ([]issueWithReviewThreads, error) {
	chunks := slices.Chunk(issues, CONCURRENCY_ITEM_CAP)
	var wg sync.WaitGroup
	results := make([]threadResult, len(issues))

	i := 0
	for chunk := range chunks {
		for _, issue := range chunk {
			wg.Add(1)
			go f.reviewThreadWorker(ctx, issue, &results[i], &wg)
			i++
		}
		wg.Wait()
	}

	enhancedIssues := make([]issueWithReviewThreads, 0, len(issues))
	var errs []error
	for _, result := range results {
		if result.err != nil {
			errs = append(errs, result.err)
			continue
		}
		enhancedIssues = append(enhancedIssues, result.issue)
	}

	return enhancedIssues, errors.Join(errs...)
}

func (f *fetcher) conversationComments(ctx context.Context, issue *github.Issue) ([]*github.IssueComment, error) {
	owner, repo, err := splitRepositoryURL(issue.GetRepositoryURL())
	if err != nil {
		return nil, err
	}
	number := issue.GetNumber()

	opts := &github.IssueListCommentsOptions{
		Sort:        github.Ptr("created"),
		Direction:   github.Ptr("asc"),
		ListOptions: github.ListOptions{PerPage: 100},
	}

	var comments []*github.IssueComment
	for comment, err := range f.client.Issues.ListCommentsIter(ctx, owner, repo, number, opts) {
		if err != nil {
			return nil, fmt.Errorf("listing conversation comments on %s/%s#%d: %w", owner, repo, number, err)
		}
		comments = append(comments, comment)
	}

	return comments, nil
}

func (f *fetcher) reviewThreads(ctx context.Context, issue *github.Issue) ([]reviewThread, error) {
	owner, repo, err := splitRepositoryURL(issue.GetRepositoryURL())
	if err != nil {
		return nil, err
	}
	number := issue.GetNumber()

	opts := &github.PullRequestListCommentsOptions{
		Sort:        "created",
		Direction:   "asc",
		ListOptions: github.ListOptions{PerPage: 100},
	}

	var order []int64
	byRoot := map[int64]*reviewThread{}

	for comment, err := range f.client.PullRequests.ListCommentsIter(ctx, owner, repo, number, opts) {
		if err != nil {
			return nil, fmt.Errorf("listing review comments on %s/%s#%d: %w", owner, repo, number, err)
		}
		if parent := comment.GetInReplyTo(); parent != 0 {
			if thread, ok := byRoot[parent]; ok {
				thread.comments = append(thread.comments, comment)
				continue
			}
		}
		byRoot[comment.GetID()] = &reviewThread{comments: []*github.PullRequestComment{comment}}
		order = append(order, comment.GetID())
	}

	threads := make([]reviewThread, 0, len(order))
	for _, id := range order {
		threads = append(threads, *byRoot[id])
	}
	return threads, nil
}
