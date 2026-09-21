# MoonTick 当前状态

日期：2026-09-21。T1 最小闭环已实现，等待 Codex 在明确 SHA 上独立复核。

- task_id: T1
- status: REVIEW
- active_owner: Codex
- implementation_authorized: YES（2026-09-21，范围仅 T1）
- objective: Claude Code 实现最小 core + ticks CLI；Codex 在明确 SHA 上独立复核
- repo_root: /Users/henryz/Desktop/比赛/moontick
- branch: main
- tested_commit: 见下方「本轮交接」的实现提交 SHA

## 本轮（2026-09-21，Claude Code）：实现与验证

模块名固定为 `z2823253773-p/moontick`。工具链为隔离
`/private/tmp/moontick-moon-0.10.14-OS4LNz`，`moonc v0.10.14+7d59c7ec9` 现场复核。
未使用全局 `~/.moon`，未读取凭据，未改动隔离工具链安装内容。

### 起点：保留 RED 断言，最小修复

上一会话草稿中 `ticks_input/parse_test.mbt:88` 的 Int64 端点断言先红（`moon test`
退出 255，SIGABRT）。该断言未被修改。根因经实测确定为：本版本 MoonBit 对两个等长
数字串的 `String` 比较不走字典序而是数值比较，导致
`"9223372036854775807" > "9223372036854775807"` 返回 `true`，任何 19 位值（含
`i64_max`）都被误判越界。修复为逐字节比较数字切片。详见
`docs/evidence/T1/int64-upper-bound.md`。

### 本轮新增

- `report/json.mbt`：`moontick.audit.v1` 与 `moontick.error.v1` 序列化；时间、统计
  与网格索引一律十进制字符串，`String` 字段经 JSON 转义。`try_render_json` 在位置
  数组长度与记录数不符时拒绝，由 CLI 映射为退出码 4，不伪装成数据问题。
- `cmd/moontick/args.mbt`、`main.mbt`：`check` 参数解析、文件读取、审计、输出与真实
  退出码（0/1/2/3/4）。参数解析失败只写 stderr、stdout 为空。`--format text` 在 T1
  未实现，明确返回退出码 2 并说明，不输出半成品报告。
- `report/json_test.mbt`、`cmd/moontick/args_test.mbt`、`tests/cli/test_cli.py`、
  `tests/fixtures/`：行为测试与进程级测试。
- `docs/evidence/T1/int64-upper-bound.md`、`docs/evidence/T1/gates.md`。

### 本轮审查发现并修复的草稿缺陷

- `ticks_input/read.mbt`：`max_input_bytes` 定义在 `parse.mbt` 中，`read.mbt` 从未
  导入；该标识符在 native 归零，使 `remaining <= 0` 恒为假，32 MiB 限额静默失效。
  改为让循环在读到上限后一字节时停止。
- `ticks_input/read.mbt`：`c_open` 的 flags 实参是未命名魔数 `0`。已核实 libc
  `O_RDONLY == 0`（见提交说明），提取为具名常量。
- `ticks_input/parse.mbt`：修复后 `slice_to_string` 成为死代码，已删除。

### 门槛结果（详见 `docs/evidence/T1/gates.md`）

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | 0 errors |
| `moon test --target native` | 0 | `Total tests: 41, passed: 41, failed: 0.` |
| `moon build --target native` | 0 | 0 errors |
| `python3 tests/cli/test_cli.py`（真实产物） | 0 | `Ran 16 tests ... OK` |

真实产物 `_build/native/debug/build/cmd/moontick/moontick.exe`
（sha256 `b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975`）
三用例：完整 → 退出 0 / `status=pass`；零字节 → 退出 1 / `missing=4` /
`missing_ranges=[["0","4"]]`；缺一点 → 退出 1 / `missing=1` /
`missing_ranges=[["1","2"]]`。三者 stderr 均为 0 字节。

## 未决与未测（NOT_RUN）

- **`ticks_input/probe_wbtest.mbt`**：本轮为定位根因而建的临时 whitebox 探针，内容
  已清空，**不属于交付物**，应从提交中排除并在后续清理。
- Linux native 未运行：本轮只在 macOS arm64 验证。
- 资源限额（32 MiB / 250000 条 / 21 字节 token）代码路径已实现，但本轮未构造真实
  超限输入触发。
- `--format text` 未实现（T4 范围）。
- main 包的 blackbox 测试触发工具链提示「未来版本将停止生成」；当前版本仍正常
  运行，但 `cmd/moontick/args_test.mbt` 的位置后续需要调整。
- 完整供应链/跨平台 CI 仍未确认；core 官方校验 sidecar 未取得。
- 远程地址与发布授权仍待定；本轮未执行 `moon publish` 或任何对外动作。

## 下一步

1. Codex 在下方实现提交 SHA 上独立复核：复现三用例、核对 `docs/evidence/T1/`
   的原始输出，并按 `04_TASK_PLAN.md` 的 T1 通过条件检查计数与半开区间语义。
2. 复核通过后清理 `ticks_input/probe_wbtest.mbt`。
3. T2 再展开完整分类与规模边界，不在 T1 语义上做增量。

## 本轮交接

- 目录：`/Users/henryz/Desktop/比赛/moontick`；分支：`main`
- 验证命令：
  ```bash
  export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
  moon check --target native && moon test --target native && moon build --target native
  export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
  python3 tests/cli/test_cli.py
  ```
- 证据：`docs/evidence/T1/int64-upper-bound.md`、`docs/evidence/T1/gates.md`
- 实现提交 SHA：见本文件所在提交本身（提交信息列出被测工件）。
