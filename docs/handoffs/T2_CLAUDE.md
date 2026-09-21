# T2：Claude Code 实施任务卡（差量范围）

## 授权与基线

- 工作目录：`/Users/henryz/Desktop/比赛/moontick`，分支 `main`。
- 用户已授权 **仅 T2**：核心审计分类、缺失区间、细节截断与规模边界的补充行为/证据。
  不做 T3+、完整 CSV、多序列、Linux、CI、text 格式、发布、报名或其他对外动作。
- 已接受的产品实现 SHA 是
  `754ff0ea7eae10cc416f6207ce94277395ddb1f3`；后续纯文档提交
  `ddfc6b1` 仅保存 T1 独立验收记录，**不是被测产品版本**。开始前确认当前 HEAD、工作树
  和 `AGENTS.md`、`.ai/TASK_STATE.md`、`docs/planning/02_SPEC.md` 第 2/5/6 节、
  `docs/planning/04_TASK_PLAN.md` 的 T2。
- 只使用隔离工具链：

  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  export PATH="$MOON_HOME/bin:$PATH"
  moon version --all
  moonc -v
  ```

  不读取、显示或复制 `$MOON_HOME/credentials.json`；若权限阻断，记录原始错误交回，
  不改用全局 MoonBit。

## 已接受，不要重写或假装仍未验证

下列是 T1/macOS native 已独立确认的基线；本任务不重做其实现，只在**改动相关代码后**
回归运行：

| 已有能力/证据 | 已验证范围 |
|---|---|
| 基础审计 | 完整、空输入、缺一个点；半开区间与 JSON/真实退出码 |
| 五类问题计数 | 缺失、重复额外行、乱序、离网格、越界；独立小网格 oracle 519 例，seed `20260921` |
| 细节/位置 | 缺失范围、重复/乱序/离网格/越界详情、物理行号、截断标记均由 oracle 比对 |
| 大数/规模 | Int64 两端、`N=10^12` 大缺口、32 MiB+1、250001 记录、21 字节 token |
| 现有门槛 | `moon check/test/build`、真实二进制 CLI 16 例均已在 `754ff0e` 通过 |

证据：`docs/evidence/T1/codex-independent-review-754ff0e.md`。不要删除、移动或弱化
T1 测试；不要为“重做 T2”重构 `core/audit.mbt`、`ticks_input/`、`report/` 或 `cmd/`。

## T2 尚缺的行为与证据

只在 `core/audit_test.mbt`（可拆新 core 测试文件）新增以下**命名、精确**契约测试；
保持数组原始顺序并断言完整统计、`missing_ranges`、`longest_missing_run`、`passed`，以及
适用类别的 `RecordRef.record_index`。基准 grid 为 `(0,60,15)`：

| times | 必须新增的精确断言 |
|---|---|
| `[0,15,15,45]` | missing=1、duplicate=1、ranges=`[(2,3)]`，重复详情是 record 3 |
| `[30,0,15,45]` | out_of_order=1，详情为 record 2 / timestamp 0，仍完整覆盖 |
| `[0,16,30,45]` | off_grid=1，missing=1、ranges=`[(1,2)]`，离网格详情 record 2 |
| `[-15,0,15,30,45,60]` | out_of_range=2，详情原始顺序 record 1、6，仍完整覆盖 |
| `[15,30]` | missing=2、ranges=`[(0,1),(3,4)]`、longest=1 |
| `[0,45]` | missing=2、ranges=`[(1,3)]`、longest=2 |
| `[60,60,0]` | missing=3、duplicate=1、out_of_order=1、out_of_range=2、ranges=`[(1,4)]`；重叠计数不能相加成“坏行” |

另外只补下列 T2 证据：

1. `grid=(-30,30,15)`、times=`[-30,-15,0,15]` 为 pass，证明负毫秒可以是有效网格点。
2. `grid=(0,10000,1)`、所有偶数索引、`detail_limit=1`：missing=5000，
   `missing_ranges=[(1,2)]`、`truncated.missing_ranges=true`、完整计数不因截断改变。
3. `detail_limit=0` 与 `10001`：`@core.audit` 直接返回 `InvalidDetailLimit` /
   `CONFIG_INVALID`，不依赖 CLI 参数层。
4. 250001 个可解析 `Int64` 的 `Array` 直接传入 `@core.audit`：返回
   `TooManyRecords` / `RESOURCE_LIMIT`，不依赖 ticks 适配层先拒绝。

`N=10^12` 大缺口、Int64 两端、输入总字节/记录/token 上限已由 T1 独立真实 CLI 验证；
除非本轮修改相关实现，不重复制造这些昂贵输入。

## 实施顺序与证据

1. 先添加上述测试并运行定向 `moon test --target native`。若现有实现通过，记录真实结果；
   不伪造 RED。若失败，保存最小输入、期望、实际字段和退出码。
2. 仅在有失败时，最小化修改 `core/audit.mbt` 或相关 core 文件；不得改变 public schema、
   时间边界、五类定义、退出码或 T1 测试期望。
3. 运行完整门槛并记录明确 SHA：

   ```bash
   moon check --target native
   moon test --target native
   moon build --target native
   export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
   python3 tests/cli/test_cli.py
   ```

4. 把新增测试、实际命令/退出码与限制写入 `docs/evidence/T2/`；更新
   `.ai/TASK_STATE.md` 为 `REVIEW / Codex`，提交一个明确 T2 SHA。不得把文档基线
   `ddfc6b1` 当作产品被测 SHA。

## 交给 Codex 的最小材料

明确 T2 commit SHA、修改文件、每条新增精确测试的结果、完整 gate 输出位置、未测项。
Codex 将在该 SHA 的独立 worktree 用小网格 oracle、细节截断、巨大网格与真实二进制复核。
