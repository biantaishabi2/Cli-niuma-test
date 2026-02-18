#!/usr/bin/env bash
set -euo pipefail

# 测试仓专用 stub provider：返回可被 niuma 各阶段解析的固定 JSON
cat <<'JSON'
{"summary":"stub summary","approach":"stub approach","title":"stub title","approved":true,"issues":[],"resolved_items":[],"should_finish":true}
JSON
