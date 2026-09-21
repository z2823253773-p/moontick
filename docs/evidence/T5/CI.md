# T5：固定工具链 CI 候选（macOS 本地实测 + 跨平台未运行记录）

日期：2026-09-22。任务：T5。状态图例：**PASS / FAIL / NOT_RUN / BLOCKED**。

本文件记录本轮实际执行过的命令与结果。**没有远程仓库，GitHub Actions 从未运行**，
因此跨平台 CI 一律为 **NOT_RUN**；本机的 macOS 结果不得读作 Linux 或 GitHub Actions 通过。

## 1. 起点与提交

| 项目 | 值 |
|---|---|
| 起点 HEAD | `3813d56`（干净工作树，`main`） |
| 格式整理 | `d253b31` style: apply moon fmt across the module |
| 接口文件 | `8dd8388` chore: refresh the report package interface file |
| CI 工作流 | `89b4e01` ci: add fixed-toolchain macOS arm64 and Linux x86_64 candidate |
| 本轮被测产品 SHA | `89b4e01fcece1ba8264e6109254571253c45b063` |
| 本文件所在提交 | `56844aa` docs(t5): record the CI candidate…（仅文档） |

按仓库既有约定，本节之后新增的**文档提交不改变产品被测 SHA**。Codex 复核
**产品与被测 SHA `89b4e01`**；`56844aa` 只追加本证据与 `.ai/TASK_STATE.md`。

产品语义、schema、计数、退出码和 oracle 期望均未改动；本轮只做格式整理、重新生成
被 T4 遗漏的公开接口文件和新增 CI。

## 2. 工具链（隔离，未触碰全局 `~/.moon`）

- `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`
- `moon 0.1.20260920 (914d7da 2026-09-20)`；`moonc v0.10.14+7d59c7ec9 (2026-09-18)`；
  `moonrun 0.1.20260920 (914d7da 2026-09-20)`。原始输出：`raw/toolchain.txt`。
- 平台：`Darwin 25.4.0 arm64`。

## 3. 归档哈希核对（本轮现场重算）

`raw/hash-verification.txt`：

| 归档 | 来源 | SHA-256 | 结论 |
|---|---|---|---|
| `moonbit-darwin-aarch64.tar.gz` | 官方 sidecar 与本地文件均重算 | `20967f93…f3ec3` | 与任务卡给定值逐位一致；**已核验** |
| `lib/core.tar.gz` | 本地重算 | `6f18b8fd…1b14` | 与任务卡记录的观察值一致；**非发行方证明** |
| `moonbit-linux-x86_64.tar.gz` | 本机未下载 | `9226694d…31b6a` | 取自 2026-09-21 发行物探测的官方 sidecar；**本机未复核** |

## 4. Windows-free 本机门槛（macOS arm64，SHA `89b4e01`）

原始输出在 `raw/`，退出码单独记于 `raw/*-exit.txt`。

| 命令 | 退出码 | 结果 | 证据 |
|---|---:|---|---|
| `moon fmt --check` | 0 | **PASS**（起点为 255，见下节） | `raw/fmt-check.txt` |
| `moon check --target native` | 0 | **PASS**，14 warnings | `raw/check.txt` |
| `moon build --target native` | 0 | **PASS** | `raw/build.txt` |
| `moon test --target native` | 0 | **PASS**，77/77 | `raw/test.txt` |
| `MOONTICK_BIN=<native exe> python3 tests/cli/test_cli.py` | 0 | **PASS**，42 tests | `raw/cli.txt` |
| `MOONTICK_BIN=<native exe> python3 tests/oracle/test_differential.py` | 0 | **PASS**，8 手算 + 1000 随机 + 30×3 变形 + `N=10^12` | `raw/oracle.txt` |
| `moon info` | 0 | 见第 6 节 | `raw/moon-info.txt` |

被测二进制：`_build/native/debug/build/cmd/moontick/moontick.exe`，
SHA-256 `99bc25ed56f05c06fb0b284a380d9fc3937af17dbf674a902f191e938716f28b`
（`raw/binary-sha256.txt`）。该值只对应本机构建，不是跨平台承诺。

`check` 的 14 条 warning 与 T4 记录的数量一致，未新增。`test` 另有一条关于主包
使用黑盒测试输入的提示，与 T4 相同，本轮未改变。

## 5. 格式清理（起点红灯 → 绿灯）与等价性证明

起点 `moon fmt --check` 现场退出 **255**，与 T5 oracle 基线记录一致。

处理方式：用固定工具链的 `moon fmt` 整理，**未在 CI 中跳过该门槛，也未把失败写成通过**。
共 15 个文件被改写，diff 只包含机械变化——参数列表换行、结构体字面量尾随逗号、
字段简写（`grid: grid` → `grid`）、`keywords` 数组空格。已逐类抽查，未发现任何语义改动。

**等价性证明**：对格式化前后两个真实二进制分别回放 37 个 CLI 调用（text/JSON 报告、
空文件、重复、乱序、离网格、越界、`Int64` 边界、`detail-limit`、help/version、缺参/未知参数/
文件不存在），逐字节比较 stdout、stderr 与真实退出码：

```text
diff  raw/fmt-equivalence-before.txt  raw/fmt-equivalence-after.txt   # 无差异
sha256 both files = 67e6ce2c9eaac9d74c63728c98597102720fac52e61b6d1b8f251c171510279a
```

