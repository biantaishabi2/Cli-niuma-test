#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=tests/test_helpers.sh
source "$ROOT_DIR/tests/test_helpers.sh"
# shellcheck source=lib/dag_l1_c_service.sh
source "$ROOT_DIR/lib/dag_l1_c_service.sh"

mock_resolver_all_closed() {
  echo "CLOSED"
}

mock_resolver_mixed() {
  case "$1" in
    562) echo "OPEN" ;;
    *) echo "CLOSED" ;;
  esac
}

issue_body_single_dep=$'L1 节点，等 A 完成后执行。\n\nblocked-by: #562'
issue_body_multi_dep=$'blocked-by: #562, #700'

output=""
status=""

run_and_capture output status dag_c_evaluate_issue_readiness 564 "$issue_body_single_dep" mock_resolver_all_closed
assert_eq "0" "$status" "全部依赖关闭时应返回成功状态"
assert_contains "$output" "READY|issue=564" "全部依赖关闭时应返回 READY"
assert_contains "$output" "dependencies=#562" "应包含依赖摘要"

run_and_capture output status dag_c_evaluate_issue_readiness 564 "$issue_body_multi_dep" mock_resolver_mixed
assert_eq "1" "$status" "存在未关闭依赖时应返回阻塞状态"
assert_contains "$output" "BLOCKED|issue=564" "未满足依赖时应返回 BLOCKED"
assert_contains "$output" "#562:OPEN" "阻塞信息应包含未关闭依赖"

run_and_capture output status dag_c_evaluate_issue_readiness 564 "" mock_resolver_all_closed
assert_eq "0" "$status" "无 blocked-by 时应视为可执行"
assert_contains "$output" "dependencies=none" "无依赖时应标记 none"

run_and_capture output status dag_c_evaluate_issue_readiness 564 "$issue_body_single_dep" missing_resolver_for_test
assert_eq "2" "$status" "resolver 缺失时应返回参数错误"
assert_contains "$output" "resolver not found" "错误信息应提示 resolver 不存在"

echo "PASS: dag_l1_c_service_unit_test"
