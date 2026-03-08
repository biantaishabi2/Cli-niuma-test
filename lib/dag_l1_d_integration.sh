#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -F dag_a_extract_blocked_by_ids >/dev/null 2>&1; then
  # shellcheck source=lib/dag_l0_a_foundation.sh
  source "$SCRIPT_DIR/dag_l0_a_foundation.sh"
fi

if ! declare -F dag_b_fetch_issue_body >/dev/null 2>&1; then
  # shellcheck source=lib/dag_l0_b_tooling.sh
  source "$SCRIPT_DIR/dag_l0_b_tooling.sh"
fi

# 集成层入口：组合 A(解析/规范化) + B(工具调用) 判定 issue 是否可执行。
dag_d_evaluate_integration_readiness() {
  local repo="${1:-}"
  local issue_number="${2:-}"
  local body_fetcher="${3:-dag_b_fetch_issue_body}"
  local state_fetcher="${4:-dag_b_fetch_issue_state}"

  if [[ -z "$repo" || -z "$issue_number" ]]; then
    echo "ERROR|message=missing required arguments(repo,issue_number)"
    return 2
  fi

  if ! declare -F "$body_fetcher" >/dev/null 2>&1 && ! command -v "$body_fetcher" >/dev/null 2>&1; then
    echo "ERROR|issue=$issue_number|message=body fetcher not found: $body_fetcher"
    return 2
  fi

  if ! declare -F "$state_fetcher" >/dev/null 2>&1 && ! command -v "$state_fetcher" >/dev/null 2>&1; then
    echo "ERROR|issue=$issue_number|message=state fetcher not found: $state_fetcher"
    return 2
  fi

  local issue_body=""
  local body_rc=0

  set +e
  issue_body="$($body_fetcher "$repo" "$issue_number")"
  body_rc=$?
  set -e

  if (( body_rc != 0 )); then
    echo "ERROR|issue=$issue_number|message=failed to fetch issue body via $body_fetcher"
    return 3
  fi

  local dep_ids=()
  mapfile -t dep_ids < <(dag_a_extract_blocked_by_ids "$issue_body")

  if (( ${#dep_ids[@]} == 0 )); then
    echo "READY|issue=$issue_number|dependencies=none"
    return 0
  fi

  local unresolved=()
  local fetch_errors=()
  local dep dep_state_raw dep_state state_rc

  for dep in "${dep_ids[@]}"; do
    set +e
    dep_state_raw="$($state_fetcher "$repo" "$dep")"
    state_rc=$?
    set -e

    if (( state_rc != 0 )); then
      fetch_errors+=("#$dep")
      continue
    fi

    dep_state="$(dag_a_normalize_state "$dep_state_raw")"
    if ! dag_a_is_closed_state "$dep_state"; then
      unresolved+=("#$dep:$dep_state")
    fi
  done

  if (( ${#fetch_errors[@]} > 0 )); then
    local error_summary=""
    local item
    for item in "${fetch_errors[@]}"; do
      if [[ -n "$error_summary" ]]; then
        error_summary+=", "
      fi
      error_summary+="$item"
    done

    echo "ERROR|issue=$issue_number|message=failed to fetch dependency states|failed=$error_summary"
    return 3
  fi

  if (( ${#unresolved[@]} == 0 )); then
    local dep_summary=""

    for dep in "${dep_ids[@]}"; do
      if [[ -n "$dep_summary" ]]; then
        dep_summary+=", "
      fi
      dep_summary+="#$dep"
    done

    echo "READY|issue=$issue_number|dependencies=$dep_summary"
    return 0
  fi

  local unresolved_summary=""
  local unresolved_item

  for unresolved_item in "${unresolved[@]}"; do
    if [[ -n "$unresolved_summary" ]]; then
      unresolved_summary+=", "
    fi
    unresolved_summary+="$unresolved_item"
  done

  echo "BLOCKED|issue=$issue_number|waiting=$unresolved_summary"
  return 1
}
