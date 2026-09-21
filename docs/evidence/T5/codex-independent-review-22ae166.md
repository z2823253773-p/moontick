# T5 CI 矩阵返修独立复核：本机候选接受，远程待运行

- CI 被测 SHA：`22ae166880d531a21ba2d28c6c0d312351f3b0ff`。
- 独立 detached worktree：`/private/tmp/moontick-t5-fix-review`，隔离 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`。
- 返修范围：相对 `89b4e01`，唯一运行配置改动是 `.github/workflows/ci.yml`；矩阵的二进制摘要与 core 观察值从不允许的 `${{ env.* }}` 改为固定字面量。两个平台、版本断言、sidecar 比对和全部测试步骤仍在。

| 独立门槛 | 结果 |
|---|---|
| `moon fmt --check` | 退出 0 |
| `moon check --target native` | 退出 0；14 warnings / 0 errors |
| `moon build --target native` | 退出 0 |
| `moon test --target native` | 77/77 |
| 真实二进制 CLI 测试 | 42/42 |
| 独立 oracle | 手算 8、固定随机 1000、变形 30×3 与大网格均一致 |
| `moon info` 后 `.mbti` diff | 无漂移 |
| `git diff --check 89b4e01 22ae166 -- .github/workflows/ci.yml` | 退出 0 |

独立解析矩阵确认两平台的 `archive_sha256` 和 `observed_core_sha256` 都是字面量。GitHub [上下文可用性表](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability)所禁止的矩阵 `env` 引用已消失，前轮 P1 的本地可审查修复成立。全提交范围的 `git diff --check` 因原样保存的编译器 warning 输出尾随对齐空格退出 2；这是证据文本格式问题，不影响工作流文件和行为门槛。

随后在主工作树整合公开 README 与 MIT 许可证，`moon.mod` 的 readme 路径改为 `README.md`；组合 HEAD 的 fmt、check、build、test 77/77、CLI 42/42、oracle 全部重跑通过。README 中的完整与缺失两个命令分别现场验证退出 0/1。该文档/包元数据提交不改变上述 CI 修复逻辑。

结论限于本机与静态审查。公开仓库已建立并连为 `origin`，但本记录写入时尚未 push；macOS/Linux 的 GitHub Actions 均 **NOT_RUN**。只有对应公开提交的实际 run URL 能关闭这项验证。core 官方校验 sidecar 仍不可得，发行方供应链证明不能声称完成。
