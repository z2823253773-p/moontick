# T3：严格 ticks 输入的差量证据

任务卡：`docs/handoffs/T3_CLAUDE.md`。实现者：Claude Code。日期：2026-09-21（北京时间闲时）。

## 结论摘要

**本轮没有 RED，产品实现零改动。** 新增覆盖全部直接通过；因此按任务卡要求如实记录
"新增覆盖通过，无产品实现变更"，不伪造失败，也不做无依据的"修复"。

新增的 10 个 MoonBit 测试与 1 个进程级测试，覆盖的是任务卡指定的**原始字节语法**、
**库层限额**与**物理行号定位**，即 T1/T2 尚未明确证明的部分。T1 已通过的解析器、
reader、core、JSON 与 CLI 未被改写。

## 起点基线

- 仓库：`/Users/henryz/Desktop/比赛/moontick`，分支 `main`。
- 起点 HEAD：`41faf7fceaa5394cf45d7bb59cb6eed52a6f497d`（本 T3 任务卡提交）。
- 工作树启动时干净（`git status --porcelain` 为空）。
- 任务卡提醒：`41faf7f` 是**文档** SHA，不是新产品被测 SHA。T1 产品实现 SHA 为
  `754ff0ea7eae10cc416f6207ce94277395ddb1f3`，T2 测试 SHA 为
  `a88af81bf7e9ff07698c63a293111532b022ba75`。本轮未把文档 SHA 当作被测工件。

## 隔离工具链（未使用全局 `~/.moon`）

`docs/evidence/T3/raw/toolchain.txt`：

```text
moon 0.1.20260920 (914d7da 2026-09-20) /private/tmp/moontick-moon-0.10.14-OS4LNz/bin/moon
moonc v0.10.14+7d59c7ec9 (2026-09-18) /private/tmp/moontick-moon-0.10.14-OS4LNz/bin/moonc
moonrun 0.1.20260920 (914d7da 2026-09-20) /private/tmp/moontick-moon-0.10.14-OS4LNz/bin/moonrun
```

隔离路径可用，未触发任务卡的"记录原始错误交回"分支，未静默切换到全局 `~/.moon`。
全程未读取、输出或复制任何凭据。

## 改动文件

| 文件 | 类型 | 说明 |
|---|---|---|
| `ticks_input/parse_scope_test.mbt` | 新增 | 10 个测试，本轮证据主体 |
| `tests/cli/test_cli.py` | 修改 | 新增 1 个进程级真实二进制用例 |
| `docs/evidence/T3/` | 新增 | 本文件、门槛记录与原始输出 |

**产品实现文件（`ticks_input/parse.mbt`、`read.mbt`、`core/*`、`report/*`、
`cmd/moontick/*`）逐字节未改动**，见下节"产品未变的独立佐证"。

## 五类证据逐项

期望值均写自 `docs/planning/02_SPEC.md` 2.1/2.3/3.1/5 与任务卡表格，不是从
`ticks_input/parse.mbt` 反推。所有输入用 `Bytes` 直接构造（`t3_bytes` 包装
`Bytes::from_array`），非法 UTF-8 用例**不经 `String` 转换**——若先转 `String`，
字节会在到达 `parse_ticks` 之前就被改写或拒绝，测试测的就不再是适配器本身。

### 1. 物理行号与边界

`ticks_input/parse_scope_test.mbt:120`、`:132`、`:152`、`:167`

- `0\n15\n` → times `[0,15]`、`start_lines=[1,2]`；`0\r\n15`（末行无换行）→ 同上。
  两种终止符给出同样的时间与物理行号。
- 单独 `\n` 与单独 `\r\n` 均为**第 1 行空行**错误，`BlankLine` / `INPUT_INVALID` / line 1。
  二者都不是记录——丢弃空行正是 SPEC 3.1 明令禁止的默认 split 行为。
- `0\n\n` 在**第 2 行**拒绝；并额外断言该输入**不返回部分结果**（拒绝时不可能拿到
  含 1 条记录的 `ParsedInput`）。
