# T2 精确契约测试：新增覆盖与真实结果

日期：2026-09-21（北京时间）。执行者：Claude Code。任务卡：`docs/handoffs/T2_CLAUDE.md`。

- 起点基线 SHA：`e329b5a935dfc22cff616fbc5239bf857c6e654a`（工作树干净）
- 已接受产品实现 SHA：`754ff0ea7eae10cc416f6207ce94277395ddb1f3`
- 本轮新增文件：`core/audit_scope_test.mbt`（唯一改动）
- 本轮**未修改任何产品代码**：`core/`、`ticks_input/`、`report/`、`cmd/` 的受版本控制
  文件 diff 为空（见 `docs/evidence/T2/gates.md` 的 `git diff --stat`）。

## 结论先行

**没有观察到 RED。** 先在 `core/audit_scope_test.mbt` 写入任务卡要求的全部精确断言，
再运行定向 `moon test --target native`，现有实现**一次通过**：core 包 22 tests
（原有 11 + 新增 11），失败 0。因此本轮不涉及任何最小修复，也没有可保留的最小反例。

任务卡明确允许这一结论：“若现有实现直接通过新增测试，如实记录‘既有实现通过新覆盖’，
不伪造 RED”。为证明这些断言不是空转，另做了一次变异抽查，见本文末节。

## 新增测试清单与逐条结果

全部为新文件 `core/audit_scope_test.mbt`，基准 grid 一律 `(0,60,15)`，
`detail_limit=1000`，输入数组按原始顺序传入。

原始逐条输出：`docs/evidence/T2/raw/core-verbose.txt`。

### 任务卡表格中的七个分类用例

| # | 行号 | 测试名 | 结果 |
|---|---:|---|---|
| 1 | 52 | `grid=(0,60,15) times=[0,15,15,45]: duplicate 15, k=2 missing` | ok |
| 2 | 72 | `grid=(0,60,15) times=[30,0,15,45]: one out-of-order row, coverage still complete` | ok |
| 3 | 93 | `grid=(0,60,15) times=[0,16,30,45]: 16 is off grid and k=1 goes missing` | ok |
| 4 | 113 | `grid=(0,60,15) times=[-15,0,15,30,45,60]: two out-of-range rows, coverage complete` | ok |
| 5 | 136 | `grid=(0,60,15) times=[15,30]: two separated gaps, longest run 1` | ok |
| 6 | 152 | `grid=(0,60,15) times=[0,45]: one interior gap of 2, longest run 2` | ok |
| 7 | 168 | `grid=(0,60,15) times=[60,60,0]: overlapping classes must not be summed` | ok |

关键断言取值（全部与任务卡与 `02_SPEC.md` 2.2 一致，未经实现反推）：

| times | missing | dup | ooo | off | oor | ranges | longest | passed |
|---|---:|---:|---:|---:|---:|---|---:|---|
| `[0,15,15,45]` | 1 | 1 | 0 | 0 | 0 | `[(2,3)]` | 1 | false |
| `[30,0,15,45]` | 0 | 0 | 1 | 0 | 0 | `[]` | 0 | false |
| `[0,16,30,45]` | 1 | 0 | 0 | 1 | 0 | `[(1,2)]` | 1 | false |
| `[-15,0,15,30,45,60]` | 0 | 0 | 0 | 0 | 2 | `[]` | 0 | false |
| `[15,30]` | 2 | 0 | 0 | 0 | 0 | `[(0,1),(3,4)]` | 1 | false |
| `[0,45]` | 2 | 0 | 0 | 0 | 0 | `[(1,3)]` | 2 | false |
| `[60,60,0]` | 3 | 1 | 1 | 0 | 2 | `[(1,4)]` | 3 | false |

`RecordRef.record_index`（1 基，物理记录号）逐条断言：

- 用例 1 重复详情 = record 3（第二个 15），timestamp 15。
- 用例 2 乱序详情 = record 2，timestamp 0。
- 用例 3 离网格详情 = record 2，timestamp 16。
- 用例 4 越界详情按**原始顺序** = record 1（-15）、record 6（60，右端点不纳入）。
- 用例 7 重复 = record 2；乱序 = record 3；越界 = record 1、record 2。

