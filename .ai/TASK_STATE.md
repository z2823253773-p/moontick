# MoonTick 当前状态

日期：2026-09-22。T1–T4 已按固定 SHA 验收；T5 在 macOS arm64 与 Linux x86_64 的真实 GitHub Actions 上通过。
T6 的 29 文件包归档已正式发布为 Mooncakes `z2823253773-p/moontick@0.1.0`；
公开版本页与仓库外安装、core 调用均已验证。赛事报名仍未完成。
用户于 2026-09-22 确认本期 9 月 30 日截止；这不等于报名或验收已提交。

- task_id: T6
- status: PUBLISHED_VERIFIED / Codex（Mooncakes 0.1.0 发布及独立安装复现通过；赛事申报未完成）
- active_owner: Codex（整理已完成的发布证据和用户人工申报事实清单）
- implementation_authorized: YES（本地预检、公开 GitHub 推送、用户明确批准的 Mooncakes 0.1.0 正式发布；不含赛事报名）
- objective: 保存发布/安装证据，支持参赛负责人在 9 月 30 日前人工完成申报与季度选项
- repo_root: /Users/henryz/Desktop/比赛/moontick
- branch: main
- tested_commit: T1 实现 `754ff0ea7eae10cc416f6207ce94277395ddb1f3` 已接受；
  T2 被测 SHA `a88af81bf7e9ff07698c63a293111532b022ba75` 已接受；
  T3 被测 SHA `8092ac634a9ff92839ccc862ccd0aaddc670e792` 已接受；
  T4 首个被测 SHA `6d9774519c2c9cb20376af7d79a32c0fea63732e` 复核未通过（两个文本反例）；
  T4 修复被测 SHA `e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c` 已接受；
  T5 oracle 提交 `4de792d86a3848d2f387d4dc774033edaa9b0f07` 仅新增 Python 独立测试；
  后续文档提交不改变上述产品被测 SHA；
  T5 CI 首轮候选 `89b4e01fcece1ba8264e6109254571253c45b063` 复核未通过（矩阵上下文 P1）；
  **T5 CI 返修被测 SHA `22ae166880d531a21ba2d28c6c0d312351f3b0ff`（本机候选接受；远程 CI 未运行）**；
  README/许可证整合提交 `f32c413` 已在主工作树回归验证；
  **远程 CI 权限修复 SHA `e047c4d20db6b83db7e633730b07f9467045201d`（双平台真实运行通过）**；
  **T6 发布候选最终包 SHA `4a9bf78b516cf9cf166455b561a442741e896f4a`；`v0.1.0` 标签指向 `30ea5ec64fc5000c84b7aa526de0d3a7e1ea97cd`，Mooncakes 与独立安装已核实**

## 当前任务：T6（已发布；正式申报待用户）

`moon.mod` 已写入已验证的 `z2823253773-p/moontick`、公开仓库 URL、MIT 与版本
`0.1.0`。`.moonignore` 将发布包收敛为 29 个文件，含 core/ticks_input/report/CLI、
README、LICENSE、CHANGELOG、AI_USAGE 和三组各有正常/故障输入的合成示例；
排除内部规划、测试脚本与原始日志。六个例子实测覆盖、缺口、重复、退出码均符合手算；
从归档另行解压后 native check/build 和正常/故障 CLI 均通过。

