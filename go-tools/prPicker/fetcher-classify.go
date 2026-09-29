package main

import (
	"context"
	"strings"
	"time"

	"github.com/google/go-github/v90/github"
)

func isBot(user *github.User) bool {
	return strings.EqualFold(user.GetType(), "Bot") || strings.HasSuffix(user.GetLogin(), "[bot]")
}
func (f *fetcher) isRepliedToUser(issue issueWithReviewThreads) bool {
	var mineAt time.Time

	for _, thread := range issue.reviewThreads {
		mine := false
		for _, comment := range thread.comments {
			if comment.GetUser().GetLogin() != f.login {
				continue
			}
			mine = true
			if at := comment.GetCreatedAt().Time; at.After(mineAt) {
				mineAt = at
			}
		}

		last := thread.comments[len(thread.comments)-1]
		if mine && last.GetUser().GetLogin() != f.login {
			return true
		}
	}

	var newestHuman *github.IssueComment
	for i := len(issue.conversationComments) - 1; i >= 0; i-- {
		author := issue.conversationComments[i].GetUser()

		if author.GetLogin() == f.login {
			return newestHuman != nil
		}
		if newestHuman == nil && !isBot(author) {
			newestHuman = issue.conversationComments[i]
		}
	}

	return newestHuman != nil && !mineAt.IsZero() &&
		newestHuman.GetCreatedAt().Time.After(mineAt)
}

func (f *fetcher) isReviewedBySomeoneElse(issue issueWithReviewThreads) bool {
	return false
}

func (f *fetcher) classify(ctx context.Context, issues []*github.Issue, categorizedPRs *CategorizedPRs) {
	enhancedIssues, err := f.getAllReviewComments(ctx, issues)
	if err != nil {
		return
	}

	for _, issue := range enhancedIssues {
		// user's own PR
		if issue.User.Login != nil && *issue.User.Login == f.login {
			return
		}

		pr, err := toPullRequest(issue)
		if err != nil {
			return
		}

		if isBot(issue.User) {
			categorizedPRs.AuthorIsBot = append(categorizedPRs.AuthorIsBot, pr)
		}

		if f.isRepliedToUser(issue) {
			categorizedPRs.RepliedToUsersReviews = append(categorizedPRs.RepliedToUsersReviews, pr)
		}
	}
}
