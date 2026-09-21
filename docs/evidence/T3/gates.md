# T3 门槛记录

日期：2026-09-21（北京时间闲时运行）。实现者：Claude Code。
仓库：`/Users/henryz/Desktop/比赛/moontick`，分支 `main`。
起点 HEAD：`41faf7fceaa5394cf45d7bb59cb6eed52a6f497d`（工作树启动时干净）。
原始输出：`docs/evidence/T3/raw/`。

命令逐字照抄任务卡。全程使用隔离工具链，未使用全局 `~/.moon`，未读取凭据。

```bash
export MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz
export PATH="$MOON_HOME/bin:$PATH"
moon version --all
moonc -v
```

工具链实测（`raw/toolchain.txt`）：`moon 0.1.20260920 (914d7da 2026-09-20)`、
`moonc v0.10.14+7d59c7ec9 (2026-09-18)`、`moonrun 0.1.20260920 (914d7da 2026-09-20)`，
均解析到隔离路径 `/private/tmp/moontick-moon-0.10.14-OS4LNz/bin/`。

## 定向测试（先跑包，再跑全仓）

```bash
moon test --target native -p z2823253773-p/moontick/ticks_input
moon test --target native -p z2823253773-p/moontick/ticks_input -v
```

退出码 0，`Total tests: 22, passed: 22, failed: 0.`，耗时 0.83 s。
逐条结果见 `raw/ticks-input-verbose.txt`：T1 的 12 个 + 本轮新增的 10 个，全部 `ok`。
新增 10 条的行号为 `parse_scope_test.mbt:120 / 132 / 152 / 167 / 183 / 236 / 264 / 304 / 340 / 360`。

## 完整 native 门槛

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon check --target native` | 0 | `14 warnings, 0 errors`（`raw/check.txt`） |
| `moon test --target native` | 0 | `Total tests: 62, passed: 62, failed: 0.`（`raw/test.txt`） |
| `moon build --target native` | 0 | `Finished. moon: no work to do`（`raw/build.txt`） |
| `python3 tests/cli/test_cli.py` | 0 | `Ran 17 tests ... OK`（`raw/cli.txt`） |

全仓测试数由 T2 的 52 增至 62（+10 个新增 MoonBit 测试）；进程级测试由 16 增至 17
（+1 个新增真实二进制用例）。两者都是本轮新增，无删除、无跳过、无"改为期望值使其变绿"。

## Warning 状态

`moon check` 为 **14 warnings / 0 errors**，与 T1、T2 记录的数量一致，本轮**未新增
warning**。既有 warning 类别为非阻断工具链提示：派生 `Eq`/`Debug` 的隐式方法提升
（`implicit_impl_as_method`）、主包 blackbox 测试的未来行为、未显式 import `env`、
未使用的 `escape_text` 等。未伪装为零警告，也未为消除警告而改动已冻结的产品代码。

## 真实二进制

```bash
export MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe
python3 tests/cli/test_cli.py
```

- 二进制 SHA-256：`b9e3e189602b3849d06a69555be6e16a548214ff1094059715f0094d37711975`
  （`raw/binary-sha256.txt`）。
- 该值与 T1 已验收产物、T2 复核所记录的**同值**，即本轮可观察产品产物**逐字节未变**。
- `moon build` 报 `no work to do`，从构建系统侧独立印证：本轮无任何产品源码变更，
  不存在"改了产品但碰巧测试仍过"的情况。

## 本轮新增的进程级用例

`tests/cli/test_cli.py::test_raw_bytes_are_rejected_verbatim_with_a_line_number`

既有 `check_ticks` 辅助函数用 `write_text(..., encoding="utf-8")` 写盘，**无法表达**
BOM 或非法序列。新增 `check_raw_ticks` 用 `write_bytes` 直接落盘四个用例：

| 盘上原始字节 | 期望退出码 | 期望 `code` | 期望 `line` |
|---|---:|---|---:|
| `EF BB BF 30 0A`（BOM 在第 1 行） | 2 | `INPUT_INVALID` | 1 |
| `30 0A EF BB BF 31 0A`（BOM 在第 2 行） | 2 | `INPUT_INVALID` | 2 |
| `30 0A FF 0A`（非法 UTF-8 在第 2 行） | 2 | `INPUT_INVALID` | 2 |
| `30 0A E4 B8 AD 0A`（非 ASCII 在第 2 行） | 2 | `INPUT_INVALID` | 2 |

这一步补的是**文件读取路径**：若 reader 把文件先解码成 `String`，这些输入会在到达
parser 之前就被改写或拒绝，测试便测不到真实路径。四例同时断言 `stderr == ""`，即
参数已解析成功后的输入错误走 stdout 的错误 JSON，符合 SPEC 3.2。

## 变异抽查（未改产品代码）

为排除"断言写弱导致假通过"，临时改动**测试期望值**并确认精确命中，随后全部还原。
详见 `precise-input-evidence.md` 的变异表；四处变异各自只命中对应用例，无一误伤。
还原后全部门槛重新跑绿（上表即为还原后的最终一次运行）。

> 说明：本次抽查**只改测试期望**，未触碰任何产品实现文件。产品目录
> `git diff --stat` 自始至终为空。

## 未测项（NOT_RUN）

- Linux native：本轮仅在 macOS arm64（Darwin 25.4.0）验证。
- CI：未配置、未运行。
- `--format text`：T4 范围。
- 发布（`moon publish`）、公开仓库、报名、验收回执：未执行，无授权。
- reader 入口字节上限：T1 已在真实 CLI 覆盖，本轮按任务卡只补 parser 入口。
- 跨平台物理行号等价性：未在其他平台核对。
