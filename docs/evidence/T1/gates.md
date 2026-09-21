# T1 证据：交付门槛与真实产物三用例

日期：2026-09-21。工具链：隔离 `moon 0.1.20260920` / `moonc v0.10.14+7d59c7ec9`。

被测 commit SHA 见本目录 `manifest.md`。以下命令均在仓库根目录执行，未使用全局
`~/.moon`，未修改隔离工具链安装内容。

## 1. 三条门槛命令

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
moon check --target native
moon test  --target native
moon build --target native
```

| 命令 | 退出码 | 末尾输出 |
|---|---:|---|
| `moon check --target native` | 0 | `Finished. moon: ran 6 tasks, now up to date (14 warnings, 0 errors)` |
| `moon test --target native` | 0 | `Total tests: 41, passed: 41, failed: 0.` |
| `moon build --target native` | 0 | `Finished. moon: ran 5 tasks, now up to date (2 warnings, 0 errors)` |

`moonc` 版本现场复核：

```text
moon 0.1.20260920 (914d7da 2026-09-20)
moonc v0.10.14+7d59c7ec9 (2026-09-18)
moonrun 0.1.20260920 (914d7da 2026-09-20)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

### 警告

三条命令均为 0 error。警告有两类，都不是本轮引入的失败：

- `implicit_impl_as_method`（7 个）：来自草稿既有的 `derive(Eq, Debug)`；Codex 在本轮
  之前的记录中同样观察到同类警告。
- `Main package ... uses blackbox-only test inputs`：`cmd/moontick` 是 main 包，
  其 `args_test.mbt` 属于 blackbox 测试。选定的工具链版本仍会生成并运行它们，但提示
  未来版本会停止。这是 T1 的已知限制，记入未测项与后续任务。

## 2. 真实编译产物

```text
_build/native/debug/build/cmd/moontick/moontick.exe
sha256 b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975
```

以下三次运行直接执行该产物，不经 `moon run` 包装器。

命令模板：

```bash
moontick.exe check <FIXTURE> --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

### 2.1 完整覆盖

输入 `tests/fixtures/full.ticks`（sha256 `52373133489ddd0c47dac1689cbc4d7c849d0fa69b3181bcecba6f9361da9227`）

- 退出码 **0**，stderr 0 字节

```json
{"schema":"moontick.audit.v1","status":"pass","unit":"ms","grid":{"start_ms":"0","end_ms":"60","step_ms":"15"},"summary":{"input_records":"4","expected_points":"4","covered_points":"4","missing_points":"0","duplicate_extra_records":"0","out_of_order_records":"0","off_grid_records":"0","out_of_range_records":"0","longest_missing_run":"0"},"missing_ranges":[],"duplicates":[],"out_of_order":[],"off_grid":[],"out_of_range":[],"details_truncated":{"missing_ranges":false,"duplicates":false,"out_of_order":false,"off_grid":false,"out_of_range":false}}
```

### 2.2 空文件（零字节）

输入 `tests/fixtures/empty.ticks`（sha256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`）

- 退出码 **1**，stderr 0 字节
- 零字节是**合法空序列**，不是格式错误：`status=fail`、全窗口缺失

```json
{"schema":"moontick.audit.v1","status":"fail","unit":"ms","grid":{"start_ms":"0","end_ms":"60","step_ms":"15"},"summary":{"input_records":"0","expected_points":"4","covered_points":"0","missing_points":"4","duplicate_extra_records":"0","out_of_order_records":"0","off_grid_records":"0","out_of_range_records":"0","longest_missing_run":"4"},"missing_ranges":[["0","4"]],"duplicates":[],"out_of_order":[],"off_grid":[],"out_of_range":[],"details_truncated":{"missing_ranges":false,"duplicates":false,"out_of_order":false,"off_grid":false,"out_of_range":false}}
```

### 2.3 缺一点

输入 `tests/fixtures/one_missing.ticks`（sha256 `f95d3e4e1005367096c6ae36c1fb34c938ddbed9af568219629f0160f86eac57`）

- 退出码 **1**，stderr 0 字节

```json
{"schema":"moontick.audit.v1","status":"fail","unit":"ms","grid":{"start_ms":"0","end_ms":"60","step_ms":"15"},"summary":{"input_records":"3","expected_points":"4","covered_points":"3","missing_points":"1","duplicate_extra_records":"0","out_of_order_records":"0","off_grid_records":"0","out_of_range_records":"0","longest_missing_run":"1"},"missing_ranges":[["1","2"]],"duplicates":[],"out_of_order":[],"off_grid":[],"out_of_range":[],"details_truncated":{"missing_ranges":false,"duplicates":false,"out_of_order":false,"off_grid":false,"out_of_range":false}}
```

## 3. 规格示例的逐字段复核

SPEC 第 4 节给出的示例（窗口 `[0,75000)`、步长 15000、五行
`0,15000,15000,45000,62000`）在本产物上的输出与其字段逐项一致：`covered_points=3`、
`missing_points=2`、`duplicate_extra_records=1`、`off_grid_records=1`、
`missing_ranges=[["2","3"],["4","5"]]`、`duplicates` 为第 3 行、`off_grid` 为第 5 行。

## 4. 其他已验证行为

| 场景 | 退出码 | stdout |
|---|---:|---|
| `0\n\n15\n` 空白行 | 2 | `moontick.error.v1`，`code=INPUT_INVALID`，`line=2` |
| `0\n15\nbad\n30\n` 坏 token | 2 | `INPUT_INVALID`，`line=3` |
| `0\r1\n` 孤立 CR | 2 | `INPUT_INVALID` |
| 文件不存在 | 3 | `moontick.error.v1`，`code=IO_ERROR`，不含绝对路径 |
| `--step-ms 0` | 2 | `CONFIG_INVALID` |
| `--end-ms 61 --step-ms 15` | 2 | `CONFIG_INVALID` |
| `--help` / `--version` | 0 | 不读取输入文件 |
| 参数解析失败 | 2 | **stdout 为空**，诊断只写 stderr |

确定性：同一输入连续运行两次，stdout 逐字节相同（`cmp` 无差异）。

## 5. 进程级测试

```bash
MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \
  python3 tests/cli/test_cli.py
```

退出码 **0**，`Ran 16 tests ... OK`。该脚本只调用真实二进制并断言 stdout /
stderr / 退出码；它是测试工具，不是产品依赖（产品运行不调用 Python）。

## 6. 未测项（NOT_RUN）

- Linux native：本轮只在 macOS arm64 运行。
- 32 MiB / 250000 条 / 21 字节 token 的实际资源限额触发：代码路径已实现，但本轮
  未构造真实超限文件。
- `--format text`：T1 未实现，返回退出码 2 并说明原因。
- 隔离工具链官方 core sidecar 校验仍未取得（见 `docs/evidence/T0/toolchain.md`）。
