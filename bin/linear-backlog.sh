#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: linear-backlog.sh [TEAM_KEY]
       linear-backlog.sh --project "PROJECT NAME" [TEAM_KEY]

Print a team's backlog (issues not assigned to any cycle) as markdown,
sorted by point estimate (smallest lift first). Each issue line includes
its identifier, title, estimate, current state, and {project} when the
issue belongs to one.

With --project, list every issue in that project instead, in any state and
regardless of cycle, sorted by state (In Progress first, Done last). Each
line includes estimate, state, and the issue's cycle when it is in one.

Arguments:
  TEAM_KEY    Linear team key (e.g. ASC, ENG). Defaults to ASC.

Options:
  -h, --help          Show this help and exit.
  --project NAME      List all issues in the named project (exact name,
                      e.g. "Multitenant WebAppRedesign").

Requires LINEAR_API_KEY in the environment.
USAGE
}

project_name=""
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --project)
    project_name="${2:?Usage: $0 --project \"PROJECT NAME\" [TEAM_KEY]}"
    shift 2
    ;;
esac

team_key="${1:-ASC}"

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "Error: please export LINEAR_API_KEY" >&2
  exit 1
fi

if [[ -n "$project_name" ]]; then
  # The project name goes in as a GraphQL variable so quotes in it are safe.
  project_query=$(cat <<EOF
query ProjectIssues(\$project: String!) {
  issues(
    filter: {
      team: { key: { eq: "$team_key" } }
      project: { name: { eq: \$project } }
    }
    first: 100
  ) {
    nodes {
      identifier
      title
      url
      estimate
      cycle { number name }
      state { name type }
    }
  }
}
EOF
)

  response=$(jq -n --arg query "$project_query" --arg project "$project_name" \
    '{query: $query, variables: {project: $project}}' | \
    http POST https://api.linear.app/graphql \
    Authorization:"$LINEAR_API_KEY" \
    Content-Type:application/json --body)

  if [[ "$(jq -r 'has("errors")' <<<"$response")" == "true" ]]; then
    echo "Error from Linear API:" >&2
    jq -r '.errors[].message' <<<"$response" >&2
    exit 1
  fi

  echo "# $project_name"
  echo ""

  items=$(jq -r '
    def state_order:
      {started: 0, unstarted: 1, triage: 2, backlog: 3, completed: 4, canceled: 5, duplicate: 6}[.state.type] // 7;
    .data.issues.nodes
    | sort_by(state_order, .identifier)
    | .[]
    | "- [\(.identifier)](\(.url)) — \(.title)"
      + (if .estimate then " [\(.estimate)pt]" else " [?pt]" end)
      + " `\(.state.name)`"
      + (if .cycle then " (\(.cycle.name // "Cycle \(.cycle.number)"))" else "" end)
  ' <<<"$response")

  if [[ -z "$items" ]]; then
    echo "_(no issues found in project '$project_name' for team $team_key)_"
  else
    echo "$items"
  fi
  exit 0
fi

graphql_query=$(cat <<EOF
query Backlog {
  teams(filter: { key: { eq: "$team_key" } }, first: 1) {
    nodes {
      key
      name
      issues(
        filter: { state: { type: { in: ["backlog", "unstarted", "triage"] } } }
        first: 50
      ) {
        nodes {
          identifier
          title
          url
          estimate
          priority
          cycle { number }
          state { name type }
          project { name }
        }
      }
    }
  }
}
EOF
)

response=$(echo "{\"query\": $(jq -Rs . <<<"$graphql_query")}" | \
  http POST https://api.linear.app/graphql \
  Authorization:"$LINEAR_API_KEY" \
  Content-Type:application/json --body)

if [[ "$(jq -r 'has("errors")' <<<"$response")" == "true" ]]; then
  echo "Error from Linear API:" >&2
  jq -r '.errors[].message' <<<"$response" >&2
  exit 1
fi

if [[ "$(jq -r '.data.teams.nodes | length' <<<"$response")" == "0" ]]; then
  echo "Error: no team found with key '$team_key'" >&2
  exit 1
fi

team_name=$(jq -r '.data.teams.nodes[0].name' <<<"$response")

echo "# $team_name — Backlog"
echo ""

items=$(jq -r '
  .data.teams.nodes[0].issues.nodes
  | map(select(.cycle == null))
  | sort_by(.estimate // 999, .identifier)
  | .[]
  | "- [\(.identifier)](\(.url)) — \(.title)"
    + (if .estimate then " [\(.estimate)pt]" else " [?pt]" end)
    + " `\(.state.name)`"
    + (if .project then " {\(.project.name)}" else "" end)
' <<<"$response")

if [[ -z "$items" ]]; then
  echo "_(no backlog issues)_"
else
  echo "$items"
fi
