# T1 证据索引

日期：2026-09-21。工具链：隔离 `moon 0.1.20260920` / `moonc v0.10.14+7d59c7ec9`。

| 文件 | 内容 |
|---|---|
| `int64-upper-bound.md` | `9223372036854775807` 被误拒的实测根因与最小修复 |
| `gates.md` | 三条门槛命令、真实产物三用例、错误路径、进程级测试 |
| `red-tests.md` | 上一会话记录的先失败行为测试（历史，未改写） |
| `blocked-toolchain-access.md` | 上一会话的路径权限阻断（历史观察，现已不成立） |
| `mooncakes-namespace.md` | 模块命名空间的确认过程 |

## 证据的边界

- `red-tests.md` 与 `blocked-toolchain-access.md` 由上一会话写下，保持原样未改写。
  后者描述的路径权限阻断在当前会话已不成立：本轮已能正常执行隔离工具链。两者并存
  会显得矛盾，按时间顺序阅读即可，前者已被本轮的 `gates.md` 取代。
- 本目录不记录任何未运行项为通过。NOT_RUN 清单见 `.ai/TASK_STATE.md`。

## 复现

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
moon version --all          # 应打印 moonc v0.10.14+7d59c7ec9
moon check --target native
moon test  --target native  # 应打印 Total tests: 41, passed: 41, failed: 0.
moon build --target native

export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

三用例也可手工复现：

```bash
$MOONTICK_BIN check tests/fixtures/full.ticks        --start-ms 0 --end-ms 60 --step-ms 15 --format json  # exit 0
$MOONTICK_BIN check tests/fixtures/empty.ticks       --start-ms 0 --end-ms 60 --step-ms 15 --format json  # exit 1
$MOONTICK_BIN check tests/fixtures/one_missing.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json  # exit 1
```
