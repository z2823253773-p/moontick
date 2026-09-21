# T2 门槛结果

日期：2026-09-21（北京时间）。执行者：Claude Code。

- 起点基线 SHA：`e329b5a935dfc22cff616fbc5239bf857c6e654a`
- 已接受产品实现 SHA：`754ff0ea7eae10cc416f6207ce94277395ddb1f3`
- 隔离工具链：`MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，
  `moon 0.1.20260920 (914d7da 2026-09-20)`，`moonc v0.10.14+7d59c7ec9 (2026-09-18)`
  （原始输出：`raw/toolchain.txt`）。未使用全局 `~/.moon`；未读取、显示或复制
  `$MOON_HOME/credentials.json`；未改动隔离工具链安装内容。

## 命令与结果

命令与任务卡一致，逐字照抄。

| # | 命令 | 退出码 | 结果 | 原始输出 |
|---|---:|---|---|---|
| 1 | `moon check --target native` | 0 | `Finished. moon: ran 4 tasks, now up to date (14 warnings, 0 errors)` | `raw/check.txt` |
| 2 | `moon test --target native` | 0 | `Total tests: 52, passed: 52, failed: 0.` | `raw/test.txt` |
| 3 | `moon build --target native` | 0 | `Finished. moon: no work to do` | `raw/build.txt` |
| 4 | `python3 tests/cli/test_cli.py` | 0 | `Ran 16 tests in 0.040s` / `OK` | `raw/cli.txt` |
| 5 | `moon test --target native -p z2823253773-p/moontick/core -v` | 0 | `Total tests: 22, passed: 22, failed: 0.` | `raw/core-verbose.txt` |

测试计数变化：`moon test` 由 T1 的 41 增至 52（+11），与 `core/audit_scope_test.mbt`
新增的 11 个测试一一对应，无测试被删除或跳过。逐名清单见 `raw/core-verbose.txt`。

`raw/build.txt` 亦记录被测产物：

```
b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975  .../cmd/moontick/moontick.exe
```

该 SHA-256 与 `docs/evidence/T1/gates.md` 记录的 T1 实现产物**逐字节一致**，
且 `moon build` 报 `no work to do`——两条独立证据共同表明 T2 未改动任何产品代码，
被测二进制仍是 T1 已独立验收的那个产物。

## 未改动产品代码的核对

```
$ git diff --stat
（空）

$ git status --porcelain
?? core/audit_scope_test.mbt
?? docs/evidence/T2/
```

工作树相对 `e329b5a` 只有两个新增（未跟踪）路径：新增测试文件与 T2 证据目录。
`core/`、`ticks_input/`、`report/`、`cmd/` 中受版本控制的文件无任何修改，
`core/pkg.generated.mbti` 未重新生成，公开 schema 未变。

## 真实二进制的三用例回归

命令与输出：`raw/cli-three-cases.txt`。

| 输入 | 退出码 | stderr 字节数 | 关键结果 |
|---|---:|---:|---|
| `tests/fixtures/full.ticks` | 0 | 0 | `status=pass`，`missing_points=0` |
| `tests/fixtures/empty.ticks` | 1 | 0 | `status=fail`，`missing=4`，`missing_ranges=[["0","4"]]` |
| `tests/fixtures/one_missing.ticks` | 1 | 0 | `status=fail`，`missing=1`，`missing_ranges=[["1","2"]]` |

三者与 T1 记录的结果一致，stderr 均为 0 字节。

## 警告与限制（未伪装为零警告）

`moon check` 报告 14 warnings / 0 errors；`raw/check.txt` 中含 15 行 `Warning:`
（其中一行是汇总行）。标签分布：`[0001]`×1、`[0025]`×8、`[0071]`×1、`[0079]`×4。

这些是 T1 已记录的工具链非阻断警告（主包 blackbox 测试未来行为、未显式 import
`env`、未使用 `escape_text`、若干 derive 提示），T2 未新增也未消除。数量与 T1 记录
的 14 条一致。

未运行项：

- Linux native：本轮只在 macOS arm64 验证。
- CI、完整 text 格式、发布、报名：未授权，未运行。
- T1 已独立验证的昂贵输入（`N=10^12` 缺口、Int64 两端、32 MiB+1、21 字节 token）
  本轮未重复制造，理由见 `precise-contract-tests.md` 末节。
