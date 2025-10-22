#!/usr/bin/env bash
set -euo pipefail

source ~/.secrets

# usage: ./linear-ticket.sh ASC-19
issue_id="${1:?Usage: $0 <ISSUE_ID>}"

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "Error: please export LINEAR_API_KEY" >&2
  exit 1
fi

# Build the GraphQL query payload
graphql_query=$(cat <<EOF
query Issue {
  issue(id: "$issue_id") {
    identifier
    title
    url
    branchName
    description
    attachments {
      nodes {
        sourceType
        metadata
      }
    }
  }
}
EOF
)

# Fetch the raw JSON via httpie (http)
response=$(echo "{\"query\": $(jq -Rs . <<<"$graphql_query")}" | \
  http POST https://api.linear.app/graphql \
  Authorization:"$LINEAR_API_KEY" \
  Content-Type:application/json --body)

# Parse out the fields with jq (no spaces around =)
identifier=$(jq -r '.data.issue.identifier'  <<<"$response")
title=$(jq -r '.data.issue.title'            <<<"$response")
url=$(jq -r '.data.issue.url'                <<<"$response")
branch=$(jq -r '.data.issue.branchName'      <<<"$response")
desc=$(jq -r '.data.issue.description'       <<<"$response")

# Build the PR list (only github attachments)
pr_list=$(jq -r '
  .data.issue.attachments.nodes[]
  | select(.sourceType=="github" and .metadata.status != "closed")
  | "  * [\(.metadata.title)](\(.metadata.url))"
' <<<"$response")

# Emit the Markdown
cat <<EOF
# $identifier - $title
* Linear link: [$identifier - $title]($url)
* Git branch name: \`$branch\`
* GitHub PRs:
$pr_list

# Description
$desc

# Notes



# Links



# To Do
- [ ] Understand the ticket
- [ ] Add testing
- [ ] Add screenshots
EOF
