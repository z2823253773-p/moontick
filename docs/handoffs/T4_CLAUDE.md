# T4：Claude Code 实施任务卡（报告与 CLI 差量闭环）

## 基线、授权与工作时段

- 仓库 `/Users/henryz/Desktop/比赛/moontick`，启动前核对 `main` 的 HEAD 与干净工作树。
  当前 T3 验收文档提交为 `66bfcfe`；已接受的最新被测实现/测试 SHA 是
  `8092ac634a9ff92839ccc862ccd0aaddc670e792`。文档 SHA 不是产品被测 SHA。
- 先读 `AGENTS.md`、`CLAUDE.md`、`.ai/TASK_STATE.md`、
  `docs/planning/02_SPEC.md` 第 2.2/3.2/4/6 节和 `docs/planning/04_TASK_PLAN.md` 的 T4。
- 用户要求继续按既定 T4 计划；Claude Code 只由用户手动在北京时间闲时启动。
  工作日 09:00–12:00、14:00–18:00 停止；周末可全天。接近高峰时记录状态并停止，
  不设置定时任务或后台续跑。
- 使用隔离工具链 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，把
  `$MOON_HOME/bin` 加到 PATH，现场输出 `moon version --all` / `moonc -v`。
  不读取、输出、复制凭据；隔离路径不可用时记录错误，不静默改用全局 `~/.moon`。

## 已实现，不重复重写

T1–T3 已在 macOS native 验收：JSON 审计/错误 schema、五类计数和详情、Int64 字符串、
真实进程退出码 0/1/2/3、help/version、usage stderr、字节稳定 JSON、严格 ticks 解析
与行号；当前全仓 62/62、真实 CLI 17/17。`report/json.mbt`、`cmd/moontick/args.mbt`
与 `tests/cli/test_cli.py` 有可复用实现。本轮不重构 core 或 ticks_input，不引入 CSV、
stdin、网络、Linux、CI、发布或报名。

明确缺口：默认 `--format text` 当前返回 `CONFIG_INVALID`，而规格要求它能输出报告；
非 JSON 的已解析命令错误当前可能写到 stdout；详情截断尚缺真实进程级的全类别证据。

## 本轮行为契约

1. **文本报告。** 新增 `report/text.mbt` 的纯渲染函数，消费既有 `AuditReport` 和
   `start_lines`，不读文件/时钟。默认格式与显式 `--format text` 在完整和有问题的
   ticks 文件上分别退出 0/1，stdout 是一份稳定、易读的报告，stderr 为空。
   报告至少给出 `PASS`/`FAIL`、网格 `[start_ms,end_ms)` 与 `step_ms`、
   `covered_points/expected_points` 和两位小数百分比、missing 与 longest run、
   duplicate/out_of_order/off_grid/out_of_range 全部计数、各缺失网格索引半开区间、
   各问题详情的时间戳/记录号/物理行号。详情达上限时逐类明确写出截断，
   不能把显示条数说成总数。输出不带主机名、绝对文件路径或运行时刻。
   百分比只用于显示；通过/失败必须来自精确布尔结果，计算不能先用 Int64 乘 100。
   `start_lines` 与记录数不一致时，文本渲染也须返回内部错误，由 CLI 映射退出码 4，
   不崩溃或编造行号。对固定的完整、空输入、重复加缺失三种输入写可审查的完整
   golden 输出；默认 text 与显式 `--format text` 的输出逐字节相同。
2. **文本错误通道。** 参数解析失败沿用 stderr-only、stdout 为空。参数已经解析、
   选择 text 后的 `CONFIG_INVALID`、`INPUT_INVALID`、`RESOURCE_LIMIT`、`IO_ERROR`
   均写 stderr，stdout 为空，退出码沿用规格的 2/3；JSON 模式继续在 stdout
   输出单个 `moontick.error.v1`。错误不回显整份输入或绝对文件路径。
3. **JSON 位置与截断。** ticks 中能定位到物理行的输入错误同时带 1-based
   `record_index` 与 `line`；无法定位时两字段省略。保持已有正常 JSON schema 和
   字节稳定性。用真实 CLI 的 `--detail-limit 1` 分别覆盖五类详情：

   | 类别 | 示例输入（每项单独文件，grid 0/60/15） | 完整数量与截断 |
   |---|---|---|
   | missing_ranges | `0,30` | missing=2，区间 `[1,2)` 与 `[3,4)`，只显示第一段，truncated=true |
   | duplicates | `0,0,0,15,30,45` | duplicate_extra_records=2，只显示 record 2，truncated=true |
   | out_of_order | `30,0,45,15` | out_of_order_records=2，只显示 record 2，truncated=true |
   | off_grid | `0,1,2,15,30,45` | off_grid_records=2，只显示 record 2，truncated=true |
   | out_of_range | `-2,-1,0,15,30,45` | out_of_range_records=2，只显示 record 1，truncated=true |

   表中逗号仅为任务卡列举，实际 ticks 文件每行一项。每个案例还断言其他类别的
   truncated 标志按实际详情数量计算，完整计数不受 `detail_limit` 影响。
4. **版本与边界。** 完成默认 text 后，`--version` 不再显示开发阶段 `(T1)` 标记；
   保留已声明的 `0.1.0` 版本号。不得为方便测试扩张 core/ticks 的公开 API，
   也无需导出 T3 的私有资源常量。

## 实施顺序和验收

先新增/扩展 `report/*_test.mbt` 和 `tests/cli/test_cli.py` 的精确用例，运行定向测试，
记录真实 RED；然后只改 `report/text.mbt`、必要的 `cmd/moontick/main.mbt` 与精确位置
映射。若已有行为直接通过某项新增测试，如实记录，不伪造 RED。对错误输出通道和
JSON 位置字段的修改，用旧/新真实进程输出说明行为差异，并审查是否符合规格。

完成后使用真实编译产物运行并记录退出码、测试数量、warnings 和未测项：

```bash
moon check --target native
moon test --target native
moon build --target native
export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

把 golden 样例与证据保存在 `tests/golden/`、`docs/evidence/T4/`，更新
`.ai/TASK_STATE.md` 为 `REVIEW / Codex`，提交一个明确 T4 SHA。交接说明改动文件、
文本完整输出、各错误通道/退出码、五类截断结果、产品二进制 SHA 与未测项。
Codex 在该固定 SHA 的独立 worktree 复核文本、JSON、真实进程和回归门槛。
