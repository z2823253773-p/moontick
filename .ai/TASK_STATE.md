# MoonTick 当前状态模板

日期：2026-09-21。T1 已获明确开工授权；本地模块名暂定为 moontick。

- task_id: T1
- status: READY
- active_owner: Claude Code
- implementation_authorized: YES（2026-09-21，范围仅 T1）
- objective: Claude Code 实现最小 core + ticks CLI；Codex 在明确 SHA 上独立复核
- repo_root: /Users/henryz/Desktop/比赛/moontick
- branch: main
- tested_commit: 不适用（尚无产品代码）

## 已完成

- v1.1 规格与任务同步；核心 + ticks，季度先试用再决定增量。
- 三项目固定版本对照来自用户 G0，本次未重跑竞品。
- 两条一手问题来源与合成最小场景；真实接入为零。
- 官方安装脚本核查、候选发行物 HEAD 探测、本机版本记录。
- 规划已迁入 docs/planning；模板已落根目录与 .ai。
- 隔离 moon 0.1.20260920、moonc 0.10.14+7d59c7ec9 已实测；证据见
  docs/evidence/T0/toolchain.md。官方 core 校验 sidecar 未取得。
- 当前工具链接受裸模块名 `moontick` 的 moon.mod / moon.pkg 临时 native 探测；
  check/build 退出 0，单测试通过但有未限定导入 warning。它不是 MoonTick 产品测试。

## 未决

- 真实 Mooncakes 发布命名空间与远程地址待定；本地 T1 使用 `moontick`，不得使用
  `username/...` 或猜测账户。确定后统一修改导入路径并重新测试。
- 完整供应链/跨平台 CI 仍未确认；core 官方校验 sidecar 未取得。
- MoonTick 产品代码、产品测试与明确实现 SHA 均 NOT_RUN。
- 日期、季度资格、commit 口径和申报要求待确认。
- 命名空间、远程地址与发布授权未定。

## 下一步

Claude Code 从 `docs/handoffs/T1_CLAUDE.md` 开始：先写并观察三个 RED 测试，再实现
最小 core/ticks/CLI，提交明确 SHA 与证据；Codex 随后独立验收。

## 交接字段

目录、分支、测试 SHA、修改原因、命令/退出码/证据、未测项、下一任务。历史放 evidence，不用模板伪造交接。
