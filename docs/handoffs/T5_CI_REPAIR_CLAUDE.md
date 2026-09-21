# T5 CI 单点返修：GitHub Actions 矩阵上下文

请先读 `AGENTS.md`、`.ai/TASK_STATE.md`、`docs/evidence/T5/codex-independent-review-89b4e01.md`。起点是该返修任务卡提交后的干净 `main`；原 CI 被测 SHA 是 `89b4e01fcece1ba8264e6109254571253c45b063`。用户仍在北京时间闲时手动启动 Claude Code；工作日 09:00–12:00、14:00–18:00 不运行，不安排自动续跑。隔离 MoonBit 工具链路径与前轮相同，勿用全局安装或读凭据。

只修 `.github/workflows/ci.yml:52–57` 的四个 `${{ env.* }}` 矩阵表达式。GitHub 官方上下文表不允许 `env` 出现在 `jobs.<job_id>.strategy` 内。直接把已经固定且有来源记录的 SHA / core 观察值填为矩阵字面量最简单；不要改为 `latest`、删平台、放宽 checksum 或绕开失败门槛。其余代码和产品行为不改。

完成后检查 YAML、所有 GitHub 表达式所在位置的上下文合法性和各 `run:` 块 shell 语法；运行 `moon fmt --check`、native check/build/test、真实 CLI、独立 oracle、`moon info` 幂等检查。静态核验不能称为远程 CI 通过。记录修复前后矩阵片段、命令退出码和限制到 `docs/evidence/T5/`，更新 `.ai/TASK_STATE.md` 为 `REVIEW / Codex` 并提交固定修复 SHA。不要创建远程仓库、push、发布或报名；用户单独处理 GitHub 空仓与登录，Codex 之后再复核并连接远程。
