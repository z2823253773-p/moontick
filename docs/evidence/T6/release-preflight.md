# T6 发布候选本地预检

日期：2026-09-22。候选源码/文档 SHA：
`4a9bf78b516cf9cf166455b561a442741e896f4a`。使用隔离工具链
`MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，`moonc v0.10.14+7d59c7ec9`。
未调用不带 `--dry-run` 的 `moon publish`，未向赛事表单提交材料。

## 元数据、归档与可公开内容

- `moon.mod`：真实 Mooncakes 命名空间 `z2823253773-p/moontick`、版本 `0.1.0`、README、公开仓库 URL 与 SPDX `MIT`。
- [官方模块配置文档](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)说明 `repository`、`license` 与 `.moonignore` 用法。`.moonignore` 排除内部规划、审核原始日志、开发测试和代理交接文件；保留库、CLI、README、LICENSE、CHANGELOG、AI_USAGE、六个合成 ticks 文件与说明。
- `moon package --list --frozen` 退出 0；实际 ZIP 有 **29 个文件**、28498 字节、SHA-256 `2b6d65a6b3cc64927101d0bee40115543ca281c1d7b9f5b6dd01c9026b0eea4a`。逐项检查含所需包与元数据，不含 `docs/`、`tests/`、`.ai/`、`AGENTS.md`、`CLAUDE.md`、`*_test.mbt`。扫描 ZIP 内容未匹配本机绝对路径、`credentials.json`、常见私钥头与常见 GitHub token 格式；模式扫描不能证明不存在其他敏感内容。
- ZIP 在独立临时目录解压后，`moon check --target native` 与 `moon build --target native` 均退出 0；解压产物的正常/故障 synthetic CLI 分别以 0/pass 和 1/fail 结束。这是本地包内容验证，**不是从 Mooncakes registry 安装**。

## 实例与回归

- 六个独立实例已逐一对照 JSON：archive 5/5 与 3/5（缺口 `[2,4)`），buckets 3/3 与 2/3（`[1,2)`），synthetic 4/4 与 3/4（`[2,3)`、额外重复 1 行）；正常退出 0，故障退出 1。全部使用合成输入。
- 候选下 `moon fmt --check` 0、native check 0（14 warnings）、build 0、test **77/77**、真实 CLI **42/42**、独立 oracle `manual=8 random=1000 seed=20260920 metamorphic=30x3 large_N=10^12` 通过；`moon info` 无 `.mbti` 漂移。
- 远端 T5 固定 SHA `e047c4d` 的[成功 CI](https://github.com/z2823253773-p/moontick/actions/runs/35747020671)和纯文档 SHA `6245428` 的[成功 CI](https://github.com/z2823253773-p/moontick/actions/runs/35747415808)均有真实运行记录。T6 候选已推送；其后仅增加被 `.moonignore` 排除的内部证据文档，在 SHA `aebf418f19131245b15732aec178101057d9c9a7` 上的[run 35748833083](https://github.com/z2823253773-p/moontick/actions/runs/35748833083)为 `completed / success`。macOS arm64 与 Linux x86_64 均报告 `moonc v0.10.14+7d59c7ec9`、`moon test` 77/77、CLI 42/42、独立 oracle 的 8 手算 + 1000 随机 + 30×3 变形 + 大网格通过。该运行验证的是含候选包源码的当前公开分支；正式 Mooncakes 发布仍未发生。

## Mooncakes 干跑与未完成项

- `moon publish --dry-run --frozen` 首次在受限环境中因 macOS `system-configuration` 的 NULL object panic 退出 255。联网重试后，最终候选包的发布检查显示 `Check passed`，服务端返回 `202 Accepted, detail: Dry run completed successfully. No changes were made. The dry-run was made for package z2823253773-p/moontick version 0.1.0.`，但 CLI 仍打印 `Error: moon publish failed` 并退出 **255**。最终候选的完整原始输出保存在 [`raw/publish-dry-run.txt.gz`](raw/publish-dry-run.txt.gz)：压缩文件 SHA-256 `76631ee789037890d9486af7556341ce4730f12414f571227e3cba83ae7a0da1`，解压内容 SHA-256 `2235c31d1560facafe1fbd724f84df62b00aadaa2da66776b66b5b29173a5253`。压缩只用于保留编译器警告原始对齐空格且不影响 `git diff --check`。不能把服务端 202 与进程退出 255 合并写成“命令成功”。原因尚未确认。
- 官方 core 归档没有可用发行方 SHA-256 sidecar；CI 仍只记录单机观察哈希，Linux 侧为 `UNKNOWN_NOT_VERIFIED`。这不是完整供应链验证。
- 尚未正式 `moon publish`、未得到 Mooncakes 版本页、未从 registry 安装、未招募独立试用、未提交赛事报名或取得验收/季度资格回执。
