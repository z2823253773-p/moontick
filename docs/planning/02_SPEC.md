# MoonTick 产品与技术规格

状态：规划契约 v1.1，2026-09-21。按 G0 修订为核心库 + ticks 行输入；没有产品实现，T1 尚未启动。本版替代原 v1 的 CSV 首版承诺。

## 1. 首版需求

输入一条有限序列的时间戳和固定采样计划；输出该计划下的覆盖情况和五类问题。输入仅被读取。核心审计逻辑全部用 MoonBit；Python 仅可出现在开发期独立验证工具中，不能成为产品运行依赖。

三层实现：`core` 负责规则，`ticks_input` 负责输入规范化及来源位置，`cli` 负责参数/文件/输出/退出码。`report` 负责纯文本与 JSON 序列化。核心不读取文件、不调用 shell、不联网、不读取时钟。

## 2. 固定采样契约

### 2.1 时间、窗口和预期网格

- 全部时间使用有符号 Int64 **整数毫秒**，可以是 Unix 毫秒，也可以是使用者声明的相对毫秒；一个检查内必须同一时间基准。
- 文本整数采用规范形式：`0` 或可选负号加非零首位数字；不接受 `+1`、`-0`、`01`、空白、浮点、小数、指数或超出 Int64 范围的值。
- 窗口采用 **左闭右开 `[start_ms, end_ms)`**。起点纳入、终点不纳入。
- `step_ms > 0`、`end_ms > start_ms`，并且 `(end_ms-start_ms)` 在 Int64 正数范围内，能被 `step_ms` 整除。非整周期窗口报配置错误，不自动舍入。
- `N=(end_ms-start_ms)/step_ms`，预期点为 `start_ms + k*step_ms`，`k=0..N-1`。
- 所有加减乘法先检查范围，不能依赖溢出后结果；尤其是在给观测值计算相对起点前先判断是否位于窗口内。
- 配置来自使用者，不从实际数据首尾推断。每个示例必须解释计划依据。

此前聊天中的五个时间点例子，在本规格下应声明 `[00:00,01:15)`、间隔 15 分钟；`01:00` 才属于预期点。端点含义以本文件为准。

### 2.2 分类与覆盖

设输入按原始顺序为 `t[0..m-1]`：

| 项目 | 精确定义 |
|---|---|
| 越界 | `t < start` 或 `t >= end` |
| 离网格 | 已位于窗口内，但 `(t-start) % step != 0` |
| 有效点 | 位于窗口内且精确落在网格上 |
| 覆盖点数 | 不同有效点的数量；同一点出现多次仍只算一次 |
| 缺失点数 | `N - 覆盖点数` |
| 重复额外行 | 对每个不同时间戳，出现次数减一；统计所有可解析时间戳，含越界/离网格记录 |
| 乱序行 | 从第二行开始，若当前时间戳小于紧邻前一条原始记录，则该行计一次；相等只属于重复 |

乱序检查必须在排序前完成。越界与离网格互斥；重复、乱序可以与它们重叠。因此五类数量不能相加当作“坏行总数”。

缺失区间用网格索引半开区间 `[k_start,k_end)` 表示。所有区间有序、不重叠且相邻区间合并；区间长度之和等于缺失点数。提供最长连续缺失点数。

精确覆盖率以 `covered_points / expected_points` 分子分母保存；文本展示百分比保留两位小数，但不能用四舍五入后的 100.00% 判断通过。可仅在展示层计算浮点百分比，分类/索引/计数仍全用整数，禁止先把 Int64 计数乘 100 导致溢出。

通过条件：五类问题计数全部为零。只要有一种问题，审计结果为 fail，即使覆盖率为 100%。

### 2.3 空输入和非法输入

- 零字节文件：有效空序列，报告整个窗口缺失，退出码 1。
- 空白行、表头、非法 token 或不支持的字节：输入错误，退出码 2。整份拒绝，不跳过坏行、不输出部分覆盖报告。
- 缺少计划/配置非法：退出码 2。文件不存在或读取失败：退出码 3。
- 程序内部错误：退出码 4，不能伪装为数据检查失败或成功。

## 3. ticks 与 CLI

### 3.1 输入格式

格式名 ticks，无表头，每行恰好一个规范 Int64 整数毫秒。文件扩展名不影响解析。这是行文本，不是 CSV。

