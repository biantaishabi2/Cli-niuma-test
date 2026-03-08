#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -F dag_a_extract_blocked_by_ids >/dev/null 2>&1; then
  # shellcheck source=lib/dag_l0_a_foundation.sh
  source "$SCRIPT_DIR/dag_l0_a_foundation.sh"
fi

# 根据 blocked-by 依赖状态给出服务层可执行性判定。
dag_c_evaluate_issue_readiness() {
  local issue_number="${1:-}"
  local issue_body="${2:-}"
  local resolver_cmd="${3:-}"

  if [[ -z "$issue_number" || -z "$resolver_cmd" ]]; then
    echo "ERROR|message=missing required arguments(issue_number,resolver_cmd)"
    return 2
  fi

  if ! declare -F "$resolver_cmd" >/dev/null 2>&1 && ! command -v "$resolver_cmd" >/dev/null 2>&1; then
    echo "ERROR|issue=$issue_number|message=resolver not found: $resolver_cmd"
    return 2
  fi

  local dep_ids=()
  mapfile -t dep_ids < <(dag_a_extract_blocked_by_ids "$issue_body")

  if (( ${#dep_ids[@]} == 0 )); then
    echo "READY|issue=$issue_number|dependencies=none"
    return 0
  fi

  local unresolved=()
  local dep dep_state

  for dep in "${dep_ids[@]}"; do
    dep_state="$("$resolver_cmd" "$dep")"
    dep_state="$(dag_a_normalize_state "$dep_state")"

    if ! dag_a_is_closed_state "$dep_state"; then
      unresolved+=("#$dep:$dep_state")
    fi
  done

  local dep_summary=""
  for dep in "${dep_ids[@]}"; do
    if [[ -n "$dep_summary" ]]; then
      dep_summary+=", "
    fi
    dep_summary+="#$dep"
  done

  if (( ${#unresolved[@]} == 0 )); then
    echo "READY|issue=$issue_number|dependencies=$dep_summary"
    return 0
  fi

  local unresolved_summary=""
  local item
  for item in "${unresolved[@]}"; do
    if [[ -n "$unresolved_summary" ]]; then
      unresolved_summary+=", "
    fi
    unresolved_summary+="$item"
  done

  echo "BLOCKED|issue=$issue_number|waiting=$unresolved_summary"
  return 1
}
