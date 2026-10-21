#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: linear-sprint.sh [TEAM_KEY]

Print the active Linear cycle (sprint) for a team as markdown,
grouped by state (In Progress / To Do / Backlog / Completed / Canceled).
Each issue line includes its identifier, title, current state, assignee,
point estimate, and {project} when the issue belongs to one.

The header leads with the cycle's name (what the team calls the sprint),
falling back to Linear's internal per-team counter when the cycle is
unnamed. The date range shows the last day actually in the cycle, not
Linear's exclusive end boundary.

Each section heading carries its point subtotal, and a capacity line under
the date range reports working days, capacity, and total points scoped.

Arguments:
  TEAM_KEY    Linear team key (e.g. ASC, ENG). Defaults to ASC.

Options:
  -h, --help  Show this help and exit.
  --raw       Print the raw Linear API response as JSON and exit. Useful when
              a state is not showing up where you expect it.

Environment:
  LINEAR_API_KEY               Required. Sourced from ~/.secrets if unset.
  LINEAR_SPRINT_POINTS_PER_DAY Capacity target per working day. Defaults to 6.
  LINEAR_SPRINT_TOTALS         Set to 0 to suppress the capacity line and the
                               per-section point subtotals.
USAGE
}

raw_output=0
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --raw) raw_output=1; shift ;;
esac

team_key="${1:-ASC}"

if [[ -z "${LINEAR_API_KEY:-}" && -e ~/.secrets ]]; then
  # shellcheck source=/dev/null
  source ~/.secrets
fi

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "Error: please export LINEAR_API_KEY" >&2
  exit 1
fi

# --- capacity reporting (remove this block and the two marked blocks below
# --- to return to the plain listing) -----------------------------------------
points_per_working_day="${LINEAR_SPRINT_POINTS_PER_DAY:-6}"
show_totals="${LINEAR_SPRINT_TOTALS:-1}"

# Counts Mon-Fri between two inclusive ISO dates.
count_working_days() {
  local cursor="$1" last="$2" count=0 day_of_week
  while [[ ! "$cursor" > "$last" ]]; do
    day_of_week=$(date -j -f "%Y-%m-%d" "$cursor" "+%u")
    if (( day_of_week <= 5 )); then
      count=$((count + 1))
    fi
    cursor=$(date -j -v+1d -f "%Y-%m-%d" "$cursor" "+%Y-%m-%d")
  done
  echo "$count"
}
# --- end capacity reporting block --------------------------------------------

