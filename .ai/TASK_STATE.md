# MoonTick 当前状态

日期：2026-09-21。T1 与 T2 均已在明确实现 SHA 上完成本机技术验收；T3（严格 ticks 输入的
原始字节、库层限额与物理行号证据）已由 Claude Code 实施完毕，等待 Codex 在固定 SHA 上独立复核。

- task_id: T3
- status: REVIEW
- active_owner: Codex（在固定 T3 SHA 的独立 worktree 复核）
- implementation_authorized: YES（2026-09-21，用户要求按计划推进；范围仅 T3）
- objective: 补齐严格 ticks 输入的原始字节语法、库层限额与物理行号证据；Codex 在明确 SHA 上独立复核
- repo_root: /Users/henryz/Desktop/比赛/moontick
- branch: main
- tested_commit: T1 实现 `754ff0ea7eae10cc416f6207ce94277395ddb1f3` 已接受；
  T2 被测 SHA `a88af81bf7e9ff07698c63a293111532b022ba75` 已接受；
  T3 被测 SHA 见本文件所在提交本身（提交信息列出被测工件与新增测试文件）

## 当前任务：T3（实施完毕，等待 Codex 独立复核）

任务卡：`docs/handoffs/T3_CLAUDE.md`。T1 已实现解析和 CLI，T3 仅补尚缺的原始字节、
库层资源边界和位置证据；若新增测试发现真实不一致，再做最小修复。不重写已通过行为，
不开展 T4+。用户控制 Claude Code 启动时间，仅在北京时间闲时运行；Codex 不代为启动
或设置自动续跑。完成后 Claude 提供固定 T3 SHA，再由 Codex 独立复核。

### T3 实施结果（2026-09-21，Claude Code）

- 起点基线：`41faf7fceaa5394cf45d7bb59cb6eed52a6f497d`（T3 任务卡提交），工作树干净，
  与任务卡一致。未把该文档 SHA 当作新产品被测 SHA。
- 隔离工具链 `/private/tmp/moontick-moon-0.10.14-OS4LNz` 可用，`moonc v0.10.14+7d59c7ec9`
  现场复核；未使用全局 `~/.moon`，未读凭据。
- **没有 RED，产品实现零改动。** 新增 10 个 MoonBit 测试与 1 个进程级测试全部一次通过，
  按任务卡如实记录"新增覆盖通过，无产品实现变更"。**未修改任何产品代码**。
- `moon build` 报 `no work to do`；真实二进制 SHA-256
  `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975` 与 T1 已验收
  产物逐字节一致。
- 门槛：`moon check` 退出 0（14 warnings / 0 errors，与 T1/T2 同数、未新增 warning）、
  `moon test` 退出 0（62/62，T2 为 52）、ticks_input 包 22/22、`moon build` 退出 0、
  `python3 tests/cli/test_cli.py` 退出 0（17 passed，T2 为 16）。
- 变异抽查（只改测试期望、不改产品代码）：四处变异各自精确命中对应用例，随后全部还原，
  还原后门槛重新跑绿。
- 证据：`docs/evidence/T3/precise-input-evidence.md`、`docs/evidence/T3/gates.md`、
  原始输出 `docs/evidence/T3/raw/`。

参赛关键路径并行：官网当前展示 9 月 30 日截止本期报名与验收，但规划快照中的
9 月 24 日章程口径仍未复核；公开仓库、正式报名回执、CI、许可证、三场景、Mooncakes
发布及干净消费者安装目前均无完成证据。不得用本地 T1/T2 验收替代官方资格/验收。

## 历史验收：T2（本机技术验收通过）

任务卡：`docs/handoffs/T2_CLAUDE.md`。只补足该任务卡列出的 core 分类、细节截断、
资源拒绝和规模证据；不要重写已通过的 core/CLI/ticks/report，不做 T3+、Linux、CI、text
格式、发布或报名。若新测试发现真实不一致，先保留最小 RED，再最小化修复并记录证据；若
现有实现直接通过新增测试，如实记录“既有实现通过新覆盖”，不伪造 RED。

