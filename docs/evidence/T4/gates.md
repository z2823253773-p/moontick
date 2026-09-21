# T4 门槛记录

日期：2026-09-21（北京时间闲时）。实现者：Claude Code。
仓库 `/Users/henryz/Desktop/比赛/moontick`，分支 `main`。
起点 HEAD `100830aad1c95e2999cb62f9c3c22b0d8e1150df`（工作树启动时干净）。
原始输出：`docs/evidence/T4/raw/`。

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon check --target native
moon test --target native
moon build --target native
export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

工具链：`moon 0.1.20260920 (914d7da 2026-09-20)`、`moonc v0.10.14+7d59c7ec9 (2026-09-18)`，
均解析到隔离路径。

## 先 RED，后实现

| 阶段 | 命令 | 退出码 | 结果 | 原始输出 |
|---|---|---:|---|---|
| RED（实现前） | `python3 tests/cli/test_cli.py` | 1 | 37 tests，**11 failures + 2 errors** | `raw/red-1-before-fix.txt` |
| GREEN（实现后） | 同上 | 0 | 37 tests，OK | `raw/cli.txt` |

RED 的 11 个 failure 覆盖：默认格式、必需字段、无环境泄漏、problem 文件退出 1、
三份 golden、三个文本错误通道。2 个 error 是 JSON 位置/错误文档用例（当时
`record_index` 不存在导致 KeyError）。

**无伪造 RED**：`DetailTruncation` 的 5 个用例与
`test_explicit_text_is_byte_identical_to_the_default` 在 RED 阶段就是 `ok`——前者只依赖
已冻结的 JSON 契约，后者在两个分支都报错时"同样失败"因而等价。这两组已按任务卡
要求如实记录为"既有行为直接通过"，未改动期望值制造失败。

## 最终门槛

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | `14 warnings, 0 errors` |
| `moon test --target native` | 0 | `Total tests: 73, passed: 73, failed: 0.` |
| `moon test --target native -p .../report -v` | 0 | `19 passed / 0 failed` |
| `moon build --target native` | 0 | 0 errors |
| `python3 tests/cli/test_cli.py` | 0 | `Ran 37 tests ... OK` |

测试数变化：全仓 62 → 73（+11 进程内）；report 包 8 → 19；真实 CLI 17 → 37（+20，
其中 1 个为 T3 遗留计数核对，新增 21 个，1 个原用例改名归入新基类）。

## Warning 状态

`moon check` 为 **14 warnings / 0 errors**，与 T1–T3 记录数量一致，本轮**未新增
warning**。新增的 `report/text.mbt` 无警告（曾出现的 `unused_value` 已在本轮内清理，
未带入最终树）。既有 warning 均为非阻断工具链提示，未伪装为零警告，也未为消除它们
改动已冻结代码。

## 产品二进制

- SHA-256：`a1f590ddda144ab26328e152f89885a0c560ca608a491aa8a79b96697a030497`
  （`raw/binary-sha256.txt`）。
- 与 T1–T3 的 `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975`
  **不同**：本轮确有产品实现变更（新增 text 渲染与错误通道），符合预期。
- `moon build` 最后一次运行报 `no work to do`，即最终门槛所测产物与提交树一致。

## 行为差异实测（旧 8092ac6 → 新）

```text
$ moontick check bad.ticks --start-ms 0 --end-ms 60 --step-ms 15
EXIT=2  STDOUT=[]  STDERR=[moontick: INPUT_INVALID: blank lines are not records]

$ moontick check bad.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
{"schema":"moontick.error.v1","code":"INPUT_INVALID","message":"blank lines are not records","record_index":2,"line":2}
EXIT=2

$ moontick --version
moontick 0.1.0
```

旧行为见 `report-and-cli.md` 的对照表；旧二进制未单独重建（worktree 创建被拒绝），
旧行为由 `raw/red-1-before-fix.txt` 的失败断言与 `8092ac6` 源码共同记录，未声称
在新会话中重新执行过旧产物。

## 变异抽查

四处变异（M1 错误通道、M2 截断提示、M3 百分比、M4 `record_index`）各自精确命中
对应用例，随后全部还原；还原后 `moon check` 14 warnings、全仓 73/73、CLI 37/37 重新
跑绿。详见 `report-and-cli.md`。

## 未测项（NOT_RUN）

- Linux native、CI、发布、报名、公开仓库、许可证：均未运行/未授权。
- 文本格式的详情截断 golden：三份 golden 均不触发截断，该路径仅由进程内测试覆盖。
- 终端宽度/列对齐行为：未测。
