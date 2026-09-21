# T4 复核修复：百分比显示与缺失区间截断提示

任务来源：`docs/evidence/T4/codex-independent-review-6d97745.md`（P1、P2）。
实现者：Claude Code。日期：2026-09-21（北京时间闲时）。
仓库 `/Users/henryz/Desktop/比赛/moontick`，分支 `main`。

## 结论摘要

只修了复核记录中的两个文本输出反例，**未改核心计数、未改 JSON 契约、未改
`core/` 与 `ticks_input/`**。两处都由"先写反例测试 → 真实 RED → 最小修复"完成，
并做了变异抽查证明新断言确实绑定。

| 反例 | 根因 | 修复 |
|---|---|---|
| P1 百分比显示错误 | `Double` 比例缩放在 `trunc` 前已略小于精确整数值 | `percent()` 改为纯整数运算，余数部分四舍五入 |
| P2 截断提示混淆量纲 | 提示把**缺失点数**当成**区间总数**写进 "first N of M" | 改为分列两个量：已列区间数与缺失点总数 |

## 起点核对

- 起点 HEAD `23d25dd`（Codex 复核记录提交），工作树干净，分支 `main`。
- 上一被测产品 SHA 仍为 `6d9774519c2c9cb20376af7d79a32c0fea63732e`。
- 两例在 HEAD 上**逐字复现**，与复核记录一致：

```text
$ moontick check p1a.ticks --start-ms 0 --end-ms 3 --step-ms 1     # 0,1
coverage: 2/3 (66.66%)      <- 期望 66.67%

$ moontick check p1b.ticks --start-ms 0 --end-ms 100 --step-ms 1   # 0..56
coverage: 57/100 (56.99%)   <- 期望 57.00%

$ moontick check p2.ticks --start-ms 0 --end-ms 100 --step-ms 1 --detail-limit 1  # 0,50
missing_ranges:
  (showing first 1 of 98; truncated)   <- 98 是缺失点数，不是区间数（区间只有 2 个）
```

## 一、P1 百分比

### 根因

`(covered.to_double() / expected.to_double()) * 10000.0` 得到的 `Double` 可能略小于
精确整数，再 `@double.trunc` 就少一分。`57/100` 是精确的 57%，本不涉及任何舍入
决策，却因二进制浮点误差显示成 `56.99%`。

### 修复

`report/text.mbt` 的 `percent()` 改为**全整数**运算：

```moonbit
let whole = covered / expected
let remainder = covered % expected
let scaled = remainder * 10000L          // remainder < 250000，不会溢出
let hundredths = scaled / expected
let leftover = scaled % expected
let rounded = if leftover >= expected - leftover { hundredths + 1L } else { hundredths }
let total = whole * 10000L + rounded     // 百分数的百分之一为单位的整数
let units = total / 100L
let fraction = total % 100L
```

三点值得复核：

1. **溢出安全**：`expected_points` 本身无上界（1ms 步长配大窗口可极大），但
   `covered_points <= 输入记录数 <= 250000`（资源上限），故 `remainder < 250000`、
   `whole * 10000 < 2.5e9`，两处乘法都远不触及 Int64 上限。**先拆分再缩放**正是
   SPEC 2.2 要求的形式——绝不在除法前放大计数器。
2. **四舍五入口径**：按 SPEC 2.2 的两位小数展示取**四舍五入**（非截断）。
   `1/3` 仍为 `33.33%`，`2/3` 由 `66.66%` 修正为 `66.67%`。
3. **不反向决定通过/失败**：`report.passed` 仍是 core 的精确布尔值。SPEC 2.2
   点名的场景（四舍五入后为 100.00% 但仍有缺失点）已加真实进程用例：19999/20000
   显示 `100.00%`、`missing: 1`、`FAIL`、退出 1。

## 二、P2 缺失区间截断提示

### 根因

原提示 `(showing first 1 of 98; truncated)` 中的 `98` 取自 `missing_points`，即
**缺失点数**；而前面的 `1` 是**区间数**。两者量纲不同，读者会以为共有 98 个缺失区间。

### 修复

`AuditReport` **未**扩展（复核记录明确要求不必为文案扩展公共 schema）。改为把两个
量分开陈述，且不虚构区间总数：