### T2 实施结果（2026-09-21，Claude Code）

- 起点基线：`e329b5a935dfc22cff616fbc5239bf857c6e654a`，工作树干净，与任务卡一致。
- 新增唯一文件：`core/audit_scope_test.mbt`（11 个测试）。**未修改任何产品代码**：
  `git diff --stat` 为空，`moon build` 报 `no work to do`，被测二进制 SHA-256
  `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975` 与 T1 已验收
  产物逐字节一致。
- **没有 RED。** 任务卡表格的七个分类用例与四项 T2 证据写入后，现有实现一次通过：
  core 包 22/22，全仓 52/52。按任务卡如实记录“既有实现通过新覆盖”，未伪造 RED，
  未做任何修复。
- 为排除“断言写弱”，做了一次临时变异抽查（仅改测试期望，不改产品代码）：三处变异
  各自精确命中对应测试（22 → 19 passed / 3 failed），随后全部还原，最终树无残留标记。
- 门槛：`moon check` 退出 0（14 warnings / 0 errors）、`moon test` 退出 0（52/52）、
  `moon build` 退出 0、`python3 tests/cli/test_cli.py` 退出 0（16 passed）。真实二进制
  三用例与 T1 一致（0 / 1 / 1，stderr 均 0 字节）。
- 证据：`docs/evidence/T2/precise-contract-tests.md`、`docs/evidence/T2/gates.md`、
  原始输出 `docs/evidence/T2/raw/`。

### Codex 独立复核（2026-09-21）

- 固定在 `a88af81bf7e9ff07698c63a293111532b022ba75` 的 detached worktree
  `/private/tmp/moontick-t2-verify`；相对 `754ff0e` 仅新增
  `core/audit_scope_test.mbt`，没有产品实现文件变更。
- 独立复跑 check 退出 0（14 warnings / 0 errors）、全仓 test 52/52、core verbose
  22/22、build 退出 0、真实二进制 CLI 16/16。
- 独立 Python 小网格/详情 oracle 未导入产品代码、未复用产品缺失范围算法；七个指定
  矩阵、256 个固定 seed `20260921` 小网格和一个截断案例共 264 例全部一致。
- 未发现需交回修复的最小反例。独立 worktree debug 产物 SHA-256 为
  `cf84224e18a66b9d2a6fad4e878008a4a0a70dfc2f2697be84fafdf302ff75dc`，与原 checkout
  构建产物不同，故未声称跨 worktree 逐字节二进制复现。
- `git diff --check a88af81^ a88af81` 退出 2，只因原始编译器输出的对齐尾随空格与
  `raw/cli-three-cases.txt` EOF 空行；它是非阻断文档卫生项，未改写原始证据。

完整记录：`docs/evidence/T2/codex-independent-review-a88af81.md`。Linux、CI、完整 text
格式、发布和报名仍 NOT_RUN；T3 已按用户指示进入准备阶段，其他后续任务另行启动。

### T2 正式验收决定（2026-09-21）

接受固定产品/测试提交 `a88af81bf7e9ff07698c63a293111532b022ba75` 的 T2 本机
技术范围：七个分类矩阵与四项补充契约已有精确 core 测试，独立 oracle 264 例一致，
且在该 SHA 的独立 worktree 再次运行 check（退出 0，14 warnings）、全仓 test
（52/52）、core test（22/22）、build（退出 0）及真实 CLI（16/16），均通过。
相对已接受的 T1 产品 SHA，只新增 core 测试，没有产品实现变更。

`git diff --check a88af81^ a88af81` 的原始输出尾随空格及 EOF 空行仍记录为非阻断
证据文件卫生项；跨 worktree debug 二进制不宣称逐字节一致。本次接受仅代表本机技术
验收，不代表 Linux、CI、发布、报名或官方赛事验收。T3 由用户手动启动 Claude Code。

## 本轮（2026-09-21，Claude Code）：实现与验证

