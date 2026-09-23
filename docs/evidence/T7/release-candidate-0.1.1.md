# MoonTick 0.1.1 候选整理与本机复现

日期：2026-09-23。基线：`44bbc6c4b777c6499135f135edeb9608576ef007`，
分支：`release/0.1.1-candidate`。这是文档与发布元数据候选，不是已发布版本。
没有改核心语义、公共 API 或功能范围。

## 版本与包内文案

- `moon.mod`、README 与 CHANGELOG 均以 0.1.1 为本候选版本；CHANGELOG 保留完整
  0.1.0 历史，说明旧归档仍不可变。本 README 明确 0.1.0 的 Mooncakes 发布事实，
  install 命令指向此候选对应的 `@0.1.1`。
- 包内 README 引用的规划、演示和证据文档使用公开 GitHub 链接；仅保留的相对链接
  `examples/README.md` 与 `LICENSE` 均存在于包内。`.moonignore` 排除 `docs/`，所以
  README 不使用包内 `docs/` 相对链接。
- 旧 0.1.0 源标签为 `v0.1.0`，仍指向原提交；此轮没有移动或重写标签，也没有声称
  已修改注册表中的 0.1.0 归档。

## 工具链与本机门槛

在新建隔离 worktree `[candidate worktree]` 执行，工具链位于
`MOON_HOME=[isolated toolchain root]`：
`moon 0.1.20260920`、`moonc v0.10.14+7d59c7ec9 (2026-09-18)`。

```sh
moon fmt --check                                  # exit 0
moon check --target native                        # exit 0, 14 warnings
moon build --target native                        # exit 0, 6 warnings
moon test --target native                         # exit 0, 77/77
MOONTICK_BIN="$PWD/_build/native/debug/build/cmd/moontick/moontick.exe" python3 tests/cli/test_cli.py
                                                   # exit 0, 42/42
MOONTICK_BIN="$PWD/_build/native/debug/build/cmd/moontick/moontick.exe" python3 tests/oracle/test_differential.py
                                                   # exit 0
moon info                                          # exit 0, 6 warnings
git diff --exit-code -- '*.mbti'                  # exit 0, no interface drift
```

本轮不清理这些既有工具链 warnings；完整原始输出见 `raw/`。独立 oracle 报告
手算样例 8 个、seed `20260920` 随机网格 1000 个、变形检查 30×3，以及 `N=10^12`
的大网格检查。

## 五分钟演示与真实进程结果

按 README 和 [`docs/demo/five-minute.md`](https://github.com/z2823253773-p/moontick/blob/main/docs/demo/five-minute.md)
运行项目编译产物：

- 正常 archive：5/5 覆盖，`status=pass`，进程退出 0。
- 缺失 archive：预期 5、覆盖 3、缺失 2，缺失网格索引 `[2,4)`，进程退出 1。
- 四行 `0,15,15,45`：预期 4、覆盖 3、缺失 1、额外重复 1，缺失索引 `[2,3)`，
  进程退出 1。重复行没有掩盖缺口。

每条真实命令、完整 JSON stdout、stderr 与退出码见 `raw/demo-cases.txt`；全部为合成数据。

## 拟发布包与仓库外解包

以固定 `v0.1.0` 标签在独立 worktree 重建 0.1.0 ZIP，SHA-256 与已发布候选证据中的
`2b6d65a6b3cc64927101d0bee40115543ca281c1d7b9f5b6dd01c9026b0eea4a` 一致。0.1.1
使用 `moon package --frozen` 生成：

- 29 个文件，ZIP 完整性检查通过，大小 29,165 bytes，SHA-256
  `fe174bb6a28708309c0b3163a87e541a3e5da8ac718c6735115c5d947f54c09e`。
- 与重建的 0.1.0 包逐成员比较：新增 0、删除 0、变化 3（`README.md`、
  `CHANGELOG.md`、`moon.mod`），其余 26 个成员字节一致。
- 完整文件清单和排除检查见 `raw/archive-manifest.txt`；无 `docs/`、`tests/` 或
  `*_test.mbt`。包内相对链接已核实存在。
- 从该 ZIP 解压至仓库外目录 `[external unpack directory]`；
  native check/build 退出 0。解包后的真实 CLI 正常例退出 0、故障例退出 1。

这是本地 ZIP 的仓库外解包复现，不是 Mooncakes 0.1.1 安装，也不是外部试用反馈。
未发布 0.1.1，因此没有使用候选版本做 registry consumer install。

## Dry run、CI 与尚未完成事项

最终候选的 `moon publish --dry-run --frozen` 在本地包检查 `Check passed` 后，
Moon CLI 的 macOS `system-configuration` 层因 NULL object panic，进程退出 **255**；
该次**没有收到服务端响应**。服务端状态与进程状态分别记录，不能称干跑成功。
0.1.0 的早期干跑曾收到服务端 **202 Accepted**、CLI 仍退出 **255**，历史记录见
[`T6/release-preflight.md`](../T6/release-preflight.md)。本轮没有运行正式 publish。

候选推送及 GitHub Actions 尚待完成；不得把本机 macOS 结果算作 Linux 或远程 CI。
官方 MoonBit core 校验材料仍缺，工具链供应链验证不完整。未发现需要 Claude Code
实现的产品问题，故没有创建 Claude 任务卡；若后续复核发现真实产品反例，再按最小
复现和明确任务卡交回用户。

提交的原始日志仅将机器本机绝对路径、工具链缓存路径与临时进程号替换为说明性占位符；完整未脱敏输出保留在执行机本地。关键原始输出：`raw/fmt-check.txt`、压缩保留 warning 空格的 `raw/check.txt.gz`、
`raw/build.txt.gz`、`raw/test.txt.gz`、`raw/cli-tests.txt`、`raw/oracle.txt`、
`raw/demo-cases.txt`、`raw/package-diff.txt`、`raw/archive-manifest.txt`、
`raw/unpacked-final-*.txt` 与 `raw/publish-dry-run-final.txt.gz`。