- 只接受 ASCII 数字、负号和规定的换行字节；拒绝 BOM、非 ASCII、非法 UTF-8、引号、逗号、注释和任何隐式 trim。
- 行结束符允许 LF、CRLF；拒绝孤立 CR。允许末行没有换行或一个正常结束换行。`0\n` 为一条记录，`0\n\n` 第二行非法。
- 空文件合法；单独一个 LF 或 CRLF 是非法空行。不得使用默认丢弃空行的 split 行为。
- token 最多 20 字节，不含换行。超长立即报 RESOURCE_LIMIT；长度合规但违反规范整数或超出 Int64 的 token 报 INPUT_INVALID。先检查长度，再检查格式与范围。
- 1-based 记录号等于物理行号。核心只知道记录号，适配层提供行号；未来适配器不能默认二者永远相等。
- 读取时同时约束 token、总字节数和记录数，不能先无限 read-all 再检查；遇到第一个输入错误即失败。

上游若为多列 CSV/数据库结果，由调用方可靠地提取原始时间列或直接调用核心库。提取不能去重、排序、补点或默默四舍五入；单列转换不等于 MoonTick 提供 CSV 支持。

输入须有精确时间网格语义；原始设备时间抖动、自然月/交易日历与可变步长不在首版承诺内。

### 3.2 拟定命令契约

以下为将要实现的接口，不是当前已有命令：

```bash
moontick check sample.ticks --start-ms 0 --end-ms 75000 --step-ms 15000 --format json
moontick check sample.ticks --start-ms 0 --end-ms 75000 --step-ms 15000
moontick --help
moontick --version
```

`check` 必须提供输入路径及三个时间参数；`--format` 为 text（默认）或 json；`--detail-limit` 默认 1000，允许 1..10000。未知选项、重复选项、缺值、额外位置参数均报错。v0.1 不支持 stdin、glob、目录遍历或自动写回。

- stdout 只输出最终报告；json 模式必须是一份可解析 JSON，无日志前缀。
- 运行诊断写 stderr。参数已成功解析且选了 json 模式时，输入/配置/I/O 等错误的 stdout 输出单个错误 JSON；参数解析尚未成功的 usage 错误只写 stderr。错误 JSON 使用独立结构，不混入成功报告字段。
- help/version 退出 0，不读取输入文件。
- 不接受输入输出同路径，因为 v0.1 根本不提供文件覆写选项；重定向由调用者控制，文档不示范覆盖输入。

| 退出码 | 含义 |
|---|---|
| 0 | 审计通过，或 help/version |
| 1 | 审计完成，发现数据问题 |
| 2 | 参数、配置、字节/整数/行输入错误或资源限制 |
| 3 | I/O 失败 |
| 4 | 内部异常 |

测试必须执行实际编译产物捕获退出码；仅检查 `moon run` 包装器退出码不足以证明产品契约。

## 4. 报告接口

正常报告 schema 为 `moontick.audit.v1`。必须包含：

```json
{
  "schema": "moontick.audit.v1",
  "status": "fail",
  "unit": "ms",
  "grid": {"start_ms": "0", "end_ms": "75000", "step_ms": "15000"},
  "summary": {
    "input_records": "5", "expected_points": "5", "covered_points": "3",
    "missing_points": "2", "duplicate_extra_records": "1",
    "out_of_order_records": "0", "off_grid_records": "1", "out_of_range_records": "0",
    "longest_missing_run": "1"
  },
  "missing_ranges": [["2", "3"], ["4", "5"]],
  "duplicates": [{"timestamp_ms": "15000", "record_index": 3, "line": 3}],
  "out_of_order": [],
  "off_grid": [{"timestamp_ms": "62000", "record_index": 5, "line": 5}],
  "out_of_range": [],
  "details_truncated": {
    "missing_ranges": false, "duplicates": false, "out_of_order": false,
    "off_grid": false, "out_of_range": false
  }
}
```

对应输入为五行 `0,15000,15000,45000,62000`，此处逗号仅用于列举，实际文件每行一个值且无表头。所有 Int64 时间、索引区间端点和统计计数序列化为十进制字符串，避免 JavaScript JSON 数字精度丢失；数据记录/物理行号为在资源限制内安全的 JSON 整数。

缺失区间按 k 升序，其他问题按原始记录编号升序；duplicates 只列第二次及之后出现的记录。每类细节最多 detail_limit 条，超过时对应 truncated 为 true，完整计数不受影响。不能把截断报告说成只有这些问题。

错误结构：`{"schema":"moontick.error.v1","code":"INPUT_INVALID","message":"...","record_index":2,"line":2}`。没有记录位置时省略位置字段。code 集合：USAGE、CONFIG_INVALID、INPUT_INVALID、RESOURCE_LIMIT、IO_ERROR、INTERNAL。错误中不回显完整输入内容。