模块名固定为 `z2823253773-p/moontick`。工具链为隔离
`/private/tmp/moontick-moon-0.10.14-OS4LNz`，`moonc v0.10.14+7d59c7ec9` 现场复核。
未使用全局 `~/.moon`，未读取凭据，未改动隔离工具链安装内容。

### 起点：保留 RED 断言，最小修复

上一会话草稿中 `ticks_input/parse_test.mbt:88` 的 Int64 端点断言先红（`moon test`
退出 255，SIGABRT）。该断言未被修改。根因经实测确定为：本版本 MoonBit 对两个等长
数字串的 `String` 比较不走字典序而是数值比较，导致
`"9223372036854775807" > "9223372036854775807"` 返回 `true`，任何 19 位值（含
`i64_max`）都被误判越界。修复为逐字节比较数字切片。详见
`docs/evidence/T1/int64-upper-bound.md`。

### 本轮新增

- `report/json.mbt`：`moontick.audit.v1` 与 `moontick.error.v1` 序列化；时间、统计
  与网格索引一律十进制字符串，`String` 字段经 JSON 转义。`try_render_json` 在位置
  数组长度与记录数不符时拒绝，由 CLI 映射为退出码 4，不伪装成数据问题。
- `cmd/moontick/args.mbt`、`main.mbt`：`check` 参数解析、文件读取、审计、输出与真实
  退出码（0/1/2/3/4）。参数解析失败只写 stderr、stdout 为空。`--format text` 在 T1
  未实现，明确返回退出码 2 并说明，不输出半成品报告。
- `report/json_test.mbt`、`cmd/moontick/args_test.mbt`、`tests/cli/test_cli.py`、
  `tests/fixtures/`：行为测试与进程级测试。
- `docs/evidence/T1/int64-upper-bound.md`、`docs/evidence/T1/gates.md`。

### 本轮审查发现并修复的草稿缺陷

- `ticks_input/read.mbt`：`max_input_bytes` 定义在 `parse.mbt` 中，`read.mbt` 从未
  导入；该标识符在 native 归零，使 `remaining <= 0` 恒为假，32 MiB 限额静默失效。
  改为让循环在读到上限后一字节时停止。
- `ticks_input/read.mbt`：`c_open` 的 flags 实参是未命名魔数 `0`。已核实 libc
  `O_RDONLY == 0`（见提交说明），提取为具名常量。
- `ticks_input/parse.mbt`：修复后 `slice_to_string` 成为死代码，已删除。

### 门槛结果（详见 `docs/evidence/T1/gates.md`）

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | 0 errors |
| `moon test --target native` | 0 | `Total tests: 41, passed: 41, failed: 0.` |
| `moon build --target native` | 0 | 0 errors |
| `python3 tests/cli/test_cli.py`（真实产物） | 0 | `Ran 16 tests ... OK` |

真实产物 `_build/native/debug/build/cmd/moontick/moontick.exe`
（sha256 `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975`）
三用例：完整 → 退出 0 / `status=pass`；零字节 → 退出 1 / `missing=4` /
`missing_ranges=[["0","4"]]`；缺一点 → 退出 1 / `missing=1` /
`missing_ranges=[["1","2"]]`。三者 stderr 均为 0 字节。

## 未决与未测（NOT_RUN）

- **`ticks_input/probe_wbtest.mbt`**：本轮为定位根因而建的临时 whitebox 探针，内容
  已清空，**不属于交付物**，应从提交中排除并在后续清理。
- Linux native 未运行：本轮只在 macOS arm64 验证。
- 资源限额（32 MiB / 250000 条 / 21 字节 token）代码路径已实现，但本轮未构造真实
  超限输入触发。
- `--format text` 未实现（T4 范围）。
- main 包的 blackbox 测试触发工具链提示「未来版本将停止生成」；当前版本仍正常
  运行，但 `cmd/moontick/args_test.mbt` 的位置后续需要调整。
