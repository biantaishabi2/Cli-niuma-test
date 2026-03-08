#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=tests/test_helpers.sh
source "$ROOT_DIR/tests/test_helpers.sh"
# shellcheck source=lib/dag_l1_d_integration.sh
source "$ROOT_DIR/lib/dag_l1_d_integration.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/gh" <<'MOCK_GH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "issue" || "${2:-}" != "view" ]]; then
  echo "unsupported command" >&2
  exit 10
fi

issue_number="${3:-}"
shift 3

repo=""
json_field=""

while (( $# > 0 )); do
  case "$1" in
    --repo)
      repo="$2"
      shift 2
      ;;
    --json)
      json_field="$2"
      shift 2
      ;;
    --jq)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "$repo" != "biantaishabi2/Cli-niuma-test" ]]; then
  echo "unexpected repo: $repo" >&2
  exit 11
fi

case "$json_field" in
  body)
    case "$issue_number" in
      565)
        cat <<'BODY'
L1 节点，等 A 和 B 都完成后执行。

blocked-by: #562, #563
BODY
        ;;
      700)
        echo "这是一个无依赖 issue"
        ;;
      *)
        echo "unknown issue" >&2
        exit 12
        ;;
    esac
    ;;
  state)
    case "$issue_number" in
      562)
        echo "CLOSED"
        ;;
      563)
        if [[ "${MOCK_FAIL_563:-0}" == "1" ]]; then
          exit 13
        fi
        echo "${MOCK_563_STATE:-OPEN}"
        ;;
      *)
        echo "OPEN"
        ;;
    esac
    ;;
  *)
    echo "unsupported json field: $json_field" >&2
    exit 14
    ;;
esac
MOCK_GH

chmod +x "$TMP_DIR/gh"
PATH="$TMP_DIR:$PATH"

output=""
status=""

# 场景 1：默认 #563 OPEN，D 层应给出 BLOCKED。
run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565
assert_eq "1" "$status" "场景1失败：存在 OPEN 依赖时应 BLOCKED"
assert_contains "$output" "BLOCKED|issue=565" "场景1失败：输出应为 BLOCKED"
assert_contains "$output" "#563:OPEN" "场景1失败：应显示等待 #563"

# 场景 2：切换 #563 CLOSED，D 层应 READY。
MOCK_563_STATE="CLOSED" run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565
assert_eq "0" "$status" "场景2失败：依赖全 CLOSED 时应 READY"
assert_contains "$output" "READY|issue=565" "场景2失败：输出应为 READY"
assert_contains "$output" "dependencies=#562, #563" "场景2失败：应输出依赖摘要"

# 场景 3：无 blocked-by 时默认可执行。
run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 700
assert_eq "0" "$status" "场景3失败：无依赖应 READY"
assert_contains "$output" "dependencies=none" "场景3失败：应标记 none"

# 场景 4：依赖状态查询失败时返回 ERROR。
MOCK_FAIL_563="1" run_and_capture output status dag_d_evaluate_integration_readiness biantaishabi2/Cli-niuma-test 565
assert_eq "3" "$status" "场景4失败：状态查询失败应 ERROR"
assert_contains "$output" "ERROR|issue=565" "场景4失败：输出应为 ERROR"
assert_contains "$output" "failed=#563" "场景4失败：应标识失败依赖"

echo "PASS: dag_l1_d_integration_bdd_test"