- 成功路径强制两数组等长：辅助函数 `t3_expect_ok` 在长度不等时直接 abort，因此
  每个成功用例都在自动校验任务卡的"时间数组与行号数组等长"。

### 2. 原始字节拒绝

`ticks_input/parse_scope_test.mbt:183`、`:236`

全部报 `INPUT_INVALID` 并保留精确物理行号：

| 输入（原始字节） | 期望行 |
|---|---|
| UTF-8 BOM 前缀 `EF BB BF` | 1 |
| 双字节 UTF-8 `C3 A9`（é） | 1 |
| 三字节 UTF-8 `E4 B8 AD`（中） | 1 |
| 非法 UTF-8 首字节 `FF` | 1 |
| 非法续字节 `80` | 1 |
| 表头 `timestamp_ms` | 1 |
| 引号 `"15"` | 1 |
| 逗号 `0,15` | 1 |
| 孤立 CR 在第 1 行 `0\r1\n` | 1 |
| 孤立 CR 在第 2 行 `0\n1\r2\n` | 2 |
| BOM 在第 2 行 | **2** |
| 非 ASCII 在第 3 行 | **3** |
| 第 3 行空行 | **3**（`BlankLine`，仍为 `INPUT_INVALID`） |

末三项是定位证据的关键：报的行号是**物理行号**，不是"已接受记录数 + 1"。在这三例中
二者数值恰好相同，因此误差不会显形；下面的变异抽查用 21 字节用例把这一点钉死。

### 3. token 判定顺序（先长度、后格式与范围）

`ticks_input/parse_scope_test.mbt:264`、`:304`

- 20 字节 `-9223372036854775808` 可解析，得到 `i64_min`。
- 20 字节 `99999999999999999999`（全为合法数字、越过 Int64 上界）→
  `InvalidToken` / `INPUT_INVALID`：这是**内容**错误，不是长度错误。
- 21 字节 `100000000000000000000` → `OverlongToken` / `RESOURCE_LIMIT` / line 1。
- **决胜用例**：第 2 行放 20 个 `0` 加一个逗号（共 21 字节，且含任何 token 都不允许的
  字符）→ 仍报 `OverlongToken` / `RESOURCE_LIMIT` / **line 2**。长度先于内容判定，
  且定位到原始物理行。
- 同形但只有 20 字节（19 个 `0` 加逗号）→ `InvalidToken` / `INPUT_INVALID` / line 2。
  这一对用例正是使"先长度"规则**可观测**的原因：单看 21 字节用例无法区分两种顺序。

### 4. 库层记录上限

`ticks_input/parse_scope_test.mbt:340`

`"0\n"` 重复构造，不写入仓库大 fixture。

- 恰好 250000 条：接受；两数组长度均为 250000，最后一条 `start_lines[249999] == 250000`。
- 第 250001 条：`TooManyRecords` / `RESOURCE_LIMIT` / **line 250001**；拒绝时同样不返回
  前面 250000 条的部分成功对象。

**注**：`max_records` / `max_input_bytes` 为包内私有 `let`，包外测试不可见。
本轮**没有**为测试方便而把常量改成 `pub`（那会扩大产品公开面）。边界值本身即是断言：
"恰好 250000 可接受"把常量钉死在 SPEC 5 的取值上，常量若被改动，该用例立即失败。

### 5. 库层字节上限

`ticks_input/parse_scope_test.mbt:360`

直接调用 `parse_ticks`，补 T1 只覆盖过的 reader 入口之外的 parser 入口。

- 32 MiB + 1 字节（`Bytes::make(33554432 + 1, b'0')`）→ `TooManyBytes` /
  `RESOURCE_LIMIT` / line 0（整份输入的性质，不绑定单行）。
- 恰好 32 MiB → **不是** TooManyBytes：字节闸门放行，随后单行规则以 32 MiB 超长 token
  拒绝，得 `OverlongToken` / `RESOURCE_LIMIT` / line 1。若闸门写成 `>=` 而非 `>`，
  该用例会变成 `TooManyBytes`，因此它把闸门边界钉在"严格大于"。

