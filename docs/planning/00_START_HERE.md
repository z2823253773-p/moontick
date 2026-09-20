# MoonTick 季度参赛工作包 v1.1

日期：2026-09-21。当前范围：**独立核心库 + ticks 行输入 CLI**。目标：可复现交付与季度评选。

当前完成规划修订与调查。没有产品仓库、产品实现、CI、发布或参赛回执。原 v1 目录和压缩包保留为历史快照，不再作为执行规格。

## 阅读入口

1. [G0-R 变化与结论](08_G0_REVISION.md)。
2. [需求证据卡](09_USE_CASE_EVIDENCE.md) 与 [工具链核验](10_TOOLCHAIN_BASELINE.md)。
3. [规格](02_SPEC.md)、[任务卡](04_TASK_PLAN.md)、[协作协议](03_WORKFLOW.md)。
4. [策略](01_STRATEGY.md)、[交付证据](05_EVIDENCE_RELEASE.md)、[规则状态](06_RULES_SOURCES.md)。

## 关键修订

- 每行一个规范整数毫秒，无表头；不实现完整 CSV、不提供 --column。
- 零字节文件为全缺失，空白行为格式错误；记录号=物理行号。
- 精确固定网格，不容差吸附、不补值、不推断计划。
- 季度优先试用与维护；多序列/完整 CSV 由需求决定。
- 配置改为 moon.mod / moon.pkg，实际兼容性在最小工程验证。

## 当前状态

“继续”用于推进本轮 G0-R；本轮没有启动产品开发。范围和两条需求来源已整理；工具链重装路径未验证：历史版本四个 HEAD 请求返回 403，不能据此保证 CI 可安装。

下一执行方读 [Codex 接力指令](prompts/CODEX_START.md) 处理剩余工程项；获准实施后 [Claude 指令](prompts/CLAUDE_START.md) 从 T1 开始。把本地闭环与跨平台可重装分别记录，不能自动标完整 G0/T5 通过。

模板：[AGENTS](templates/AGENTS.md)、[CLAUDE](templates/CLAUDE.md)、[TASK_STATE](templates/TASK_STATE.md)。换会话读 [RESUME](prompts/RESUME.md)。交接以磁盘状态、明确 SHA 与命令输出为准。

9/24 为内部检查点，9/30 为用户 G0 当日官网记载。精确截止、资格和计数口径待官方确认。规划包不是人工申报书；[包校验](07_PACKAGE_CHECK.md) 不能代替产品测试。
