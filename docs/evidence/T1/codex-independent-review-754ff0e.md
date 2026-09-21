# Codex 独立验收：T1 实现提交 `754ff0e`

日期：2026-09-21。验证对象严格为
`754ff0ea7eae10cc416f6207ce94277395ddb1f3`（`feat(t1): minimal core, ticks input,
JSON report and check CLI`），在独立 detached worktree
`/private/tmp/moontick-t1-verify` 完成。该 worktree 的 HEAD 已现场核对为该 SHA；不在
Claude Code 的 checkout 写入 oracle 或产品文件。

## 本地工具链与门槛

使用隔离 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`：

```text
moon 0.1.20260920 (914d7da 2026-09-20)
moonc v0.10.14+7d59c7ec9 (2026-09-18)
moonrun 0.1.20260920 (914d7da 2026-09-20)
```

| 命令 | 独立结果 |
|---|---:|
| `moon check --target native` | 退出 0 |
| `moon test --target native` | 退出 0；41 passed / 0 failed |
| `moon build --target native` | 退出 0 |
| `MOONTICK_BIN=.../moontick.exe python3 tests/cli/test_cli.py` | 退出 0；16 passed |

编译产物是实际 `_build/native/debug/build/cmd/moontick/moontick.exe`，不是 `moon run`
包装器；本次独立构建的 SHA-256 为
`1c36358005076a9616ebee8b7d4ca03ecc86641aa2e880f317ebaae03ac80131`。

## 独立 oracle 与恶劣输入

在验证 worktree 写入并运行（未导入产品模块、未复用产品排序/缺失区间算法）：

```text
MOONTICK_BIN=.../moontick.exe python3 tests/oracle/t1_independent_oracle.py
independent oracle: 519 cases passed (seed=20260921)

MOONTICK_BIN=.../moontick.exe python3 tests/oracle/t1_adversarial_cli.py
adversarial CLI: 12 focused checks passed
```

小网格 oracle 枚举预期网格并逐例比较完整 JSON：统计、缺失范围、重复/乱序/离网格/
越界详情及物理行号、截断标记、status 和真实退出码。专项目包括：零字节输入、重复不补
覆盖、Int64 最小/最大值、`N=10^12` 的大缺口、CRLF 后空白行 `line=2`、CONFIG/IO/usage
输出通道与退出码、重复运行逐字节确定性、21 字节 token、250001 条记录、32 MiB+1 字节。
全部符合 T1 契约；没有产生需交回修复的最小反例。

## 审查判断与限制

- `try_render_json` 位置数组长度不符映射内部错误/退出 4，符合规格第 6 节，不要求回退。
- `--format text` 仍明确拒绝，是 T1 既定范围外项，未作为完整 text 报告验收。
- 当前工具链保留 warnings：main 包 blackbox 测试的未来行为提示、`env` 未显式 import、
  `escape_text` 未使用及若干 derive 提示；本次不把它们描述为零 warning。
- Linux native、CI、发布、报名、真实用户接入和官方 core checksum sidecar 都未运行。

## 清理

用户明确授权删除主 checkout 的未追踪临时文件
`ticks_input/probe_wbtest.mbt`。删除前验证其仅含临时探针说明，删除后以 `git status --
short -- ticks_input/probe_wbtest.mbt` 确认不再列出。没有删除其他文件，也未创建提交。