即格式化未改变任何可观察行为。二进制字节本身不同（调试构建嵌入路径/时间），
因此以**行为**而非二进制哈希证明等价。

## 6. 公开接口差异审查（`moon info`）

`moon info` 修改了一个受版本控制的生成文件 `report/pkg.generated.mbti`，**未被静默提交**，
已逐项审查：

```diff
+pub fn render_text(@core.AuditReport, Array[Int]) -> String
+pub fn try_render_json(@core.AuditReport, Array[Int]) -> Result[String, String]
+pub fn try_render_text(@core.AuditReport, Array[Int]) -> Result[String, String]
```

- 三个函数都是 T4 文本报告修复已引入、但当时未重新生成 `.mbti` 的真实公开函数
  （`report/text.mbt:107`、`report/json.mbt:128`、`report/text.mbt:122`）。
- 纯新增：无任何既有声明被修改或删除，冻结的公开类型与错误码未变。
- 复核方式：在新进程重跑 `moon info`，不再产生任何差异（幂等），且 `core`、`cmd/moontick`
  两个包的 `.mbti` 无变化。

这属于生成产物与源码不同步的既有缺陷修复，不是接口语义变更。

## 7. CI 工作流（`.github/workflows/ci.yml`）

### 7.1 设计

- 固定版本 `0.10.14+7d59c7ec9`（URL 中以 `%2B` 转义），**不使用 `latest`**，不使用全局
  `~/.moon`，不执行会改 shell 配置的官方安装脚本；下载与解压全部落在 `$RUNNER_TEMP`。
- 矩阵：`macos-15`（arm64）与 `ubuntu-24.04`（x86_64），与两个归档的架构一一对应。
- 安装步骤复刻官方 `install/unix.sh` 的协议：二进制归档解压到前缀目录，core 归档解压到
  `lib/`，然后对 `lib/core` 执行 `moon bundle`——**core 必须单独下载并编译**，二进制归档
  本身不足以构建。
- 二进制归档用**发行方自己的 `.sha256` sidecar** 校验，sidecar 摘要与工作流中钉死的常量
  双重比对（两个值本轮均已在本机现场重算确认）。
- 核心归档没有发行方校验材料，处理见 7.2。
- 断言 `moonc -v` 精确等于 `v0.10.14+7d59c7ec9`；断言 runner 架构（`runner.arch` 归一化，
  因 Linux 把 arm64 报成 `aarch64`），架构不符即失败而不是静默构建错误目标。
- 明确设置真实产物 `MOONTICK_BIN` 后再跑 CLI 与独立 oracle，与本地门槛命令一致。

### 7.2 供应链限制（未完成，不掩盖）

官方 core 归档的 `.sha256` sidecar 在 2026-09-21 探测中返回 **HTTP 403**，至今没有发行方
校验材料。因此：

- macOS 侧与**本机观察值**比对，一致时在 job summary 中明确写为
  "consistency check against a single-machine observation, **not** a publisher attestation"。
- Linux 侧没有观察值，`OBSERVED_CORE_SHA256_LINUX` 显式写为 `UNKNOWN_NOT_VERIFIED`，
  summary 输出 **NOT VERIFIED**，不会把未做的校验写成通过。
- 无论哪种情况，**真正把关的是 `moonc -v` 断言**，core 哈希只作报告项。

**结论：官方 core 供应链证明仍未完成，跨平台发布/CI 供应链阻断项保留。**

### 7.3 静态核验（不是 CI 通过）

本机无 `actionlint`/`yamllint`/`shellcheck`，故：

- YAML 用两个独立解析器（Python `yaml`、Ruby `YAML`）解析通过：`raw/workflow-static.txt`。
- 13 个 `run:` 块全部通过 `bash -n`：`raw/workflow-shell-syntax.txt`。
- 关键 shell 逻辑用真实归档在本机实测：sidecar 解析、两条哈希比对、`moonc -v` 断言
  （并验证它会**拒绝**形如 `v0.10.15+deadbeef` 的近似版本）、core 目录定位。

静态核验只能证明语法与逻辑自洽，**不能替代远程运行**。

## 8. 远程 CI 状态：NOT_RUN

- 仓库无 Git remote；未创建公开仓库、未 push、未发布、未报名、未读取或输出任何凭据。
- `raw/remote-ci.txt` 记录仓库的 remote 查询结果。
- 因此：（macOS, GitHub Actions）= **NOT_RUN**；（Linux, GitHub Actions）= **NOT_RUN**。
- 不能以"工作流文件存在"或"YAML 解析通过"宣称 CI 通过。
- 解除条件：建好远程并产生**对应本 SHA** 的 run URL。届时才可把对应平台标为 PASS。

## 9. 明确未做（NOT_RUN）

- Linux 本机 native 构建/测试：本机为 macOS，未下载 Linux 归档，**NOT_RUN**。
- Linux 上 `moon fmt --check`、check/build/test、CLI、oracle：**NOT_RUN**。
- 任何 GitHub Actions 运行：**NOT_RUN**。
- `moon publish --dry-run`、注册表安装、对外发布：**NOT_RUN**（不属于本轮）。

## 10. 限制

macOS 的 PASS 只证明该平台该 SHA 上的一次观察。独立 oracle 是独立实现，但仍共用同一
产品二进制；格式等价性用 37 个 CLI 用例覆盖可观察表面，不是形式化证明。core 归档缺少
发行方校验，仍是公开的供应链未决项。