两个超大样本各只构造一次，未反复制造巨型输入；运行时间见门槛记录（全程秒级）。

## 产品未变的独立佐证

| 证据 | 值 |
|---|---|
| `moon build --target native` | `Finished. moon: no work to do`（无任何产品重编译） |
| 真实二进制 SHA-256 | `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975` |
| 该 SHA 与 T1 已验收产物 | **逐字节一致**（T2 记录同值） |
| 危险改动检查 | 无新增 warning，`moon check` 仍为 **14 warnings / 0 errors**，与 T1/T2 基线同数 |

即：本轮唯一的产品侧可观察物（native 二进制）与已接受的 T1 产物完全相同。

## 变异抽查（仅改测试期望，不改产品代码）

全部通过可能是断言写弱导致的。为排除这一点，临时改动测试期望值，确认每个用例都能
精确命中，随后全部还原。

| 变异 | 期望被改成 | 结果 | 命中的测试 |
|---|---|---|---|
| A | 决胜用例 `line=2` → `1` | `21 bytes with a comma: expected line 1, got 2` | `parse_scope_test.mbt:304` |
| B | 250001 条 `line=250001` → `250000` | `250001 records: expected line 250000, got 250001` | `parse_scope_test.mbt:340` |
| C | 恰好 32 MiB `OverlongToken` → `TooManyBytes` | `32 MiB exactly: wrong error kind; expected RESOURCE_LIMIT at line 0` | `parse_scope_test.mbt:360` |
| D | 进程级 BOM 第 2 行 `line=2` → `1` | `AssertionError: 2 != 1`（subTest `case='BOM on line 2'`） | `test_cli.py:198` |

四例各自只命中对应用例，无一误伤。变异已全部还原：还原后 `moon test` 62/62、
`test_cli.py` 17/17 全绿，且 `git diff --stat` 对产品目录为 0 变更。

注意变异 A/C 的关系：A 证明"定位到原始物理行"这一断言不是恒真，C 证明字节闸门的
`>` 边界断言不是恒真。

## 与任务卡表格的对照

任务卡表格逐项：

| 任务卡条目 | 覆盖位置 |
|---|---|
| 空字节 → `[]` | `parse_test.mbt:32`（T1） |
| `0\n15\n` → `[0,15]` 行号 `[1,2]` | `parse_scope_test.mbt:120` |
| `0\r\n15` → `[0,15]` 行号 `[1,2]` | `parse_scope_test.mbt:120` |
| `0\n\n` → `INPUT_INVALID` line=2 | `parse_scope_test.mbt:152` |
| 单独 LF / `timestamp_ms` / BOM / 引号 / 逗号 / 孤立 CR / 非 ASCII | `parse_scope_test.mbt:183`、`:132` |
| 空格 / `01` / `+1` / `-0` / `1e3` / `9223372036854775808` | `parse_test.mbt:79`、`:98`（T1） |
| `-9223372036854775808` / `9223372036854775807` 可解析 | `parse_scope_test.mbt:264`、`parse_test.mbt:88`（T1） |
| 21 字节 token / 超 250000 条 / 超 32MiB → `RESOURCE_LIMIT` | `parse_scope_test.mbt:304`、`:340`、`:360` |
| 时间数组与行号数组等长 | `parse_scope_test.mbt:167` 及 `t3_expect_ok` 全局约束 |
| 整份拒绝，不发部分成功报告 | `parse_scope_test.mbt:152`、`:340` |

## 未被本轮覆盖（NOT_RUN）

- **Linux native**：本轮仍只在 macOS arm64（Darwin 25.4.0）验证。
- **CI**：未配置、未运行。
- **`--format text`**：T4 范围，未实现。
- **发布 / 报名 / 公开仓库**：未执行任何对外动作，无授权。
- **reader 入口的字节上限**：T1 已在真实 CLI 上测过（32 MiB+1 → `RESOURCE_LIMIT` /
  退出 2），按任务卡本轮不重复制造巨型 fixture，只补 parser 入口。
- **非 macOS 的物理行号等价性**：孤立 CR 与 CRLF 的读入行为未在其他平台核对。
