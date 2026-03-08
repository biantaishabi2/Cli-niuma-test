#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=tests/test_helpers.sh
source "$ROOT_DIR/tests/test_helpers.sh"
# shellcheck source=lib/dag_l1_c_service.sh
source "$ROOT_DIR/lib/dag_l1_c_service.sh"

fake_issue_state_resolver() {
  case "$1" in
    562) echo "CLOSED" ;;
    563) echo "OPEN" ;;
    *) echo "UNKNOWN" ;;
  esac
}

# 场景 1：#564 依赖 #562，且 #562 已关闭，服务层应允许执行。
issue_564_body=$'L1 节点，等 A 完成后执行。\n\nblocked-by: #562'
run_and_capture output status dag_c_evaluate_issue_readiness 564 "$issue_564_body" fake_issue_state_resolver
assert_eq "0" "$status" "场景1失败：#562 CLOSED 时 #564 应 READY"
assert_contains "$output" "READY|issue=564" "场景1失败：输出应为 READY"

# 场景 2：多依赖中存在 OPEN，服务层应返回阻塞并列出等待项。
issue_multi_body=$'L1 节点，依赖 A+B。\n\nblocked-by: #562, #563'
run_and_capture output status dag_c_evaluate_issue_readiness 565 "$issue_multi_body" fake_issue_state_resolver
assert_eq "1" "$status" "场景2失败：存在 OPEN 依赖时应 BLOCKED"
assert_contains "$output" "BLOCKED|issue=565" "场景2失败：输出应为 BLOCKED"
assert_contains "$output" "#563:OPEN" "场景2失败：应标记 OPEN 依赖"

# 场景 3：blocked-by 重复编号应被去重，避免误判和重复等待项。
issue_duplicate_body=$'blocked-by: #562, #562, #563'
run_and_capture output status dag_c_evaluate_issue_readiness 566 "$issue_duplicate_body" fake_issue_state_resolver
assert_eq "1" "$status" "场景3失败：存在 #563 OPEN 时仍应 BLOCKED"
assert_contains "$output" "waiting=#563:OPEN" "场景3失败：去重后仅应保留真实阻塞项"

echo "PASS: dag_l1_c_service_bdd_test"
