#!/usr/bin/env bash

# 检查 gh CLI 是否可用。
dag_b_require_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi

  echo "ERROR|message=gh cli not found"
  return 127
}

# 通过 gh 获取 issue 正文。
dag_b_fetch_issue_body() {
  local repo="${1:-}"
  local issue_number="${2:-}"

  if [[ -z "$repo" || -z "$issue_number" ]]; then
    echo "ERROR|message=missing required arguments(repo,issue_number)"
    return 2
  fi

  dag_b_require_gh || return $?

  gh issue view "$issue_number" \
    --repo "$repo" \
    --json body \
    --jq '.body'
}

# 通过 gh 获取 issue 状态（OPEN/CLOSED）。
dag_b_fetch_issue_state() {
  local repo="${1:-}"
  local issue_number="${2:-}"

  if [[ -z "$repo" || -z "$issue_number" ]]; then
    echo "ERROR|message=missing required arguments(repo,issue_number)"
    return 2
  fi

  dag_b_require_gh || return $?

  gh issue view "$issue_number" \
    --repo "$repo" \
    --json state \
    --jq '.state'
}
