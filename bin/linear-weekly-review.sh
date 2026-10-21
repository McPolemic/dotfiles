#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source ~/.secrets

TEAM_KEY="${LINEAR_TEAM_KEY:-ASC}"
LOOKBACK_DAYS="${LINEAR_LOOKBACK_DAYS:-7}"
ISSUE_LIMIT="${LINEAR_WEEKLY_LIMIT:-50}"

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "Error: please export LINEAR_API_KEY" >&2
  exit 1
fi

since="$(date -u -v-"${LOOKBACK_DAYS}"d +%Y-%m-%dT%H:%M:%SZ)"
generated="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

graphql_query=$(cat <<EOF
query WeeklyReview {
  issues(
    filter: {
      team: { key: { eq: "$TEAM_KEY" } }
      updatedAt: { gte: "$since" }
    }
    sort: [{ updatedAt: { order: Descending } }]
    first: $ISSUE_LIMIT
  ) {
    nodes {
      identifier
      title
      url
      updatedAt
      state { name }
      project { name }
      history(last: 20) {
        nodes {
          createdAt
          actor {
            displayName
            name
            email
          }
          fromState { name }
          toState { name }
          fromAssignee {
            displayName
            name
          }
          toAssignee {
            displayName
            name
          }
          fromProject { name }
          toProject { name }
          addedLabels { name }
          removedLabels { name }
          changes
        }
      }
      comments(last: 20) {
        nodes {
          createdAt
          body
          user {
            displayName
            name
            email
          }
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

if jq -e '.errors' >/dev/null <<<"$response"; then
  echo "Error: Linear API returned errors" >&2
  jq '.errors' <<<"$response" >&2
  exit 1
fi

echo "# Associations activity since ${since}"
echo

jq -r --arg since "$since" --arg lookback "$LOOKBACK_DAYS" '
  def name_or_email($obj):
    (($obj // {}) | .displayName // .name // .email // "Unknown");

  def assignee_name($obj):
    if $obj == null then "Unassigned" else name_or_email($obj) end;

  def fmt_ts:
    sub("\\.[0-9]+";"") | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M UTC");

  def hist_summary:
    [
      (if (.fromState.name? or .toState.name?) then "State: " + (.fromState.name // "None") + " → " + (.toState.name // "None") else empty end),
      (if ((.fromAssignee // null) != null or (.toAssignee // null) != null)
       then "Assignee: " + assignee_name(.fromAssignee) + " → " + assignee_name(.toAssignee)
       else empty
      end),
      (if (.fromProject.name? or .toProject.name?) then "Project: " + (.fromProject.name // "None") + " → " + (.toProject.name // "None") else empty end),
      (if ((.addedLabels // []) | length) > 0 then "Labels added: " + ((.addedLabels // []) | map(.name) | join(", ")) else empty end),
      (if ((.removedLabels // []) | length) > 0 then "Labels removed: " + ((.removedLabels // []) | map(.name) | join(", ")) else empty end),
      (if (.changes.descriptionUpdatedByIds? // false) then "Description updated" else empty end)
    ] | map(select(length > 0)) | join("; ");

  def history_entry:
    . as $h
    | $h.createdAt as $ts
    | select($ts != null and $ts >= $since)
    | ($h | hist_summary) as $summary
    | select($summary | length > 0)
    | {
        createdAt: $ts,
        actor: (if $h.actor != null then name_or_email($h.actor) else "System" end),
        kind: "history",
        summary: $summary
      };

  def comment_entry:
    . as $c
    | $c.createdAt as $ts
    | select($ts >= $since)
    | {
        createdAt: $ts,
        actor: (if $c.user != null then name_or_email($c.user) else "Unknown" end),
        kind: "comment",
        summary: ("Comment:\n" + (($c.body // "") | gsub("\r"; "")))
      };

  def format_activity:
    "- " + 
    (if .kind == "comment"
     then (.summary | split("\n") | map("  " + .) | join("\n"))
     else "  " + .summary
     end) + " (" + (.createdAt | fmt_ts) + ") — " + .actor;

  def fmt_updated_at:
    if . == null then "unknown"
    else (. | fmt_ts)
    end;

  def state_priority($state):
    if $state == "Done" then 0
    elif $state == "In Review" then 1
    elif $state == "In Progress" then 2
    elif $state == "Todo" then 3
    else 4 end;

  (.data.issues.nodes // [])
  | if length == 0 then "_No updated issues in this window._"
    else (
      map(
        {
          identifier,
          title,
          url,
          updatedAt,
          state: (.state.name // "Unknown"),
          project: .project.name,
          activities: [
            (.history.nodes[]? | history_entry),
            (.comments.nodes[]? | comment_entry)
          ] | sort_by(.createdAt)
        }
      )
      | map(
          {
            state: .state,
            priority: state_priority(.state),
            identifier: .identifier,
            content: (
              "### " + .identifier + " – " + .title
              + (if .project then " {" + .project + "}" else "" end) + "\n"
              + (if (.activities | length) > 0
                 then (.activities | map(format_activity) | join("\n"))
                 else "- No recorded updates."
                 end)
            )
          }
        )
      | sort_by([.priority, .identifier])
      | group_by(.state)
      | map(
          "# " + (.[0].state) + "\n\n"
          + (map(.content) | join("\n\n"))
        )
      | join("\n\n")
    )
  end
' <<<"$response"
