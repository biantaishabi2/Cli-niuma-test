#!/bin/bash
set -euo pipefail

# gate retry 测试：同一重试上下文首次失败，后续重试成功
RAW_ATTEMPT_KEY="${attempt_key:-${ATTEMPT_KEY:-default}}"
# 兼容部分调用方把轮次编码进 key（例如 xxx-attempt-1/2）
NORMALIZED_ATTEMPT_KEY="$(echo "$RAW_ATTEMPT_KEY" | sed -E 's/-attempt-[0-9]+$//')"
MARKER_DIR="${RUNNER_TEMP:-/tmp}/niuma-test-gate-retry"
MARKER_FILE="${MARKER_DIR}/${NORMALIZED_ATTEMPT_KEY}.ok"

mkdir -p "$MARKER_DIR"

if [ ! -f "$MARKER_FILE" ]; then
  echo "FAIL: intentional gate failure for testing"
  echo "Test assertion error: expected 'success' got 'failure'"
  : > "$MARKER_FILE"
  exit 1
fi

echo "PASS: gate retry marker detected"
echo "Test assertion success: expected 'success' got 'success'"
exit 0
