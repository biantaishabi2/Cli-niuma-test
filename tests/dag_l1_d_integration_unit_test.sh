#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=tests/test_helpers.sh
source "$ROOT_DIR/tests/test_helpers.sh"
# shellcheck source=lib/dag_l1_d_integration.sh
source "$ROOT_DIR/lib/dag_l1_d_integration.sh"

mock_body_with_multi_deps() {
  cat <<'BODY'
L1 节点，等 A 和 B 都完成后执行。

blocked-by: #562, #563
BODY
}

mock_body_without_deps() {
  echo "no dependencies declared"
}

mock_state_all_closed() {
  echo "CLOSED"
}

mock_state_mixed() {
  case "$2" in
    562) echo "CLOSED" ;;
    563) echo "OPEN" ;;
    *) echo "UNKNOWN" ;;
  esac
}

mock_state_fail_on_563() {
  case "$2" in
    563) return 9 ;;
    *) echo "CLOSED" ;;
  esac
}

mock_body_fetch_fail() {
  return 5
}

output=""
status=""

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 mock_body_with_multi_deps mock_state_all_closed
assert_eq "0" "$status" "全部依赖关闭时应 READY"
assert_contains "$output" "READY|issue=565" "全部依赖关闭时应输出 READY"
assert_contains "$output" "dependencies=#562, #563" "应输出完整依赖摘要"

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 mock_body_with_multi_deps mock_state_mixed
assert_eq "1" "$status" "存在 OPEN 依赖时应 BLOCKED"
assert_contains "$output" "BLOCKED|issue=565" "应输出 BLOCKED"
assert_contains "$output" "#563:OPEN" "应包含未满足依赖"

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 mock_body_without_deps mock_state_all_closed
assert_eq "0" "$status" "无 blocked-by 时应 READY"
assert_contains "$output" "dependencies=none" "无依赖时应标记 none"

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 mock_body_with_multi_deps mock_state_fail_on_563
assert_eq "3" "$status" "依赖状态获取失败时应返回错误"
assert_contains "$output" "failed to fetch dependency states" "应提示依赖状态获取失败"
assert_contains "$output" "failed=#563" "应标记失败依赖"

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 mock_body_fetch_fail mock_state_all_closed
assert_eq "3" "$status" "issue 正文获取失败时应返回错误"
assert_contains "$output" "failed to fetch issue body" "应提示正文获取失败"

run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565 missing_body_fetcher mock_state_all_closed
assert_eq "2" "$status" "body fetcher 缺失应返回参数错误"
assert_contains "$output" "body fetcher not found" "应提示 fetcher 不存在"

echo "PASS: dag_l1_d_integration_unit_test"
