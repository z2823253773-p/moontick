# Codex 独立复核：T4 `6d97745`（需最小修复）

固定被测提交：`6d9774519c2c9cb20376af7d79a32c0fea63732e`。在 detached
worktree `/private/tmp/moontick-t4-verify` 复核；未在主 checkout 写入产品代码。
隔离工具链为 `moon 0.1.20260920`、`moonc v0.10.14+7d59c7ec9`。

| 命令 | 独立结果 |
|---|---:|
| `moon check --target native` | 退出 0；14 warnings / 0 errors |
| `moon test --target native` | 退出 0；73/73 |
| `moon test --target native -p z2823253773-p/moontick/report -v` | 退出 0；19/19 |
| `moon build --target native` | 退出 0 |
| 真实 `moontick.exe` 的 `python3 tests/cli/test_cli.py` | 退出 0；37/37 |

上述门槛证明已有测试通过，**不能覆盖以下真实反例**。两例均由本 worktree 的实际
编译产物运行得到，退出码均为 1；JSON/核心计数不在本次发现范围内。

## P1：百分比会显示错误数值

最小输入：ticks 文件为 `0\n1\n`，计划 `[0,3)`、`step_ms=1`，默认 text。
精确覆盖率为 `2/3`，按 `docs/planning/02_SPEC.md` 2.2 的两位小数四舍五入口径，
应显示 `66.67%`；实际显示 `66.66%`。`report/text_test.mbt` 目前把 `66.66%`
写成期望值，需与修复同步纠正。

即使按当前“截断”解释也会出错：ticks 为 `0` 至 `56` 各一行，计划 `[0,100)`、
`step_ms=1`，精确覆盖率为 `57/100=57%`，应显示 `57.00%`；实际为 `56.99%`。
根因是 `report/text.mbt` 的 `(covered.to_double()/expected.to_double())*10000`
可能略小于精确整数，再 `trunc` 会少一分。修复仅限展示层；不可用百分比反推
`report.passed`，也不可先在 Int64 中乘 100 或 10000。加入上述两例的进程级回归。

## P2：缺失区间截断提示混淆“区间数”和“缺失点数”

输入 ticks 为 `0\n50\n`，计划 `[0,100)`、`step_ms=1`、`--detail-limit 1`。
真实缺失点 98 个，分为两个区间 `[1,50)` 与 `[51,100)`。实际文本为：

```text
missing_ranges:
  (showing first 1 of 98; truncated)
  [1,50)
```

`report/text.mbt` 在“showing first 1 of ...”中使用了 `missing_points=98`，
读者会以为共有 98 个缺失区间。当前 `AuditReport` 不公开总区间数，无需为这句文案
扩展公共 schema。可改为明确的“显示前 1 个缺失区间；总共缺失 98 个点；详情已截断”
之类措辞，并补一个真实 text CLI 用例或截断 golden。不能把所展示区间数与总缺失
点数写成同一种计数。

## 交接与范围

T4 暂不验收；请 Claude Code 在用户手动启动的北京时间闲时完成这两处最小修复，
保留反例并运行完整门槛，提交新的固定产品 SHA 供 Codex 独立复核。
`tests/cli/__pycache__/` 是未追踪生成物；本轮单独在 `.gitignore` 忽略
`__pycache__/` 与 `*.pyc`，未删除用户目录中的文件，也未把缓存加入被测提交。

`git diff --check 6d97745^ 6d97745` 因原始 warning 日志尾随空格和三份 golden 的
EOF 空行退出 2；与上述产品行为反例区分记录。Linux、CI、发布、报名仍未运行。
