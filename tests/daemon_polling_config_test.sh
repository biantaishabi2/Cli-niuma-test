#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-.niuma.yml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "FAIL: 配置文件不存在: $CONFIG_FILE"
  exit 1
fi

# 验证 daemon 主配置，确保轮询功能开启。
grep -Eq '^daemon:$' "$CONFIG_FILE" || { echo "FAIL: 缺少 daemon 配置"; exit 1; }
grep -Eq '^[[:space:]]+poll_interval:[[:space:]]*"15s"$' "$CONFIG_FILE" || {
  echo "FAIL: poll_interval 不是预期值 15s"
  exit 1
}
grep -Eq '^[[:space:]]+tracker:[[:space:]]*"github"$' "$CONFIG_FILE" || {
  echo "FAIL: tracker 不是 github"
  exit 1
}
grep -Eq '^[[:space:]]+owner:[[:space:]]*"biantaishabi2"$' "$CONFIG_FILE" || {
  echo "FAIL: github.owner 不是 biantaishabi2"
  exit 1
}
grep -Eq '^[[:space:]]+project_number:[[:space:]]*2$' "$CONFIG_FILE" || {
  echo "FAIL: github.project_number 不是 2"
  exit 1
}

echo "PASS: daemon 轮询配置校验通过"
