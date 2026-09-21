# T3：Claude Code 实施任务卡（严格 ticks 输入的差量证据）

## 基线与范围

- 仓库：`/Users/henryz/Desktop/比赛/moontick`，分支 `main`。启动前核对 HEAD、工作树，
  阅读 `AGENTS.md`、`CLAUDE.md`、`.ai/TASK_STATE.md`、
  `docs/planning/02_SPEC.md` 2.1/2.3/3.1/5/6 节及 `docs/planning/04_TASK_PLAN.md` 的 T3。
- T1 产品实现在 `754ff0ea7eae10cc416f6207ce94277395ddb1f3` 已接受；T2 测试与产品
  基线在 `a88af81bf7e9ff07698c63a293111532b022ba75` 已接受。启动基线为 T2 验收文档
  提交加本任务卡提交的当前 HEAD；不得把文档 SHA 当成新产品被测 SHA。
- 用户要求继续按计划推进，但 Claude Code 由用户**手动在北京时间闲时启动**。工作日
  09:00–12:00、14:00–18:00 不运行；周末可全天运行。接近高峰时保存状态并停止，
  不自行设置定时任务或后台续跑。法定节假日优惠须以当时的服务商规则核实。
- 本轮只补 `ticks_input` 的缺口证据与由真实失败引出的最小修复。不重写 T1 已通过的
  解析器、reader、core、JSON 或 CLI；不做完整 CSV、T4 text、Linux、CI、发布、报名。

## 已有证据，不重复当成新工作

`ticks_input/parse_test.mbt` 已覆盖空文件、LF/CRLF、末尾换行、1-based 行号、孤立 CR、
空行、规范整数、Int64 两端、20/21 字节 token 与第一坏行拒绝。T1 独立真实二进制
验收还覆盖了 CRLF 后坏行、21 字节 token、250001 行、32 MiB+1 字节和不存在文件的
退出码；见 `docs/evidence/T1/codex-independent-review-754ff0e.md`。本轮的重点是未被
明确证明的**原始字节语法与库层限额/定位**，不是再实现一次已有功能。

只使用隔离工具链；不要读取、输出或复制凭据：

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon version --all
moonc -v
```

若隔离路径不可用，记录原始错误交回，不静默切换到全局 `~/.moon`。

## 本轮要补的精确证据

优先在 `ticks_input/parse_scope_test.mbt` 新增命名测试，以 `Bytes` 构造原始字节；
需要时再补最小的真实 CLI 用例。按规格写期望，不从实现反推。

1. **物理行号与边界：** `0\n15\n` 与 `0\r\n15` 均得到 times `[0,15]`、
   `start_lines=[1,2]`；`\n`、`\r\n` 单独出现时分别是第 1 行空行错误；
   `0\n\n` 在第 2 行拒绝，不生成部分报告。所有成功结果的两个数组等长。
2. **原始字节拒绝：** UTF-8 BOM、至少一种非 ASCII UTF-8、一个非法 UTF-8 单字节、
   `timestamp_ms` 表头、引号、逗号、孤立 CR 分别报 `INPUT_INVALID`，保留精确行号。
   非法 UTF-8 不能先经 `String` 转换后测试；直接构造 `Bytes`。
3. **token 判定顺序：** 20 字节 `-9223372036854775808` 可解析；20 位正数越过
   Int64 上界报 `INPUT_INVALID`；21 字节即使含非法字符也先报 `RESOURCE_LIMIT`
   (`OverlongToken`)，定位到原始物理行。
4. **库层记录上限：** 直接调用 `parse_ticks`，恰好 250000 条短记录可接受，
   第 250001 条报 `TooManyRecords` / `RESOURCE_LIMIT`，`line=250001`，不返回前面
   250000 条的部分成功对象。单项测试可生成内存字节输入，不写入仓库大 fixture。
5. **库层字节上限：** 直接调用 `parse_ticks` 检验 32 MiB+1 字节报
   `TooManyBytes` / `RESOURCE_LIMIT`。T1 已在真实 CLI 验过读取上限，本轮只补
   parser 入口；控制内存和运行时间，不反复制造巨型样本。

若某项与当前实现或 MoonBit 测试框架不符，先保留最小 RED 输入、实际错误类别/行号、
期望和命令；只修复已证实的不一致。不得通过改期望、跳过测试或把非 ASCII 预处理掉来
使测试变绿。现有实现全部通过时，如实写“新增覆盖通过，无产品实现变更”。

## 验证、证据与交接

先跑 ticks_input 包的定向测试，再跑完整 native 门槛：

```bash
moon check --target native
moon test --target native
moon build --target native
export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

将精确用例、命令、退出码、工具链版本、warning、未测项写入 `docs/evidence/T3/`；
更新 `.ai/TASK_STATE.md` 为 `REVIEW / Codex`，提交一个明确的 T3 SHA。交接时报告
改动文件、每类边界结果、真实 CLI 结果与剩余风险。Codex 将在该固定 SHA 的独立
worktree 用原始字节 oracle 和真实二进制复核，不以主工作树的后续改动代替证据。