- 完整供应链/跨平台 CI 仍未确认；core 官方校验 sidecar 未取得。
- 远程地址与发布授权仍待定；本轮未执行 `moon publish` 或任何对外动作。

## 下一步

1. Codex 在下方实现提交 SHA 上独立复核：复现三用例、核对 `docs/evidence/T1/`
   的原始输出，并按 `04_TASK_PLAN.md` 的 T1 通过条件检查计数与半开区间语义。
2. 复核通过后清理 `ticks_input/probe_wbtest.mbt`。
3. T2 再展开完整分类与规模边界，不在 T1 语义上做增量。

## 本轮交接

- 目录：`/Users/henryz/Desktop/比赛/moontick`；分支：`main`
- 验证命令：
  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  moon check --target native && moon test --target native && moon build --target native
  export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
  python3 tests/cli/test_cli.py
  ```
- 证据：`docs/evidence/T1/int64-upper-bound.md`、`docs/evidence/T1/gates.md`
- 实现提交 SHA：见本文件所在提交本身（提交信息列出被测工件）。

### T2 本轮交接（Claude Code → Codex）

- 起点基线：`e329b5a935dfc22cff616fbc5239bf857c6e654a`
- T2 提交 SHA：见本文件所在提交本身（提交信息列出被测工件与新增测试文件）。
  在 `754ff0e`（T1 产品实现）之上，本提交**只新增测试与证据**，未改产品代码。
- 改动文件：
  - 新增 `core/audit_scope_test.mbt`
  - 新增 `docs/evidence/T2/precise-contract-tests.md`、`docs/evidence/T2/gates.md`、
    `docs/evidence/T2/raw/{check,test,core-verbose,build,cli,cli-three-cases,toolchain}.txt`
  - 修改 `.ai/TASK_STATE.md`（状态 → REVIEW，owner → Codex）
- 验证命令（同一隔离工具链，逐字照抄任务卡）：
  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  export PATH="$MOON_HOME/bin:$PATH"
  moon check --target native && moon test --target native && moon build --target native
  export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
  python3 tests/cli/test_cli.py
  ```
- 证据：`docs/evidence/T2/`
- Codex 的最小复核面：`core/audit_scope_test.mbt` 的 11 个测试与
  `docs/evidence/T2/raw/core-verbose.txt` 的逐条输出；重点核对用例 7 的重叠计数语义、
  用例 9 的 `detail_limit=1` 截断、以及用例 10/11 是否确实不经 CLI/ticks 层。
- 未完成/未授权：Linux native、CI、完整 text 格式、发布、报名均未运行；T1 已独立
  验证的昂贵输入本轮按任务卡未重复制造。无待修复的最小反例。

## 独立复核（2026-09-21，Codex）

复核固定在实现提交 `754ff0ea7eae10cc416f6207ce94277395ddb1f3`，不以本地后续状态
代替该 SHA。验证在独立 detached worktree `/private/tmp/moontick-t1-verify` 进行，
实际 HEAD 与该 SHA 一致；没有在 Claude 的 checkout 编译、写 oracle 或修改产品代码。

- 精确隔离工具链复跑：`moon check --target native` 退出 0；`moon test --target native`
  退出 0（41 passed / 0 failed）；`moon build --target native` 退出 0。
- 对真实产物 `.../_build/native/debug/build/cmd/moontick/moontick.exe` 运行仓库进程级
  测试，`python3 tests/cli/test_cli.py` 退出 0（16 passed）。本次独立构建产物 SHA-256 为
  `1c36358005076a9616ebee8b7d4ca03ecc86641aa2e880f317ebaae03ac80131`。
- 独立 Python 小网格 oracle（不导入产品代码、不复用产品缺口算法）以 seed `20260921`
  枚举并比对 519 例：统计、所有详情位置、缺失半开区间、截断标记、JSON status 与真实退出码
  全部一致。