```text
missing_ranges (truncated):
  ranges shown: 1; missing points in total: 98
  [1,50)
```

复核记录给的方向是"可改为明确的『显示前 1 个缺失区间；总共缺失 98 个点；详情已截断』
之类措辞"。采用的措辞满足其约束（两个计数分列、不混用），但**未逐字照抄**该示例
措辞。若 Codex 要求与示例逐字一致，这是一处需要回退的点。

同时把标题本身也标为 `(truncated)`，从标题即可看出列表被截断，不必读到提示行才发现。
未截断时标题仍为 `missing_ranges:`，空类别仍为 `  none`。

**记录类别不受影响**：`duplicates` 等四类的 "first N of M" 中两个数都是**记录数**，
量纲相同，措辞保持原样。

## 三、版本

`--version` 未改动，仍为 `moontick 0.1.0`。

## 四、副产物：移除 `moonbitlang/core/double` 依赖

改用整数运算后 `report/moon.pkg` 不再需要 `moonbitlang/core/double`，已移除。
`report/json.mbt` 未改动，JSON 契约与字段顺序完全不变。

## 改动文件

| 文件 | 类型 | 说明 |
|---|---|---|
| `report/text.mbt` | 修改 | `percent()` 改整数四舍五入；缺失区间截断提示分列两个量 |
| `report/moon.pkg` | 修改 | 移除已不需要的 `moonbitlang/core/double` |
| `report/text_test.mbt` | 修改 | 纠正 66.66% 期望；新增 4 个进程内用例 |
| `tests/cli/test_cli.py` | 修改 | 新增 `TextAccuracyRegressions`（5 个真实进程用例） |
| `tests/golden/text-truncated-missing.txt` | 新增 | 首份**触发详情截断**的文本 golden |
| `docs/evidence/T4-fix/` | 新增 | 本文件与原始输出 |

**未改动** `core/*`、`ticks_input/*`、`report/json.mbt`、`cmd/moontick/main.mbt`。

## 先 RED 后修复

| 阶段 | 命令 | 退出码 | 结果 | 原始输出 |
|---|---|---:|---|---|
| RED（实现前） | `python3 tests/cli/test_cli.py` | 1 | 41 tests，**4 failures** | `raw/red-cli-before-fix.txt` |
| RED（实现前） | `moon test --target native` | 2 | 76 tests，**3 failed** | 本轮首次运行，输出见下 |
| GREEN | 同上两条 | 0 | 77/77、42/42 | `raw/test.txt`、`raw/cli.txt` |

RED 的 4 个进程级失败全部落在新增的 `TextAccuracyRegressions`：
`test_two_of_three_rounds_up_to_the_nearest_hundredth`、
`test_a_whole_percentage_is_not_shaved_by_binary_rounding`、
`test_missing_range_notice_does_not_pass_off_points_as_ranges`、
`test_golden_truncated_missing_ranges`。

RED 的 3 个进程内失败为 `report/text_test.mbt` 的 66/85/136 行对应断言。

> 说明：进程内 RED 的完整 stdout 未单独留存文件（当时直接读屏），此处以失败计数与
> 行号记录，不冒充已有原始文件。

## 变异抽查（新断言是否真的绑定）

在冻结前对三条关键路径各做一次变异，**每条都先 `touch` 源文件强制重编译**，
随后全部还原并重新构建。

| 变异 | 改动 | 进程内 | 进程级失败用例 |
|---|---|---|---|
| M5 | 四舍五入 `>=` 改为 `>` | 1 failed | `rounded_up_hundred_percent_still_fails` |
| M6 | `+ rounded` 改为 `+ hundredths`（退化为截断） | 2 failed | `rounded_up_hundred_percent_still_fails`、`two_of_three_rounds_up_to_the_nearest_hundredth` |
| M7 | 截断提示改回旧措辞 | 2 failed | `golden_truncated_missing_ranges`、`missing_range_notice_does_not_pass_off_points_as_ranges` |

