# daemon 轮询测试（#560）

## 场景 1：Queued issue 自动派发
- 输入：issue `#560` 在 GitHub Project（`project_number=2`）状态为 `Queued`
- 预期输出：daemon 轮询命中该 issue 并触发 `niuma fix` 派发（进入 `bot:fix` 流程）

## 场景 2：非 Queued issue 不派发
- 输入：issue 状态不为 `Queued`（例如 `Done` / `In Progress`）
- 预期输出：daemon 不触发 `niuma fix` 派发

## 场景 3：配置回归校验
- 输入：执行 `bash tests/daemon_polling_config_test.sh`
- 预期输出：返回 `PASS: daemon 轮询配置校验通过`
