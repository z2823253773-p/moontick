# T1：Claude Code 实施交接

## 基线与权限

- 工作目录：`/Users/henryz/Desktop/比赛/moontick`
- 基线提交：`e366f11`。开始前确认工作树干净，并先读 `AGENTS.md`、
  `.ai/TASK_STATE.md`、`docs/planning/02_SPEC.md` 第 1--6 节、
  `docs/planning/04_TASK_PLAN.md` 的 T1。
- 用户已授权 **仅 T1**。允许创建最小 MoonBit 项目、core、ticks 输入、CLI、报告、
  测试、T1 证据与一个真实实现提交；不要实现 T2--T8、完整 CSV、多序列、CI、发布、
  报名或任何对外动作。
- 本地模块名暂定为裸 `moontick`，已在指定工具链通过 native 最小工程探测。这不是
  Mooncakes 发布命名空间；不得使用 `username/...`，不得猜测用户账户。真实命名空间
  确定后统一替换导入路径并重新运行所有受影响检查。

## 隔离工具链

仅使用以下临时目录，不改动全局 `~/.moon`：

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon version --all
moonc -v
```

预期 `moonc v0.10.14+7d59c7ec9 (2026-09-18)`。二进制 archive 已按官方 SHA-256
sidecar 校验；core 仅有观察 hash，官方 core sidecar 未取得。相关限制见
`docs/evidence/T0/toolchain.md`。

## T1 任务卡

先建立 `moon.mod`、`moon.pkg`，`preferred_target = "native"`，模块名为 `moontick`。
将文件限制在：

```text
core/types.mbt       core/grid.mbt       core/audit.mbt
core/*_test.mbt      ticks_input/*       report/json.mbt
cmd/moontick/*       tests/fixtures/     tests/golden/
README.mbt.md / README.md（若工具链模板需要）
docs/evidence/T1/
```

先写三个可运行的行为测试并保存 RED 证据，然后最小实现使其变绿：

```text
grid=(0,60,15), times=[0,15,30,45] -> expected=4, covered=4, missing=0, pass
grid=(0,60,15), times=[]           -> expected=4, covered=0, missing=4, [[0,4]], fail
grid=(0,60,15), times=[0,30,45]    -> expected=4, covered=3, missing=1, [[1,2]], fail
```

T1 必须同时拒绝 `step=0`、负 step、`end<=start`、非整周期窗口和窗口差溢出，错误为
`CONFIG_INVALID`；不得将 Int64 转为 Double。ticks CLI 可先支持该最小闭环的无表头
文件，但零字节文件必须产生全缺失 JSON 与实际退出码 1。完整严格 ticks 边界属于 T3。

## 交付门槛

在明确 commit 前运行并记录退出码：

```bash
moon check --target native
moon test --target native
moon build --target native
```

再对实际编译产物运行完整、空、缺一点三个 `.ticks` 文件，记录 stdout JSON、stderr 和
退出码；不可只报告 `moon run` 的包装器结果。更新 `.ai/TASK_STATE.md` 为 `REVIEW`、
`active_owner: Codex`，注明 SHA、修改文件、命令、未测项和下一步。不要把未运行项写成
通过；完成后将明确 SHA 交给 Codex 独立复核。