本机 fmt/check/build/test 通过（test 77/77；check 14 warnings），真实 CLI 42/42、
独立 oracle 通过。`moon publish --dry-run --frozen` 的服务端响应为
`202 Accepted: Dry run completed successfully. No changes were made`，但 CLI
最终仍退出 **255**，当时不能记录为命令成功或已发布。随后在用户明确批准下，
`moon publish --frozen` 退出 0、服务端 `200 OK`；[Mooncakes 0.1.0 版本页](https://mooncakes.io/docs/z2823253773-p/moontick@0.1.0)
显示模块、版本、MIT 与仓库。仓库外新工程用 `moon add z2823253773-p/moontick@0.1.0`
下载，native check 0、test 2/2；安装得到的 29 个文件与候选归档逐字节一致。
公开 `v0.1.0` Git 标签指向上述源提交。完整记录：
`docs/evidence/T6/release-and-consumer.md`。官方 core sidecar 仍缺；赛事报名、
官方验收与季度资格回执尚未完成。

候选已推送；[run 35748833083](https://github.com/z2823253773-p/moontick/actions/runs/35748833083)
在仅多出 T6 证据文档的 SHA `aebf418f19131245b15732aec178101057d9c9a7`
上双平台 success：各 77/77、CLI 42/42、独立 oracle 通过。包文件与已核对的
`4a9bf78` 候选相同，因为随后提交只增加 `.moonignore` 排除的内部文档。

## 历史任务：T5（双平台远程 CI 已通过）

真实运行：[成功 run 35747020671](https://github.com/z2823253773-p/moontick/actions/runs/35747020671)，
固定 SHA `e047c4d20db6b83db7e633730b07f9467045201d`。`macos-15 / native` 与
`ubuntu-24.04 / native` 均为 success：各自 `moon test` 77/77、真实 CLI 42/42，
独立 oracle（8 手算、1000 随机、30×3 变形、`N=10^12`）通过。精确版本
`moonc v0.10.14+7d59c7ec9`、二进制归档发行方 sidecar 哈希、runner 架构均通过。
首轮 [失败 run 35746584237](https://github.com/z2823253773-p/moontick/actions/runs/35746584237)
停在 `moon: Permission denied`：官方归档文件权限为 0644。修复只在解压后为
`bin/` 下非 `.wasm` 文件补执行位，未改产品代码、版本钉定、哈希门槛或测试。
证据：`docs/evidence/T5/remote-ci-2026-09-22.md`。

官方 core 归档仍无发行方 sidecar；Linux core 只记录观察哈希，**供应链验证未完成**。
Mooncakes 发布、赛事申报/验收、季度评选资格均未完成或未得到确认。

Codex 在固定返修 SHA `22ae166` 的独立 worktree 复核矩阵字面量与 GitHub
上下文规则，并重跑 fmt/check/build/test 77/77、真实 CLI 42/42、独立 oracle 和
`moon info` 幂等，全部通过。独立记录：
`docs/evidence/T5/codex-independent-review-22ae166.md`。公开 README 与 MIT
许可证已从隔离 worktree 整合；组合 HEAD 本机门槛同样通过。现有 `origin` 是
`https://github.com/z2823253773-p/moontick.git`，空的公开仓库；只有推送后
对应 SHA 的 Actions run 能决定远程 macOS/Linux 状态。官方 core 校验材料仍缺。

## T5 返修交接（历史记录；已本机复核）

Codex 在固定 `89b4e01` 的独立 worktree 复现本机门槛全部通过，但静态审查发现
`.github/workflows/ci.yml:52–57` 的矩阵属性使用 `${{ env.* }}`，而 GitHub 官方
上下文表不允许 `env` 用于 `jobs.<job_id>.strategy`。这是依据官方规则确认的配置
阻断，远程尚无运行错误日志。复核记录：
`docs/evidence/T5/codex-independent-review-89b4e01.md`。

Claude Code 本轮（起点 `aa4902a`）按返修卡完成单点修复，固定 SHA
`22ae166880d531a21ba2d28c6c0d312351f3b0ff`：

1. **只改 `.github/workflows/ci.yml`**。四个矩阵表达式改为字面量（沿用已固定且有
   来源记录的 SHA / core 观察值），并删除只被矩阵引用、已成死引用的工作流级
   `SHA256_*` / `OBSERVED_CORE_*` 环境变量。选字面量而非 `vars`：远程仓库虽已配置
   `origin`，但尚无任何 push，远程 `vars` 从未设置过；字面量可离线自证，不依赖远程状态。
   **未用 `latest`、未删平台、未放宽 checksum、未绕开任何失败门槛。**
2. 独立复核了规则本身（未仅依赖 Codex 结论）：官方
   [上下文可用性表](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts)
   的 `jobs.<job_id>.strategy` 行只列 `github, needs, vars, inputs`。P1 成立。
3. 新增**非空跑的上下文审计**（`_build/check_workflow_contexts.py`，未提交）：把官方
   可用性表编码为逐位置检查。对修复前工作流报 **BAD / 退出 1**，对修复后报
   **0 处非法 / 退出 0**——能抓到原缺陷，故该检查有效。
4. 本机回归：`fmt --check` 0、`check` 0（14 warnings）、`build` 0、`test` 77/77、
   真实 CLI 42/42、独立 oracle 全通过、`moon info` 后 `.mbti` 无漂移。
   YAML 双解析器通过；13 个 `run:` 块 `bash -n` 无语法错误。证据：
   `docs/evidence/T5/CI-matrix-context-fix.md`、`raw/repair-*.txt`。

**（Linux）= NOT_RUN；（GitHub Actions）= NOT_RUN。** 注意状态依据已变化：远程 `origin`
现已配置为 `https://github.com/z2823253773-p/moontick.git`（2026-09-22 00:28:29 写入
`.git/config`），但该远程**为空**——`git ls-remote origin` 返回 0 个 ref，任何分支都没有
upstream，**没有任何提交被 push**。因此 Actions 从未对任何 SHA 运行过，NOT_RUN 成立，
但理由已不是"无 remote"。首次 push 前需先完成 `README.mbt.md` 与 `LICENSE` 的公开前修正。
静态核验不构成远程 CI 通过。官方 core checksum 仍无来源证明，供应链阻断项保留。

返修卡：`docs/handoffs/T5_CI_REPAIR_CLAUDE.md`。两个 runner 标签已从 GitHub 官方文档
核实：`macos-15` 为 arm64，`ubuntu-24.04` 为 x64，无须改标签。本机 `gh auth status`
显示当前 GitHub CLI 登录凭据无效，用户需重新通过浏览器授权后再推送经复核的提交。
公开前预检另发现 `README.mbt.md` 仍是 T1 阶段文案，且缺 `LICENSE`；首次 push 前需修正
并复核。证据：`docs/evidence/T5/github-preflight-2026-09-22.md`。

**交给 Codex 的最小复核命令**（复核目标 `22ae166880d531a21ba2d28c6c0d312351f3b0ff`，独立 worktree，隔离工具链）：

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
git diff aa4902a 22ae166880d531a21ba2d28c6c0d312351f3b0ff --stat          # 期望只改 ci.yml
grep -n 'env\.' .github/workflows/ci.yml # 期望只命中注释，无 env.* 表达式
python3 -c 'import yaml;yaml.safe_load(open(".github/workflows/ci.yml"))'
moon fmt --check && moon check --target native && moon build --target native
moon test --target native                # 期望 77/77
MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \
  python3 tests/cli/test_cli.py          # 期望 42/42
MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \
  python3 tests/oracle/test_differential.py
moon info && git diff --exit-code -- '*.mbti'   # 期望无输出
```

## T5 首轮交接（历史记录；其矩阵上下文 P1 已在 22ae166880d531a21ba2d28c6c0d312351f3b0ff 返修）

Codex 使用固定 T4 产品 SHA 的真实二进制完成独立 oracle：8 个手算样例、
`seed=20260920` 的 1000 个小网格、30 组三类变形检查、一个 `N=10^12` 解析案例；
逐字段 JSON、详情、截断及真实退出码无差异。测试代码提交 `4de792d`，
证据 `docs/evidence/T5/oracle-baseline.md`。

Claude Code 本轮（起点 `3813d56`）交付固定 SHA `89b4e01`：

1. 格式门槛由起点现场实测的 **255** 转绿。用隔离工具链的 `moon fmt` 整理 15 个文件，
   diff 仅含换行、尾随逗号与字段简写。**未跳过门槛、未把失败写成通过。**
   等价性用格式化前后两个真实二进制回放 37 个 CLI 调用证明：stdout、stderr、
   退出码逐字节一致（两文件 SHA-256 同为 `67e6ce2c…0279a`）。
2. `moon info` 暴露 `report/pkg.generated.mbti` 与 T4 源码不同步，补上三个纯新增公开
   函数（`render_text`、`try_render_json`、`try_render_text`），无既有声明变化，重跑幂等。
3. 新增 `.github/workflows/ci.yml`：`macos-15`(arm64) 与 `ubuntu-24.04`(x86_64) 固定
   `moonc v0.10.14+7d59c7ec9`，跑 `moon fmt --check`、native check/build/test、真实 CLI
   与独立 oracle，断言精确版本与 runner 架构。二进制归档按发行方 sidecar 校验；
   core 无发行方校验材料，仅与单机观察值比对并在 summary 中明确标注非发行方证明，
   Linux 侧记为 NOT VERIFIED。

本机 macOS arm64 全部门槛：`fmt --check` 0、`check` 0（14 warnings）、`build` 0、
`test` 77/77、真实 CLI 42/42、独立 oracle 全通过。证据 `docs/evidence/T5/CI.md`。

**Linux 与远程 GitHub Actions 均为 NOT_RUN**：仓库仍无 Git remote，未创建、未 push、
未发布。工作流只做了静态核验（两个 YAML 解析器 + 13 个 `run:` 块 `bash -n`），
这不等于远程 CI 通过。官方 core checksum 仍无来源证明，供应链阻断项保留。

Claude Code 任务卡：`docs/handoffs/T5_CLAUDE_CI.md`。用户按北京时间闲时手动启动；
Codex 不代为启动、不安排定时或后台续跑。T5 不能凭工作流文件或本地测试宣称
跨平台 CI 已通过。

**复核目标 SHA 为 `89b4e01`**（产品与 CI 的最后一个提交）；其后的提交只追加
`docs/evidence/T5/` 与 `.ai/TASK_STATE.md`，按既有约定不改变被测 SHA。

**交给 Codex 的最小复核命令**（在 `89b4e01` 的独立 worktree，隔离工具链）：

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon fmt --check                          # 期望 0
moon check --target native                # 期望 0，14 warnings
moon test  --target native                # 期望 77/77
moon build --target native                # 期望 0
MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \
  python3 tests/cli/test_cli.py           # 期望 42/42
MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \
  python3 tests/oracle/test_differential.py
moon info && git diff --exit-code -- '*.mbti'   # 期望无输出（幂等）
python3 -c 'import yaml;yaml.safe_load(open(".github/workflows/ci.yml"))'
```

## 历史验收：T4（本机技术验收通过）

Codex 在固定 SHA `e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c` 的独立
worktree 复核修复：`moon check` 0（14 warnings）、全仓 77/77、report 23/23、
native build 0、真实 CLI 42/42。独立 Decimal 参考值与文本输出在 262 个覆盖率
案例一致；修复前后 3 个 JSON 用例的退出码、stdout、stderr 逐字节一致。
`2/3` 为 `66.67%`、`57/100` 为 `57.00%`；19999/20000 虽显示
`100.00%`，仍为 FAIL / 退出 1。缺失区间提示准确区分已显示的 1 个区间与
总共缺失的 98 个点，接受语义等价措辞。复核记录：
`docs/evidence/T4-fix/codex-independent-review-e35fbb2.md`。

以下首轮复核反例保留为历史过程，不代表当前产品状态。

复核记录：`docs/evidence/T4/codex-independent-review-6d97745.md`。在固定 SHA 的
独立 worktree 重跑 check（0，14 warnings）、全仓 test（73/73）、report（19/19）、
build（0）及真实 CLI（37/37），随后发现两例现有测试未覆盖的文本输出错误：

1. `2/3` 显示 `66.66%`，违反规格 2.2 的两位小数四舍五入口径；`57/100`
   甚至显示 `56.99%`，并非正确截断。
2. 两个缺失区间、共 98 个缺失点、`detail_limit=1` 时，文本写成
   `showing first 1 of 98; truncated`，把缺失点数当成缺失区间总数。

T4 首个 SHA 未被接受。Claude Code 保留上述最小反例、仅修文本展示与相关测试，
并提交新的固定 SHA；Codex 随后完成独立复核并接受修复。
`__pycache__/` 已在 `.gitignore` 忽略，缓存文件本身未删除、未提交。
用户继续手动控制 Claude Code 的闲时运行，不设置自动续跑。

任务卡：`docs/handoffs/T4_CLAUDE.md`。T1–T3 已有 JSON、真实 CLI 与严格 ticks 输入；
本轮只补默认 text 报告、非 JSON 错误输出通道、定位字段和五类截断的进程级证据。
未重写已通过的核心或输入实现，未开展 T5+。用户在北京时间闲时手动启动 Claude Code；
Codex 不代为启动或设置自动续跑。首个固定 T4 SHA 已交 Codex 复核并收到两个反例，
修复后的新固定 SHA 再次交 Codex 在独立 worktree 验证。

### T4 实施结果（2026-09-21，Claude Code）

- 起点基线：`100830aad1c95e2999cb62f9c3c22b0d8e1150df`（T4 任务卡提交），工作树干净，
  与任务卡一致。未把该文档 SHA 当作产品被测 SHA。
- 隔离工具链 `/private/tmp/moontick-moon-0.10.14-OS4LNz` 可用，`moonc v0.10.14+7d59c7ec9`
  现场复核；未使用全局 `~/.moon`，未读凭据。
- **本轮有真实 RED**（与 T2/T3 的零改动不同，T4 是产品实现轮）：先写测试得
  `37 tests, 11 failures + 2 errors`，再实现最小改动。五类截断矩阵与"显式/默认等价"
  两组在无 UI 依赖下先行通过，按任务卡如实记录为"既有行为直接通过"，未伪造 RED。
- **产品实现变更**：
  - 新增 `report/text.mbt`（纯渲染器，无文件/时钟/主机/路径）。
  - `cmd/moontick/main.mbt`：text 分支改为渲染报告；解析成功后的
    `CONFIG_INVALID`/`INPUT_INVALID`/`RESOURCE_LIMIT`/`IO_ERROR` 改为写 stderr、
    stdout 为空；可定位输入错误同时带 `record_index` 与 `line`；`--version` 去掉 `(T1)`。
  - `report/moon.pkg` 仅加 `moonbitlang/core/double` 导入（**该导入已在后续修复中
    移除**，见下节：百分比改为纯整数运算后不再需要）。**未改** `core/*`、
    `ticks_input/*`、`report/json.mbt`，未扩大任何自有公开 API。
- 门槛：`moon check` 退出 0（14 warnings / 0 errors，与 T1–T3 同数、无新增）、
  `moon test` 退出 0（73/73，T3 为 62）、report 包 19/19、`moon build` 退出 0、
  `python3 tests/cli/test_cli.py` 退出 0（37 passed，T3 为 17）。
- 产品二进制 SHA-256 `a1f590ddda144ab26328e152f89885a0c560ca608a491aa8a79b96697a030497`，
  与 T1–T3 的 `b9e3e189…` 不同——本轮确有产品变更，符合预期。
- 变异抽查四处（错误通道 / 截断提示 / 百分比 / `record_index`）各自精确命中对应用例，
  随后全部还原。**注意**：截断提示那处只被进程内用例捕获，三份 golden 都没抓到，
  因为任务卡指定的 golden 输入均不触发截断。已记录为 golden 覆盖面的已知边界。
- 证据：`docs/evidence/T4/report-and-cli.md`、`docs/evidence/T4/gates.md`、
  原始输出 `docs/evidence/T4/raw/`、golden `tests/golden/text-*.txt`。

## 历史验收：T3（macOS native 范围内接受）

任务卡：`docs/handoffs/T3_CLAUDE.md`。T1 已实现解析和 CLI，T3 仅补尚缺的原始字节、
库层资源边界和位置证据；若新增测试发现真实不一致，再做最小修复。不重写已通过行为，
当时未开展 T4+。用户控制 Claude Code 启动时间，仅在北京时间闲时运行；Codex 不代为启动
或设置自动续跑。T3 实际被测 SHA 与验收记录见下文；T4 已另发差量任务卡。

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
发布及干净消费者安装目前均无完成证据。不得用本地 T1/T2/T3 验收替代官方资格/验收。

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

## T4 首轮交接（历史记录；已由修复与复核取代）

以下保留首轮交接原貌；其中百分比预期、截断 golden 状态和待复核指令
均已被 `e35fbb2` 修复及本机验收取代，不能作为当前产品结论。

- 起点基线：`100830aad1c95e2999cb62f9c3c22b0d8e1150df`
- T4 首个实现 SHA：`6d9774519c2c9cb20376af7d79a32c0fea63732e`。
  相对 `8092ac6`（T3）**既有产品实现变更，也有测试与证据新增**。
- 改动文件：
  - 新增 `report/text.mbt`、`report/text_test.mbt`（11 个测试）
  - 新增 `tests/golden/text-{complete,empty,duplicates-and-missing}.txt`
  - 修改 `report/moon.pkg`（加 `moonbitlang/core/double`）、
    `cmd/moontick/main.mbt`、`tests/cli/test_cli.py`（+21 个真实进程用例）
  - 新增 `docs/evidence/T4/`；修改 `.ai/TASK_STATE.md`（状态 → REVIEW，owner → Codex）
- 验证命令（同一隔离工具链，逐字照抄任务卡）：
  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  export PATH="$MOON_HOME/bin:$PATH"
  moon check --target native && moon test --target native && moon build --target native
  export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
  python3 tests/cli/test_cli.py
  ```
- 证据：`docs/evidence/T4/`
- Codex 的最小复核面：
  1. **文本错误通道**：`moontick check <bad> --start-ms 0 --end-ms 60 --step-ms 15`
     必须退出 2、**stdout 为空**、stderr 含 `INPUT_INVALID`。旧 T3 产物把该诊断写在
     stdout，复核时请确认这是本轮有意变更且符合 SPEC 3.2（该规格句限定 JSON 模式）。
  2. **定位字段**：同一错误加 `--format json` 后应得
     `"record_index":2,"line":2`；不可定位的错误（IO/CONFIG/字节或记录上限）应**同时
     省略两字段**，请重点核对省略分支。
  3. **百分比**：`covered/expected` 用 `Double` 缩放后截断（非四舍五入），且通过/失败
     只来自 `report.passed`。请用独立计算核对 1/3→`33.33%`、2/3→`66.66%`。
  4. **五类截断**：`--detail-limit 1` 逐类复核，重点确认"除本类别外 truncated 均为
     false"以及"恰好等于上限不算截断"（比较为 `>` 而非 `>=`）。
  5. **golden 局限**：三份 golden 均不触发详情截断，截断文本证据只在
     `report/text_test.mbt`。请勿把 golden 通过当作截断证据。
- 未完成/未授权：Linux native、CI、发布、报名均未运行；文本格式的截断 golden 未补；
  终端列对齐行为未测。无待修复的最小反例。

## T4 修复交接（已独立验收）

- 起点 HEAD：`23d25dd`（Codex 复核记录提交），工作树干净。
- T4 修复被测 SHA：`e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c`。
- 只修复核记录中的两个文本输出反例，**未改核心计数、未改 JSON 契约、
  未改 `core/`、`ticks_input/`、`report/json.mbt`、`cmd/moontick/main.mbt`**。
- 改动文件：
  - 修改 `report/text.mbt`（`percent()` 改纯整数四舍五入；缺失区间截断提示分列两个量）
  - 修改 `report/moon.pkg`（移除已不需要的 `moonbitlang/core/double`）
  - 修改 `report/text_test.mbt`（+4 进程内用例）、`tests/cli/test_cli.py`
    （+5 真实进程用例，新增 `TextAccuracyRegressions`）
  - 新增 `tests/golden/text-truncated-missing.txt`（首份触发详情截断的文本 golden）
  - 新增 `docs/evidence/T4-fix/`；修改 `.ai/TASK_STATE.md`
- 两处修复：
  1. **P1 百分比**：`Double` 比例缩放在 `trunc` 前已略小于精确整数值，导致
     `57/100` 显示 `56.99%`、`2/3` 显示 `66.66%`。改为**全整数**：先拆出整数商与
     余数，只缩放余数（`remainder < 250000`，受记录上限约束），末尾做四舍五入。
     仍不使用 `report.passed` 以外的通过判据。
  2. **P2 截断提示**：原 `showing first 1 of 98` 把缺失**点数**当成区间**总数**。
     改为分列两个量且不虚构区间总数：`ranges shown: 1; missing points in total: 98`，
     并把 `(truncated)` 提到标题。**未扩展 `AuditReport` schema**（复核记录明确不要求）。
     记录类别的 "first N of M" 两数同量纲，保持原样。
- 门槛：`moon check` 退出 0（**14 warnings / 0 errors，无新增**）、
  `moon test` 退出 0（**77/77**，修复前 73）、report 包 **23/23**、
  `moon build` 退出 0、`python3 tests/cli/test_cli.py` 退出 0（**42/42**，修复前 37）。
- 产品二进制 SHA-256 `d3f53710a11d0249524a24ff32cb89554bddb9bb7d0e44c8fc1f162ee7579a8a`。
- 变异抽查三处（四舍五入 `>=`→`>`、四舍五入→截断、提示改回旧措辞）现**同时**被
  进程内与进程级用例捕获；其中提示那处由新增的截断 golden 捕获。
- **JSON 契约实测未变**：用旧源码与新源码各构建一次，对同一命令同一输入做逐字节
  `diff`，无差异（`docs/evidence/T4-fix/raw/json-before-vs-after.txt`）。
- Codex 最小复核面：
  1. `2/3` 是否显示 `66.67%`、`57/100` 是否显示 `57.00%`；请用**独立于产品代码**的
     百分比 oracle 交叉验证，不要调用 `percent()` 当真值。
  2. 19999/20000 是否显示 `100.00%` 但**仍 `FAIL` / 退出 1**（SPEC 2.2 点名场景）。
  3. `ranges shown: 1; missing points in total: 98` 两个计数是否量纲正确。
  4. 采用的措辞与复核记录所给示例措辞**不同**（语义等价、约束满足）。如要求逐字
     一致，请明确指出。
- 未完成/未授权：Linux native、CI、发布、报名均未运行；终端列对齐未测。
- 证据：`docs/evidence/T4-fix/review-repair.md`、`docs/evidence/T4-fix/raw/`。

## 接下来

1. 首次推送当前已核验的主分支到 `origin`；核对 GitHub 页面显示 README、MIT
   许可证和完整提交记录，不把公开仓库创建本身当作报名。
2. 取得该提交的 macOS arm64 与 Linux x86_64 GitHub Actions run URL，逐步
   复核安装、格式、测试、CLI、oracle 和供应链提示。若失败，保存真实日志与最小
   原因，修复后重新验证；只有两个真实 run 都通过才接受 T5 远程 CI。
3. 随后推进 T6 的三个可运行场景、Mooncakes 发布候选和用户本人撰写的一页申报。

T1–T4 验收和 T5 oracle 均只在 macOS native 范围内成立。Linux native、远程 CI、
发布和报名尚未运行；T5 已在本机通过，远程结果待验证。
