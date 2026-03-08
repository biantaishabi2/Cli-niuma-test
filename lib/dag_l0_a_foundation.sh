#!/usr/bin/env bash

# 统一状态值，避免服务层处理大小写和空白细节。
dag_a_normalize_state() {
  local state="${1:-UNKNOWN}"

  # 去掉首尾空白。
  state="${state#"${state%%[![:space:]]*}"}"
  state="${state%"${state##*[![:space:]]}"}"

  if [[ -z "$state" ]]; then
    echo "UNKNOWN"
    return 0
  fi

  echo "${state^^}"
}

# 判断依赖是否处于 CLOSED，作为服务层的基础判定能力。
dag_a_is_closed_state() {
  [[ "$(dag_a_normalize_state "${1:-}")" == "CLOSED" ]]
}

# 从 issue 正文中提取 blocked-by 依赖编号，按出现顺序去重输出。
dag_a_extract_blocked_by_ids() {
  local issue_body="${1:-}"
  local line raw token dep_id
  local deps=()
  declare -A seen=()

  while IFS= read -r line; do
    if [[ "$line" =~ blocked-by:[[:space:]]*(.*)$ ]]; then
      raw="${BASH_REMATCH[1]}"
      raw="${raw//,/ }"

      for token in $raw; do
        if [[ "$token" =~ ^#?([0-9]+)$ ]]; then
          dep_id="${BASH_REMATCH[1]}"
        elif [[ "$token" =~ ^#?([0-9]+)[^0-9].*$ ]]; then
          dep_id="${BASH_REMATCH[1]}"
        else
          continue
        fi

        if [[ -z "${seen[$dep_id]+x}" ]]; then
          seen[$dep_id]=1
          deps+=("$dep_id")
        fi
      done
    fi
  done <<< "$issue_body"

  if (( ${#deps[@]} > 0 )); then
    printf '%s\n' "${deps[@]}"
  fi
}
