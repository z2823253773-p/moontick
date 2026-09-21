# T4：报告与 CLI 差量闭环

任务卡：`docs/handoffs/T4_CLAUDE.md`。实现者：Claude Code。日期：2026-09-21（北京时间闲时）。

## 结论摘要

本轮**有真实 RED**，并据此做了最小实现。这与 T2/T3 的"零改动"不同：T4 是产品实现轮，
默认 text 报告此前根本不存在。

- 先写测试 → 记录真实 RED：`37 tests, 11 failures + 2 errors`。
- 再实现 `report/text.mbt` 与 `cmd/moontick/main.mbt` 的最小改动。
- 两项既有 Json 契约在无 UI 依赖下先行通过（五类截断矩阵、显式/默认等价），
  按任务卡如实记录为"既有行为直接通过"，未伪造 RED。

## 起点基线

- 仓库 `/Users/henryz/Desktop/比赛/moontick`，分支 `main`，工作树干净。
- 起点 HEAD：`100830aad1c95e2999cb62f9c3c22b0d8e1150df`（T4 任务卡提交）。
- 已接受的上一被测 SHA：`8092ac634a9ff92839ccc862ccd0aaddc670e792`（T3）。
  未把文档 SHA `100830a` 当作产品被测 SHA。

## 隔离工具链

`docs/evidence/T4/raw/toolchain.txt`：`moon 0.1.20260920 (914d7da 2026-09-20)`、
`moonc v0.10.14+7d59c7ec9 (2026-09-18)`，均解析到
`/private/tmp/moontick-moon-0.10.14-OS4LNz/bin/`。未使用全局 `~/.moon`，未读凭据。

## 改动文件

| 文件 | 类型 | 说明 |
|---|---|---|
| `report/text.mbt` | 新增 | 纯文本渲染器 |
| `report/text_test.mbt` | 新增 | 11 个进程内渲染器测试 |
| `report/moon.pkg` | 修改 | 加 `moonbitlang/core/double` 导入（仅为 `trunc`） |
| `cmd/moontick/main.mbt` | 修改 | text 分支、错误通道、位置字段、版本串 |
| `tests/cli/test_cli.py` | 修改 | +21 个真实进程用例，测试基类重构 |
| `tests/golden/text-*.txt` | 新增 | 三份 golden 文本报告 |
| `docs/evidence/T4/` | 新增 | 本文件、门槛、原始输出 |

**未改动** `core/*`、`ticks_input/*`、`report/json.mbt`。`report/moon.pkg` 只加了一个
核心库导入，没有扩大任何自有公开 API。

## 一、文本报告

### 输出形状

```text
FAIL
grid: [0,60) step_ms=15
records: 4  expected_points: 4
coverage: 3/4 (75.00%)  missing: 1  longest_missing_run: 1
problems: duplicates=1 out_of_order=0 off_grid=0 out_of_range=0
missing_ranges:
  [2,3)

duplicates:
    ms=15 record=3 line=3

out_of_order:
  none

off_grid:
  none

out_of_range:
  none
```

任务卡要求的字段逐项对应：`PASS`/`FAIL`、网格 `[start_ms,end_ms)` 与 `step_ms`、
`covered_points/expected_points` 与两位小数百分比、missing 与 longest run、
四类问题计数、缺失网格索引半开区间、每类详情的时间戳/记录号/物理行号。

### 关键实现决策

- **百分比只用于显示。** `percent()` 用 `Double` 缩放后 `@double.trunc` 取整，再手工
  放置小数点——既满足 SPEC 2.2"禁止先把 Int64 计数乘 100 导致溢出"，也不依赖本工具链
  对 `Double` 的格式化行为，输出因此字节稳定。
- **通过/失败来自 `report.passed`**，即 core 的精确布尔结果，绝不从显示百分比反推。
  已用 `report/text_test.mbt:49` 与 `:66` 两条测试钉住（1/3 → `33.33%`、2/3 → `66.66%`，
  截断非四舍五入）。
