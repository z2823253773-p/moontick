# T5 CI 候选独立复核：REVISE

- 固定被测 SHA：`89b4e01fcece1ba8264e6109254571253c45b063`。
- 独立 checkout：`/private/tmp/moontick-t5-review`，detached HEAD；使用隔离 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`。
- 结论：macOS native 本机门槛通过，生成接口文件幂等；工作流在 GitHub Actions 展开前存在一处 P1 上下文错误。远程 CI 与 Linux 均仍为 **NOT_RUN**，故 T5 CI 候选暂不接受。

| 独立检查 | 结果 |
|---|---|
| `moon fmt --check` | 退出 0 |
| `moon check --target native` | 退出 0；14 warnings / 0 errors |
| `moon build --target native` | 退出 0 |
| `moon test --target native` | 77/77 |
| 真实二进制 `python3 tests/cli/test_cli.py` | 42/42 |
| 同一二进制 `python3 tests/oracle/test_differential.py` | 手算 8、随机 1000、变形 30×3、巨大 N 均通过 |
| `moon info && git diff --exit-code -- '*.mbti'` | 退出 0；无生成接口漂移 |
| `git diff --check 3813d56 89b4e01` | 退出 0 |

## P1：矩阵配置使用不可用的 `env` 上下文

位置：`.github/workflows/ci.yml:52–57`。四个矩阵属性以 `${{ env.SHA256_... }}` / `${{ env.OBSERVED_CORE_... }}` 取工作流环境变量。GitHub 官方[上下文可用性表](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability)规定 `jobs.<job_id>.strategy` 只允许 `github, needs, vars, inputs`，不包含 `env`；矩阵定义位于 `strategy` 内。因此两种 YAML 解析器和 `bash -n` 虽通过，也不能证明 GitHub 会接受这些表达式。这是依据官方规则推断的阻断项，**尚无远程运行错误日志**。

最小修复：把矩阵中的两个二进制 SHA 和 core 观察值改成字面量，或改用在该位置可用且已配置的 `vars`；当前仓库没有远程配置，因此字面量更可复现。保留现有 runner 架构断言、发行方二进制 sidecar 比对、core 供应链限制和两个平台的全部门槛。修复后做静态上下文审查、格式/本机回归；交新的固定 SHA。实际 GitHub Actions 结果只能在公开仓库推送后的 run URL 上确认。

## 其他边界

格式提交主要是机械格式变化；本机产品门槛无回归。`report/pkg.generated.mbti` 只新增与当前源码相符的三个公开函数，`moon info` 重跑无差异。

[GitHub 托管 runner 表](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)当前列出 `macos-15` 为 arm64、`ubuntu-24.04` 为 x64，标签选择本身无需返修；运行时架构断言仍应保留。core 没有发行方校验值，现有哈希和版本检查不能证明该归档的发行方完整性。仓库无 remote，不能把本机通过写成 GitHub Actions 或 Linux 通过。
