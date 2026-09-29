package main

import (
	"time"

	"github.com/google/go-github/v90/github"
)

type reviewThread struct {
	comments []*github.PullRequestComment
}

type pullRequest struct {
	owner     string
	repo      string
	number    int
	title     string
	author    string
	updatedAt time.Time
}

type CategorizedPRs struct {
	WithNoReviews                []pullRequest
	RepliedToUsersReviews        []pullRequest
	CommittedAfterUsersReviews   []pullRequest
	BelongsToImportantRepo       []pullRequest
	AuthorIsBot                  []pullRequest
	AlreadyReviewedBySomeoneElse []pullRequest
}

type fetcher struct {
	client *github.Client
	cfg    *config
	login  string
}

type issueWithReviewThreads struct {
	*github.Issue
	reviewThreads        []reviewThread
	conversationComments []*github.IssueComment
}

type threadResult struct {
	issue issueWithReviewThreads
	err   error
}