> **过程记录（供复核参考）**：首次跑变异矩阵时未 `touch` 源文件，构建系统报
> `no work to do`，导致 3 个 CLI 用例对着**上一次变异的残留产物**运行，把过期失败
> 误读为当前变异的结果。发现后改为每次 `touch` 并重跑，上表为修正后的结果。
> 这也解释了为何 M5 起初看起来"只被进程内捕获"。

三条变异现在**同时**被进程内与进程级用例捕获，其中 M7 由新增的截断 golden 捕获——
这正是 T4 记录里"三份 golden 均不触发截断"这一覆盖缺口的补位。

## 五、JSON 契约未变的实测核对

不满足于"没改 `json.mbt`"，而是**用旧源码构建一次、新源码构建一次，对同一命令
同一输入做逐字节比对**：

```bash
git stash push -- report/text.mbt report/moon.pkg report/text_test.mbt tests/cli/test_cli.py
touch report/text.mbt && moon build --target native     # 产物 = HEAD 23d25dd 行为
# 三个输入：0,15,15,45 / 空文件 / 0,50 + --detail-limit 1，均加 --format json
git stash pop && touch report/text.mbt && moon build --target native
```

结果：`diff` **无差异**，修复前后 JSON 逐字节相同。原始输出见
`raw/json-before-vs-after.txt`。特别是 `0,50` 这例的
`"details_truncated":{"missing_ranges":true,...}` 前后一致——P2 只动文本措辞，
未动 JSON 的截断标记或任何计数。

## 门槛（`raw/`）

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon check --target native
moon test --target native
moon test --target native -p z2823253773-p/moontick/report -v
moon build --target native
export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | `14 warnings, 0 errors`（与 T1–T4 同数，无新增） |
| `moon test --target native` | 0 | `Total tests: 77, passed: 77, failed: 0.` |
| `moon test -p .../report -v` | 0 | `23 passed / 0 failed` |
| `moon build --target native` | 0 | 0 errors |
| `python3 tests/cli/test_cli.py` | 0 | `Ran 42 tests ... OK` |

测试数变化：全仓 73 → 77（+4 进程内）；report 包 19 → 23；真实 CLI 37 → 42（+5）。
新增测试**只覆盖这两处修复**，未顺带扩面。

工具链现场复核：`moon 0.1.20260920 (914d7da 2026-09-20)`、
`moonc v0.10.14+7d59c7ec9 (2026-09-18)`，均解析到隔离路径
`/private/tmp/moontick-moon-0.10.14-OS4LNz/bin/`。未使用全局 `~/.moon`，未读凭据。
见 `raw/toolchain.txt`。

## 产品二进制

- SHA-256：`d3f53710a11d0249524a24ff32cb89554bddb9bb7d0e44c8fc1f162ee7579a8a`
  （`raw/binary-sha256.txt`）。
- 与 T4 的 `a1f590dd…` 不同：本轮确有产品实现变更。与 T1–T3 的 `b9e3e189…` 亦不同。
- 修复前产物已被本轮构建覆盖（`_build` 不入库），修复前行为由复核记录与本节
  复现输出共同记录，未声称在新会话中重新执行过旧产物。

## 未测项（NOT_RUN）

- Linux native、CI、发布、报名、公开仓库、许可：均未运行/未授权。
- 除百分比与缺失区间提示之外，文本报告的其它版式：本轮未改、未重测。
- 终端宽度/列对齐：未测。

## 待复核

请 Codex 在 `23d25dd` 之后的新固定 SHA 上独立复核：

1. **P1**：`2/3` 是否显示 `66.67%`、`57/100` 是否显示 `57.00%`；并提供**独立于
   产品代码**的百分比 oracle 交叉验证（不要调用 `percent()` 当真值）。
2. **P1 通过性**：19999/20000 是否显示 `100.00%` 且仍 `FAIL` / 退出 1。
3. **P2**：`ranges shown: 1; missing points in total: 98` 两个计数是否量纲正确；
   并确认 `duplicates` 等记录类别的 "first N of M" 未被误改。
4. **措辞**：采用的措辞与复核记录所给示例措辞不同（语义等价、约束满足）。
   如要求逐字一致，请明确指出。
5. **JSON 契约**：`--format json` 输出应与 T4 **逐字节相同**，请重点核对未受影响。
