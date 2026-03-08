# DAG-L1-C 服务层测试场景（#564）

## 场景 1：依赖已满足时放行
- 输入：issue `#564` body 包含 `blocked-by: #562`，依赖查询结果 `#562 -> CLOSED`
- 预期输出：`dag_c_evaluate_issue_readiness` 返回码 `0`，输出包含 `READY|issue=564`

## 场景 2：存在未满足依赖时阻塞
- 输入：issue `#565` body 包含 `blocked-by: #562, #563`，依赖查询结果 `#562 -> CLOSED`、`#563 -> OPEN`
- 预期输出：返回码 `1`，输出包含 `BLOCKED|issue=565` 且等待项包含 `#563:OPEN`

## 场景 3：无依赖声明时默认可执行
- 输入：issue body 不包含 `blocked-by`
- 预期输出：返回码 `0`，输出包含 `dependencies=none`

## 场景 4：边界条件 - 重复依赖去重
- 输入：`blocked-by: #562, #562, #563`
- 预期输出：依赖解析去重，不重复统计 `#562`；当 `#563` 为 `OPEN` 时仍返回 `BLOCKED`

## 场景 5：边界条件 - resolver 缺失
- 输入：调用服务层时传入不存在的 resolver
- 预期输出：返回码 `2`，输出包含 `resolver not found`