为可复现，不把执行时间、主机名、绝对路径写入规范报告；这些只记录在测试证据中。同一输入字节、配置与产品版本应产生逐字节一致的 JSON 输出。

## 5. 规模与算法

首版上限：输入字节 32 MiB（33,554,432）、数据记录 250,000、单个 token 20 字节（不含换行）、细节每类默认 1,000 条。超限明确报 RESOURCE_LIMIT，不静默截断输入。读取过程最多接收上限加一字节以判断超限，不能先无限 read-all 再检查；文件大小元数据不能作为唯一保护。上限是保护边界，不是已经实测的性能承诺。

算法建议：一次遍历原始记录计算乱序、分类、重复，并收集有效点；排序去重有效网格索引；从相邻索引间计算缺失区间，覆盖窗口首尾。时间目标 O(m log m)，内存 O(m)，缺失区间数量最多与有效点数同阶。**不分配长度 N 的数组，不逐点生成预期网格。**

窗口十亿点、观测十条必须仍可运行；N 很大但记录数量很小时不会因为 N 大而拒绝。小窗口独立 oracle 可以枚举 N，但产品实现不能照搬该方法。

## 6. 逻辑接口与目录

以下为语言无关的类型契约，G1 转成能由所选 MoonBit 版本编译的公开接口，再生成并提交 `.mbti`：

```text
Grid = {start_ms:Int64, end_ms:Int64, step_ms:Int64, expected_points:Int64}
make_grid(start_ms:Int64, end_ms:Int64, step_ms:Int64) -> Result<Grid, ConfigError>
audit(times:Array<Int64>, grid:Grid, detail_limit:Int) -> Result<AuditReport, AuditError>
parse_ticks(bytes:Bytes) -> Result<ParsedInput, InputError>
read_ticks(path:String) -> Result<ParsedInput, InputOrIOError>
ParsedInput = {times:Array<Int64>, start_lines:Array<Int>}
render_json(report:AuditReport, start_lines:Array<Int>) -> String
render_text(report:AuditReport, start_lines:Array<Int>) -> String
```

read_ticks 在读取中执行资源限制；parse_ticks 同样检查字节/记录/token 限额，供受控内存输入使用。以上为逻辑接口，错误类型由 G1 统一。

Grid 只能通过验证构造；调用者不能绕过检查。AuditReport 公开只读结果；invalid detail_limit/过多 records 在库层也必须拒绝。render 时位置数组长度不符属于内部错误，不能越界崩溃或给错行号。

预期产品目录（此规划包内尚不存在）：

```text
core/          types.mbt grid.mbt audit.mbt missing_ranges.mbt；对应 *_test.mbt
ticks_input/   parse.mbt read.mbt；对应 *_test.mbt
report/        json.mbt text.mbt；对应 *_test.mbt
cmd/moontick/  main.mbt args.mbt
tests/         fixtures/ golden/ oracle/ cli/ integration/
examples/      archive/ buckets/ synthetic/
docs/          planning/ evidence/ decisions/ release/
.github/workflows/ci.yml
.ai/TASK_STATE.md
AGENTS.md CLAUDE.md README.md LICENSE CHANGELOG.md
```

模块名称必须使用真实 Mooncakes 用户名，不猜测。v0.1 核心与 CLI 只承诺 native，经验证后再声明其他后端。Python 只用于 tests/oracle；不打包为产品依赖。

## 7. 季度增强契约

若试用证明多序列需求，v0.2 可增加显式批量计划文件，记录预期 series_id 和每个序列的窗口。数据按 series_id 隔离后调用同一 core；manifest 中有、数据里没有的序列生成全缺失报告。数据中出现未声明序列报输入错误，不自动猜配置。

若实施，批量报告使用 `moontick.batch.v1` 包裹各序列的 `moontick.audit.v1`，保持旧命令与旧报告可用。series_id 按 UTF-8 字节序排序，输入顺序用于各序列内部乱序检测。T7 开始前具体冻结 manifest/schema 和跨序列资源上限，不在 v0.1 偷加参数。

其他增强必须有实际需求和新增测试。时间容差会引入多记录争抢同一网格点的问题，不是“加个 tolerance 参数”即可；未经独立设计不纳入季度承诺。

## 8. 变更控制

影响窗口边界、计数、错误码、报告 schema 或性能上界的变化，先提交最小反例及 ADR，列出现有用户影响，再由你确认。单纯修复不符合本规格的实现不需要重复确认。

启动审查发现需求不合理可以提出修订，但不得为了让失败用例变绿而暗改期望值。
