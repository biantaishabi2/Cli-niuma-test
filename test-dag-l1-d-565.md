# DAG-L1-D 集成层测试场景（#565）

## 场景 1：A+B 依赖全部关闭时放行
- 输入：issue `#565` body 为 `blocked-by: #562, #563`，状态查询结果 `#562 -> CLOSED`、`#563 -> CLOSED`
- 预期输出：`dag_d_evaluate_integration_readiness` 返回码 `0`，输出包含 `READY|issue=565` 与 `dependencies=#562, #563`

## 场景 2：存在未满足依赖时阻塞
- 输入：issue `#565` body 为 `blocked-by: #562, #563`，状态查询结果 `#562 -> CLOSED`、`#563 -> OPEN`
- 预期输出：返回码 `1`，输出包含 `BLOCKED|issue=565` 且等待项包含 `#563:OPEN`

## 场景 3：无依赖声明时默认可执行
- 输入：issue body 不包含 `blocked-by`
- 预期输出：返回码 `0`，输出包含 `dependencies=none`

## 场景 4：边界条件 - 依赖状态查询失败
- 输入：issue `#565` 依赖 `#562,#563`，其中 `#563` 状态查询失败
- 预期输出：返回码 `3`，输出包含 `ERROR|issue=565`，并包含 `failed=#563`

## 场景 5：边界条件 - fetcher 缺失或参数缺失
- 输入：未传 repo/issue，或传入不存在的 body/state fetcher
- 预期输出：返回码 `2`，输出包含对应的参数错误信息
