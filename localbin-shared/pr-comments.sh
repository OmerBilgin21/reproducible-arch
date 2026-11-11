#!/bin/bash
# Fetch every comment on a pull request as a single JSON blob. Read-only.
#
#   pr-comments.sh              # PR for the current branch
#   pr-comments.sh 123          # PR by number, current repo
#   pr-comments.sh <pr-url>     # PR by URL, any repo
#
# Output: {meta, reviewThreads[], comments[], reviews[]}
#   reviewThreads - inline threads, with isResolved/isOutdated and file+line
#   comments      - top-level conversation comments
#   reviews       - review summaries (APPROVED / CHANGES_REQUESTED / COMMENTED)

set -euo pipefail

TARGET="${1:-}"

META=$(gh pr view ${TARGET:+"$TARGET"} \
  --json number,title,state,isDraft,url,headRefName,baseRefName,author) || {
  echo "No pull request found. Pass a number or URL, or switch to a branch with an open PR." >&2
  exit 1
}

NUMBER=$(jq -r '.number' <<<"$META")
URL=$(jq -r '.url' <<<"$META")
OWNER=$(cut -d/ -f4 <<<"$URL")
REPO=$(cut -d/ -f5 <<<"$URL")

# Inline review threads. Only GraphQL exposes isResolved/isOutdated, and those
# drive the triage, so this cannot be swapped for the REST comments endpoint.
THREADS='[]'
CURSOR=""
while :; do
  PAGE=$(gh api graphql \
    -f query='
      query($owner:String!,$repo:String!,$number:Int!,$cursor:String){
        repository(owner:$owner,name:$repo){
          pullRequest(number:$number){
            reviewThreads(first:100, after:$cursor){
              pageInfo{hasNextPage endCursor}
              nodes{
                isResolved
                isOutdated
                comments(first:50){
                  nodes{author{login} body path line originalLine diffHunk createdAt url}
                }
              }
            }
          }
        }
      }' \
    -F owner="$OWNER" -F repo="$REPO" -F number="$NUMBER" \
    ${CURSOR:+-F cursor="$CURSOR"})

  THREADS=$(jq -n \
    --argjson acc "$THREADS" \
    --argjson page "$(jq '.data.repository.pullRequest.reviewThreads.nodes' <<<"$PAGE")" \
    '$acc + $page')

  HAS_NEXT=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' <<<"$PAGE")
  [ "$HAS_NEXT" = "true" ] || break
  CURSOR=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$PAGE")
done

CONVERSATION=$(gh api graphql \
  -f query='
    query($owner:String!,$repo:String!,$number:Int!){
      repository(owner:$owner,name:$repo){
        pullRequest(number:$number){
          comments(first:100){nodes{author{login} body createdAt url}}
          reviews(first:100){nodes{author{login} state body createdAt url}}
        }
      }
    }' \
  -F owner="$OWNER" -F repo="$REPO" -F number="$NUMBER")

jq -n \
  --argjson meta "$META" \
  --argjson threads "$THREADS" \
  --argjson conversation "$CONVERSATION" \
  '{
     meta: $meta,
     reviewThreads: $threads,
     comments: $conversation.data.repository.pullRequest.comments.nodes,
     reviews: $conversation.data.repository.pullRequest.reviews.nodes
   }'
