# T5：Claude Code 实施任务卡（固定工具链与 CI）

## 起点与运行时段

- 仓库：`/Users/henryz/Desktop/比赛/moontick`。开始前核对 `main` HEAD、干净工作树及 `.ai/TASK_STATE.md`。T4 已接受的产品被测 SHA 是 `e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c`；`4de792d86a3848d2f387d4dc774033edaa9b0f07` 仅新增 Codex 独立 oracle，不是新的产品行为验收 SHA。以本任务卡提交后的实际 HEAD 为实施起点，不把文档 SHA 当成被测产品 SHA。
- 先读 `AGENTS.md`、`CLAUDE.md`、`.ai/TASK_STATE.md`、`docs/planning/04_TASK_PLAN.md` 的 T5、`docs/planning/05_EVIDENCE_RELEASE.md` 第 1–3 节、`docs/evidence/T5/oracle-baseline.md`、`docs/evidence/T0/toolchain.md`。
- 用户手动在北京时间闲时运行 Claude Code；工作日 09:00–12:00 与 14:00–18:00 为高峰，其余时段和周末为闲时。接近高峰则保存状态并停止；不设置定时任务、后台续跑或自行唤醒。
- 本机仅用 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz` 的隔离工具链，输出并核对 `moon version --all` / `moonc -v`。路径不可用时如实记录，不退回全局 `~/.moon`；不读取凭据。

## 已有验证与本轮目标

T1–T4 的 macOS native 产品行为已验收。Codex 的独立 Python oracle 已在固定 T4 二进制上通过 8 个手算样例、1000 个固定 seed 小网格、30 组三类变形检查与一个 `N=10^12` 解析案例；命令是 `MOONTICK_BIN=<真实 native 二进制> python3 tests/oracle/test_differential.py`。不要重写 oracle 或把 Python 放入产品包。

本轮交付可审查的 GitHub Actions 工作流：macOS arm64 与 Linux x86_64 在**相同精确 MoonBit 版本**下分别执行 `moon fmt --check`、native check/build/test、真实 CLI 与独立 oracle，并保存版本和退出状态。起点上本机 `moon fmt --check` 已真实退出 255；须先处理既有格式差异，不能在 CI 中跳过或把失败写成通过。

## 实施边界

1. 允许修改 `.github/workflows/ci.yml`、必要的隔离安装脚本、经 `moon fmt` 产生的格式差异、`docs/evidence/T5/` 和 `.ai/TASK_STATE.md`。格式整理与 CI 逻辑可分两个有意义的提交，便于复核。不要改产品语义、schema、计数、退出码或 oracle 期望；若门槛发现真实产品反例，保留最小输入并只做有证据的修复。
2. 固定 `moonc v0.10.14+7d59c7ec9`，不要使用 `latest`、全局 `~/.moon` 或会改 shell 配置的安装脚本。官方二进制归档 SHA-256：macOS arm64 `20967f9389ac54508899ee2fc051a3470d051452bac5818a9696ed4c144f3ec3`；Linux x86_64 `9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a`。core 归档的本地观察哈希为 `6f18b8fdea18f85e628a75e4a1bd3977c5a5c9c6a836fd8824192b0e6bd91b14`，并非发行方校验承诺；若官方 sidecar 仍不可用，CI 可以比对固定观察值，但必须保留“官方 core 供应链证明未完成”的限制。安装和归档路径必须隔离、可重复，不回写仓库或主目录凭据。
3. 选与架构匹配的 runner 标签，避免把 macOS Intel runner 配给 arm64 归档。工作流记录 `uname -srm`、`moon version --all`、`moonc -v`，并断言精确版本。不要只输出版本而不验证。优先使用 [GitHub runner 文档](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) 当前列出的 `macos-15`（arm64）与 `ubuntu-24.04`（x86_64）；运行时若架构不符则失败并记录。
4. CI 中明确设置真实产物的 `MOONTICK_BIN`，运行 `python3 tests/cli/test_cli.py` 与 `python3 tests/oracle/test_differential.py`。两个系统都要运行；网络/归档不可达时记录环境阻断，不删 job 或降为单平台。
5. `moon fmt --check` 起点红灯可用固定工具链的 `moon fmt` 整理，再审查 diff 只含机械格式，并重跑全部本地门槛。`.mbti` 若由 `moon info` 更新，逐项审查公开接口差异；不静默提交或忽略意外变化。对 shell/workflow 做静态语法核验（本机有工具则用），不能把 YAML 语法检查等同远程 CI 通过。
6. 仓库目前没有 Git remote。本轮不创建公开仓库、不 push、不发布、不报名、不读取或输出 Mooncakes 凭据。工作流本地可验证，但**实际 GitHub Actions 状态必须为 NOT_RUN**，直至远程建好并产生对应 SHA 的 run URL；Linux 本机未跑也不能记为 PASS。

## 交付与交接

- 运行并留存命令、退出码、测试数量及 warning：`moon fmt --check`、`moon check --target native`、`moon test --target native`、`moon build --target native`、真实 CLI 和独立 oracle。保留失败输出中的关键反例，不靠修改断言掩盖。
- `docs/evidence/T5/` 记录平台、架构、工具链及归档哈希、安装来源、workflow 静态核验、本机门槛、远程 CI 的 `NOT_RUN` 或真实 run URL、已知供应链限制。不得称本地运行是 Linux 或 GitHub Actions 通过。
- 提交固定实现 SHA，更新 `.ai/TASK_STATE.md` 为 `REVIEW / Codex`，交接改动文件、每个平台真实状态和最小复核命令。Codex 再在该 SHA 独立复核；若尚无远程 run，T5 只能记“本地 CI 候选”，不能正式接受跨平台 CI。