- **`start_lines` 与记录数不符时返回内部错误**，由 CLI 映射退出码 4，不崩溃、不编造行号。

### golden

`tests/golden/text-{complete,empty,duplicates-and-missing}.txt`，对应任务卡指定的
完整、空输入、重复加缺失三种输入，退出码分别 0 / 1 / 1。
`test_golden_text_reports` 断言 stdout 与文件逐字节相同。

**默认 text 与显式 `--format text` 输出逐字节相同**（`test_explicit_text_is_byte_identical_to_the_default`）。

**不泄漏环境信息**：`test_the_text_report_names_no_host_or_absolute_path_or_clock`
断言输出不含输入文件的绝对路径、临时目录、`socket.gethostname()`，且不匹配
`\d{4}-\d{2}-\d{2}` 或 `\d{2}:\d{2}:\d{2}`。

## 二、文本错误通道（行为差异记录）

任务卡要求"用旧/新真实进程输出说明行为差异"。旧二进制为 `8092ac6` 构建产物
（T1 起未变的 `b9e3e189…`），旧行为由 RED 运行
`raw/red-1-before-fix.txt` 的失败断言直接记录；新行为为下方实测。

| 场景 | 旧（8092ac6） | 新 | 退出码 |
|---|---|---|---|
| 默认格式（无 `--format`） | stdout 为 `CONFIG_INVALID: text output is not implemented in T1` | stdout 为完整文本报告 | 0 / 1 |
| text + `INPUT_INVALID` | **stdout** 写诊断行，stderr 空 | **stderr** 写诊断行，**stdout 空** | 2 |
| text + `CONFIG_INVALID` | **stdout** | **stderr**，stdout 空 | 2 |
| text + `IO_ERROR` | **stdout** | **stderr**，stdout 空 | 3 |
| json + 任一错误 | stdout 单个 `moontick.error.v1` | **不变** | 2 / 3 |

实测（新二进制）：

```text
$ moontick check bad.ticks --start-ms 0 --end-ms 60 --step-ms 15
EXIT=2  STDOUT=[]  STDERR=[moontick: INPUT_INVALID: blank lines are not records]
```

与 SPEC 3.2 对照：规格要求"参数已成功解析……输入/配置/I/O 等错误的 stdout 输出单个
错误 JSON"——该句限定在 JSON 模式；text 模式下错误走 stderr、stdout 保持为空，正是
任务卡第 2 条的要求。参数解析失败的 usage 错误沿用旧行为（stderr-only、stdout 空），
未改动。

错误诊断不回显输入内容、不含绝对路径：
`test_text_reports_do_not_leak_the_input_contents`、
`test_io_error_goes_to_stderr_with_stdout_empty`（断言 stderr+stdout 均不含
`/nonexistent`）。

## 三、JSON 位置与截断

### 位置字段

可定位的 ticks 输入错误现在同时带 1-based `record_index` 与 `line`：

```json
{"schema":"moontick.error.v1","code":"INPUT_INVALID","message":"blank lines are not records","record_index":2,"line":2}
```

`record_index` 与 `line` 在本产品中恒等，因为 SPEC 3.1 规定"1-based 记录号等于物理
行号"、适配层提供行号。无法定位时两字段一并省略（`test_an_unlocated_error_omits_both_position_fields`、
`test_a_config_error_omits_both_position_fields`），字节或记录上限错误同样省略
（`error.line == 0` 分支）。

**字段顺序固定**，`record_index` 先于 `line`，由 `render_error` 的构造顺序决定。

### 五类截断（`--detail-limit 1`，真实二进制）

grid 均为 `[0,60)` step 15，四个预期点。表中逗号仅为列举，实际文件每行一项。

