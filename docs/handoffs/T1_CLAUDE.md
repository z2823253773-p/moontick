# T1：Claude Code 实施交接

## 基线与权限

- 工作目录：`/Users/henryz/Desktop/比赛/moontick`
- 基线提交：`e366f11`。当前工作树含上一会话留下的**未提交** T1 草稿；开始前先读
  `AGENTS.md`、`.ai/TASK_STATE.md`、`docs/planning/02_SPEC.md` 第 1--6 节、
  `docs/planning/04_TASK_PLAN.md` 的 T1。
- 用户已授权 **仅 T1**。允许创建最小 MoonBit 项目、core、ticks 输入、CLI、报告、
  测试、T1 证据与一个真实实现提交；不要实现 T2--T8、完整 CSV、多序列、CI、发布、
  报名或任何对外动作。
- 已由隔离 `moon login` 和 CLI 临时模块探针确认 Mooncakes 用户名为
  `z2823253773-p`；模块名固定为 `z2823253773-p/moontick`。不要用裸 `moontick` 或
  `username/...` 占位符。先用 `rg -n 'moontick/' .` 核对并更新所有本地导入路径；随后
  重跑受影响检查。此确认不授予发布权限。
- 保留现有未提交 core/ticks 草稿及旧的阻塞证据，先审查其 diff 与测试状态。它们既不是
  可直接提交的成果，也不可因方便而删除；发现不符合规格时用最小反例记录后再修复。

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

启动 Claude Code 时，将该工具链目录列入该会话可访问目录并只授权上述 `moon` / `moonc`
检查所需的命令；不得读取、展示或复制 `$MOON_HOME/credentials.json`。若会话仍被路径权限
拦截，记录原始错误并交回 Codex，不要改用全局工具链或伪造验证。

## 已观察的起点（不是验收）

在模块名更新为 `z2823253773-p/moontick` 后，Codex 以该隔离工具链实测当前未提交草稿：

| 命令 | 结果 |
|---|---|
| `moon check --target native` | 退出 0；4 个 `implicit_impl_as_method` warnings |
| `moon test --target native` | 退出 255；子测试进程 SIGABRT |
| `moon build --target native` | 退出 0；同 4 个 warnings |

测试的最小复现已存在于 `ticks_input/parse_test.mbt:88--93`：输入
`9223372036854775807` 预期被接受，却得到 `INPUT_INVALID at line 1`。先保持该断言，
定位 `parse_canonical` 的 Int64 上界处理并最小修复；不要通过削弱测试、改为 Double 或
绕过真实测试二进制来“通过”。当前没有 `cmd/moontick`，CLI 的 JSON 与退出码尚未测试。

## T1 任务卡

先确认 `moon.mod` 的模块名是 `z2823253773-p/moontick`，`preferred_target = "native"`，
并核对/补齐所需 `moon.pkg`。
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