graphql_query=$(cat <<EOF
query Cycle {
  teams(filter: { key: { eq: "$team_key" } }, first: 1) {
    nodes {
      key
      name
      activeCycle {
        number
        name
        startsAt
        endsAt
        issues(first: 50) {
          nodes {
            identifier
            title
            url
            estimate
            state { name type }
            assignee { name }
            project { name }
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

if [[ "$raw_output" == "1" ]]; then
  jq . <<<"$response"
  exit 0
fi

if [[ "$(jq -r 'has("errors")' <<<"$response")" == "true" ]]; then
  echo "Error from Linear API:" >&2
  jq -r '.errors[].message' <<<"$response" >&2
  exit 1
fi

if [[ "$(jq -r '.data.teams.nodes | length' <<<"$response")" == "0" ]]; then
  echo "Error: no team found with key '$team_key'" >&2
  exit 1
fi

if [[ "$(jq -r '.data.teams.nodes[0].activeCycle' <<<"$response")" == "null" ]]; then
  echo "Error: team '$team_key' has no active cycle" >&2
  exit 1
fi

team_name=$(jq -r '.data.teams.nodes[0].name' <<<"$response")
cycle_number=$(jq -r '.data.teams.nodes[0].activeCycle.number' <<<"$response")
cycle_name=$(jq -r '.data.teams.nodes[0].activeCycle.name // ""' <<<"$response")
starts=$(jq -r '.data.teams.nodes[0].activeCycle.startsAt | split("T")[0]' <<<"$response")
ends_exclusive=$(jq -r '.data.teams.nodes[0].activeCycle.endsAt | split("T")[0]' <<<"$response")

# Linear's endsAt is midnight at the start of the following cycle's first day,
# so the last day actually in this cycle is the day before it.
ends=$(date -j -v-1d -f "%Y-%m-%d" "$ends_exclusive" "+%Y-%m-%d")

# The team refers to a cycle by its name; Linear's `number` is an internal
# per-team counter and is only a fallback when the cycle is unnamed.
if [[ -n "$cycle_name" ]]; then
  header="# $team_name — $cycle_name"
else
  header="# $team_name — Cycle $cycle_number"
fi

echo "$header"
echo "$starts → $ends (inclusive)"

# --- capacity reporting block ------------------------------------------------
if [[ "$show_totals" != "0" ]]; then
  # Canceled and duplicate work is not scope, so it is left out of the total.
  scoped_points=$(jq -r '
    [ .data.teams.nodes[0].activeCycle.issues.nodes[]
      | select(.state.type != "canceled" and .state.type != "duplicate")
      | .estimate // 0
    ] | add // 0
  ' <<<"$response")
  scoped_unestimated=$(jq -r '
    [ .data.teams.nodes[0].activeCycle.issues.nodes[]
      | select(.state.type != "canceled" and .state.type != "duplicate" and .estimate == null)
    ] | length
  ' <<<"$response")

  working_days=$(count_working_days "$starts" "$ends")
  capacity=$((working_days * points_per_working_day))

  totals_line="$working_days working days · $capacity pt capacity · $scoped_points pt scoped"
  if (( scoped_unestimated > 0 )); then
    totals_line="$totals_line · $scoped_unestimated unestimated"
  fi
  echo "$totals_line"
fi
# --- end capacity reporting block --------------------------------------------

echo ""

known_types="started unstarted backlog triage completed canceled duplicate"

# Any state type the cycle contains that the list above does not name. Linear
# adds types over time - `duplicate` was one - and without this they are
# silently dropped from the listing while still sitting in the cycle.
unknown_types=$(jq -r --arg known "$known_types" '
  ($known | split(" ")) as $known
  | [ .data.teams.nodes[0].activeCycle.issues.nodes[].state.type ]
  | unique
  | map(select(. as $type | $known | index($type) | not))
  | .[]
' <<<"$response")

for state_type in $known_types $unknown_types; do
  items=$(jq -r --arg t "$state_type" '
    .data.teams.nodes[0].activeCycle.issues.nodes
    | map(select(.state.type == $t))
    | sort_by(.identifier)
    | .[]
    | "- [\(.identifier)](\(.url)) — \(.title)"
      + (if .state.name then " `\(.state.name)`" else "" end)
      + (if .assignee then " _(\(.assignee.name))_" else "" end)
      + (if .estimate then " [\(.estimate)pt]" else "" end)
      + (if .project then " {\(.project.name)}" else "" end)
  ' <<<"$response")

  if [[ -n "$items" ]]; then
    case "$state_type" in
      started)   label="In Progress" ;;
      unstarted) label="To Do" ;;
      backlog)   label="Backlog" ;;
      triage)    label="Triage" ;;
      completed) label="Completed" ;;
      canceled)  label="Canceled" ;;
      duplicate) label="Duplicate" ;;
      *)         label="$(tr '[:lower:]' '[:upper:]' <<<"${state_type:0:1}")${state_type:1}" ;;
    esac

    # --- capacity reporting block --------------------------------------------
    if [[ "$show_totals" != "0" ]]; then
      section_points=$(jq -r --arg t "$state_type" '
        [ .data.teams.nodes[0].activeCycle.issues.nodes[]
          | select(.state.type == $t)
          | .estimate // 0
        ] | add // 0
      ' <<<"$response")
      section_unestimated=$(jq -r --arg t "$state_type" '
        [ .data.teams.nodes[0].activeCycle.issues.nodes[]
          | select(.state.type == $t and .estimate == null)
        ] | length
      ' <<<"$response")

      if (( section_unestimated > 0 )); then
        label="$label ($section_points pt, $section_unestimated unestimated)"
      else
        label="$label ($section_points pt)"
      fi
    fi
    # --- end capacity reporting block ----------------------------------------

    echo "## $label"
    echo "$items"
    echo ""
  fi
done