- 专项真实二进制验证通过：零字节全缺失；重复不补覆盖；Int64 最小/最大值；十亿级网格
  缺口；CRLF 后空白行的 `line=2`；CONFIG/IO/usage 的 stdout/stderr 与退出码；确定性。
  同时实测 21 字节 token、250001 条记录和 32 MiB+1 字节输入均为 `RESOURCE_LIMIT` /
  退出 2。
- 未发现需交回修复的反例。工具链仍给出非阻断 warnings（主包 blackbox 测试未来行为、
  未显式 import `env`、未使用 `escape_text` 与若干 derive 提示），未伪装为零警告。

按用户明确请求，已删除主 checkout 中未追踪的临时诊断文件
`ticks_input/probe_wbtest.mbt`；删除前核实其内容仅为“Temporary diagnostic probe”。
完整命令、范围与未测项见 `docs/evidence/T1/codex-independent-review-754ff0e.md`。

## T3 本轮交接（Claude Code → Codex）

- 起点基线：`41faf7fceaa5394cf45d7bb59cb6eed52a6f497d`
- T3 提交 SHA：见本文件所在提交本身（提交信息列出被测工件与新增测试文件）。
  相对 `a88af81`（T2）**只新增测试与证据**，未改产品代码。
- 改动文件：
  - 新增 `ticks_input/parse_scope_test.mbt`（10 个测试）
  - 修改 `tests/cli/test_cli.py`（新增 1 个真实二进制用例 + `check_raw_ticks` 辅助）
  - 新增 `docs/evidence/T3/precise-input-evidence.md`、`docs/evidence/T3/gates.md`、
    `docs/evidence/T3/raw/{check,test,ticks-input-verbose,build,cli,toolchain,binary-sha256}.txt`
  - 修改 `.ai/TASK_STATE.md`（状态 → REVIEW，owner → Codex）
- 验证命令（同一隔离工具链，逐字照抄任务卡）：
  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  export PATH="$MOON_HOME/bin:$PATH"
  moon check --target native && moon test --target native && moon build --target native
  export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
  python3 tests/cli/test_cli.py
  ```
- 证据：`docs/evidence/T3/`
- Codex 的最小复核面：
  1. `parse_scope_test.mbt:304` 的**决胜用例**——21 字节且含逗号仍报 `OverlongToken`，
     对比 20 字节同形报 `InvalidToken`；这两条共同证明"先查长度、再查格式"。
  2. `parse_scope_test.mbt:360` 的"恰好 32 MiB 不是 `TooManyBytes`"，钉死字节闸门为
     `>` 而非 `>=`。
  3. `parse_scope_test.mbt:340` 的 250001 条 / line 250001，钉死私有常量 `max_records`
     的边界（`max_records`/`max_input_bytes` 为包内私有，本轮**未**为测试改成 `pub`）。
  4. `parse_scope_test.mbt:183/236` 的原始字节用例是直接构造 `Bytes`、不经 `String`；
     建议 Codex 用独立字节级 oracle 复核，不要调用产品函数当真值。
  5. `test_cli.py` 新增用例用 `write_bytes` 落盘，复核 reader 路径的字节保真。
- 未完成/未授权：Linux native、CI、完整 text 格式、发布、报名均未运行；T1 已独立
  验证的 reader 入口字节上限与昂贵输入本轮按任务卡未重复制造。无待修复的最小反例。

## 接下来

1. Codex 在下方 T3 commit SHA 的独立 worktree 复核：跑同一隔离工具链的
   `moon check/test/build` 与真实二进制 CLI，读 `docs/evidence/T3/raw/` 的原始输出，
   并用**原始字节 oracle**（不导入产品代码）复核五类差量证据，重点见上节"最小复核面"。
   注意：启动复核前需用户手动授权；本会话不自行安排定时任务或后台续跑。
2. 复核通过后由用户决定 T4（CLI、报告、错误与确定性）是否展开。

T1、T2、T3 均只在 macOS native 范围内成立。Linux native、CI、发布、报名、完整 text
格式与 T4+ 范围仍未授权/未运行；等待用户决定下一任务，不自动展开。