用例 2 额外断言“乱序但仍完整覆盖”时 `passed=false`：规格 2.2 规定“只要有一种问题，
审计结果为 fail，即使覆盖率为 100%”。

用例 7 额外断言重叠计数不可相加：`duplicate_extra_records + out_of_order_records +
out_of_range_records == 4`，而 `input_records == 3`。该断言在测试里写成
`assert_eq(<三项之和>, 4L)` 并紧邻 `input_records == 3`，使“不能加总成坏行总数”这一
契约成为可执行断言，而不是注释。

### 任务卡要求的四项 T2 证据

| # | 行号 | 测试名 | 结果 |
|---|---:|---|---|
| 8 | 206 | `grid=(-30,30,15) times=[-30,-15,0,15]: negative milliseconds are valid grid points` | ok |
| 9 | 227 | `grid=(0,10000,1) with every even index and detail_limit=1 truncates ranges only` | ok |
| 10 | 255 | `audit rejects detail_limit=0 and detail_limit=10001 at the library layer` | ok |
| 11 | 275 | `audit rejects 250001 parseable timestamps at the library layer` | ok |

证据 8（负毫秒）：`grid.start_ms == -30`，`expected=4`，`covered=4`，`missing=0`，
`missing_ranges=[]`，五类计数全 0，`passed=true`。负毫秒可以是有效网格点。

证据 9（细节截断）：grid `(0,10000,1)`，times 为 0..9998 全部偶数（5000 条），
`detail_limit=1`：

- `missing_points == 5000`（**完整计数不因截断改变**）
- `missing_ranges == [(1,2)]`（只保留第一段缺口）
- `longest_missing_run == 1`
- `truncated.missing_ranges == true`，其余四个 truncated 标志均为 false
- `passed == false`

构造依据：偶数索引 0,2,...,9998 全部命中，奇数索引两两之间各是一个单点缺口
（4999 段），右端点 9999 是第 5000 个缺失点（1 段），合计 5000 段、每段长 1。
按 `k` 升序折叠后第一段即 `[1,2)`，`detail_limit=1` 只留这一段。

证据 10（库层拒绝 detail_limit）：`@core.audit(times, grid, 0)` 与
`@core.audit(times, grid, 10001)` 均匹配 `Err(InvalidDetailLimit)`，且
`AuditError::code()` 均为 `CONFIG_INVALID`。测试直接调用 `@core.audit`，不经过 CLI
参数层，因此证明该拒绝由库层保证。

证据 11（库层拒绝记录上限）：构造 250001 个可解析 `Int64` 的 `Array`（
`assert_eq(times.length(), 250001)` 先行确认长度），直接传入 `@core.audit`，匹配
`Err(TooManyRecords)`，`code()` 为 `RESOURCE_LIMIT`。不依赖 ticks 适配层先拒绝。

## 关于“没有 RED”的可靠性：变异抽查

现有实现通过新增测试，本身不能排除“断言写弱了”。为校验断言敏感性，做了一次
**临时**变异抽查（仅改测试期望值，不改产品代码）：

| 变异 | 改动的断言 | 结果 |
|---|---|---|
| 1 | 用例 5 `longest_missing_run` 期望 1 → 2 | 失败：`1 != 2` |
| 2 | 用例 7 `duplicates[0].record_index` 期望 2 → 1 | 失败：`2 != 1` |
| 3 | 用例 9 `truncated.missing_ranges` 期望 true → false | 失败：`true` is not false |

变异后 `Total tests: 22, passed: 19, failed: 3.`，每个变异都精确命中对应测试。

**三处变异已在运行后立即还原**，最终树中不含任何变异标记（`grep -c "MUTATION PROBE"
core/audit_scope_test.mbt` 为 0），测试复跑为 22/22 通过。抽查证明三条断言读到的是
实现的实际值（分别为 1、2、true），而非恒真表达式或未取到的字段。

## 未做与限制

- 未重做 T1 已独立验证的昂贵输入（`N=10^12` 大缺口、Int64 两端、32 MiB+1、
  21 字节 token）。本轮未修改相关实现，且 `moon build` 报告无工作可做，
  产物 SHA 与 T1 已验收产物逐字节一致（见 `gates.md`），故按任务卡不重复制造。
- 只在 macOS arm64 native 验证；Linux、CI、完整 text 格式、发布均未授权、未运行。