| 类别 | 输入 | 完整数量 | 显示 | 其余类别 truncated |
|---|---|---:|---|---|
| missing_ranges | `0,30` | missing=2，区间 `[1,2)`/`[3,4)` | 仅 `[["1","2"]]` | 全 false |
| duplicates | `0,0,0,15,30,45` | duplicate_extra_records=2 | 仅 record 2 | 全 false |
| out_of_order | `30,0,45,15` | out_of_order_records=2 | 仅 record 2 | 全 false |
| off_grid | `0,1,2,15,30,45` | off_grid_records=2 | 仅 record 2 | 全 false |
| out_of_range | `-2,-1,0,15,30,45` | out_of_range_records=2 | 仅 record 1 | 全 false |

全部与任务卡表格一致，且：

- 每例额外断言**除本类别外四类 truncated 均为 false**——截断按类别独立标记。
- **完整计数不受 `detail_limit` 影响**（`summary` 中仍是 2）。
- 显示的是**第一条**而非最后一条：`test_the_truncated_category_shows_the_first_entry_only`
  逐类断言精确首项（如 out_of_range 为 `ms=-2 record=1 line=1`）。
- **恰好等于上限不算截断**：`test_a_category_at_the_limit_is_not_marked_truncated`
  用 1 条重复 + `detail_limit 1` 断言 `truncated=false`，把比较钉在 `>` 而非 `>=`。

## 四、版本

`--version` 现输出 `moontick 0.1.0`，去掉了开发阶段 `(T1)` 标记，保留任务卡要求的
`0.1.0` 版本号。

## 变异抽查（关键断言是否真的绑定）

| 变异 | 改动 | 结果 |
|---|---|---|
| M1 | text 错误通道 `eprintln` → `println` | 3 个错误通道用例失败 |
| M2 | 删除截断提示行 | `text_test.mbt:85`「截断不冒充总数」失败 |
| M3 | 百分比小数点后 +1 | 4 个进程级用例失败（含全部 3 份 golden）+ 2 个进程内用例 |
| M4 | 错误 JSON 丢掉 `record_index` | `test_a_located_input_error_carries_record_index_and_line` 失败 |

四处变异各自只命中对应用例，随后全部还原。**值得记录的是 M2**：它只被进程内用例捕获，
三份 golden 都没抓到——因为任务卡指定的 golden 输入（完整、空、重复加缺失）都不触发
详情截断。这是 golden 覆盖面的一个已知边界，不是缺陷，但 Codex 复核时可据此判断
截断证据的实际来源是 `text_test.mbt` 而非 golden。

## 门槛（`raw/`）

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | `14 warnings, 0 errors`（与 T1–T3 同数，无新增 warning） |
| `moon test --target native` | 0 | `Total tests: 73, passed: 73, failed: 0.`（T3 为 62） |
| `moon test -p .../report -v` | 0 | `19 passed`（T3 为 8） |
| `moon build --target native` | 0 | 0 errors |
| `python3 tests/cli/test_cli.py` | 0 | `Ran 37 tests ... OK`（T3 为 17） |

产品二进制 SHA-256：`a1f590ddda144ab26328e152f89885a0c560ca608a491aa8a79b96697a030497`
（`raw/binary-sha256.txt`）。**与 T1–T3 的 `b9e3e189…` 不同**，本轮确有产品实现变更，
这正是预期。

新增测试数：进程内 +11（report 包 8 → 19），进程级 +21（17 → 37）。

## 未测项（NOT_RUN）

- **Linux native**：仅在 macOS arm64（Darwin 25.4.0）验证。
- **CI**：未配置、未运行。
- **发布 / 报名 / 公开仓库 / 许可**：未执行任何对外动作，无授权。
- **`--format text` 的详情截断 golden**：本轮三份 golden 均不触发截断，
  该路径只有进程内测试覆盖（见上）。
- **非 ASCII / 极长时间戳的文本对齐**：文本报告不面向列对齐，未测终端宽度行为。
