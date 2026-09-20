# MoonTick Implementation Plan

> **For agentic workers:** 实现方使用 superpowers:executing-plans（若环境提供）逐任务执行；本项目已选择 Claude Code 实现、Codex 独立验证的接力方式。不存在该 skill 时按本文任务卡执行，不因工具缺失假装已调用。不要默认启动子代理群。

**Goal:** 交付可验收的 MoonBit 定频采样计划审计库与 CLI，并建立季度评选所需的使用、维护和复现证据。

**Architecture:** 无 I/O 的 core 按显式网格计算覆盖与问题；ticks 行适配层保留原始记录/行号；CLI 只处理参数、文件和退出；report 输出稳定的文本/JSON。季度批量层复用同一 core，不另写第二套审计逻辑。

**Tech Stack:** MoonBit native、GitHub Actions、Python 3（仅独立测试）、公开 Mooncakes 包。确切 Moon/moonc 和依赖版本在 T0 实测固定。

**Spec:** [02_SPEC.md](02_SPEC.md)。本计划是整体执行路线；尚无代码。以下命令中的产品文件/脚本是对应任务应创建的交付物，不声称现在可运行。

## Global Constraints

- 窗口 `[start_ms,end_ms)`；整数毫秒 Int64；正步长；正窗口且整周期；显式计划、不猜首尾。
- 覆盖只计不同有效网格点；原始顺序用于乱序；细节截断不能影响完整计数。
- 核心全部 MoonBit；Python 仅独立测试；产品不调用 Python。
- native 为 v0.1 唯一承诺后端。先验证 macOS 与 Linux，其他平台不能标支持而无实测。
- 输入上限 32 MiB、250,000 条、token 20 字节（不含换行）；detail_limit 默认 1000、范围 1..10000。
- 退出码：0 通过；1 有数据问题；2 参数/输入/资源错误；3 I/O；4 内部错误。
- JSON 时间、统计及网格索引为十进制字符串；行号/记录号为安全整数。
- 不在产品中逐点展开预期网格；不自动改输入；不制造用户/提交/测试/发布证据。
- 发布命名空间使用真实账户；公开和报名身份材料分开。以最新明确授权决定是否执行外部动作。

## Review Focus

1. 完全空的合法序列、窗口首尾缺失仍需发现：T1/T2/T5。
2. 跨 Int64 正负边界和 JSON 精度，不能溢出或丢失数字：T1/T2/T4/T5。
3. 空文件与空行必须区分；CRLF、结束换行与坏 token 定位准确：T3/T4/T5。
4. 重复、乱序、越界重叠，覆盖率不可由行数替代：T2/T5。
5. 巨大网格与细节截断不能造成卡死或假通过：T2/T4/T5。

## T0 / G0-R：修订后的可行性检查

**Owner:** Codex；你处理官方问题。当前工作为规划与调查，T1 尚未启动，产品仓库尚未创建。

**本次材料：**[修订决策](08_G0_REVISION.md)、[需求证据卡](09_USE_CASE_EVIDENCE.md)、[工具链核验](10_TOOLCHAIN_BASELINE.md)。已有固定版本的竞品核查不从零重做，新疑点再针对性验证。

- [x] 接收用户提供的三项目固定 commit 对照，采用“显式采样计划完整性核算”的有限定位；本次未重新运行竞品。
- [x] 首版改为 ticks；同步空输入、行号、资源限制、CLI、样例及提示词。
- [x] 找到两条公开的一手需求记录，以独立合成用例明确输入与期望；不是 MoonTick 接入证明。
- [x] 只读确认本机版本，读取官方安装脚本、探测候选发行物。
- [ ] 发行物固定未完成：候选历史版本四个 HEAD 请求均返回 403。原因未明，不能称下载可用或版本不存在。
- [ ] 允许进入 T1 后，先验证选定配置/编译器的最小工程；跨平台 CI 在 T5 真正运行后才标 PASS。
- [ ] 参赛负责人处理精确截止、季度选项、有效 commit 和人工申报等未决信息。

**当前结论：**范围和需求论证支持继续准备 T1；工具链重装可复现性仍未决。本轮未启动产品开发。下一执行方先处理版本固定，再跑最小闭环，不接入完整 CSV。

**建库步骤（实施时执行）：**检查独立目录 `/Users/henryz/Desktop/比赛/moontick` 无未知内容，创建仓库并复制本包到 `docs/planning/`；AGENTS/CLAUDE 放根目录、TASK_STATE 放 .ai。不能把父目录初始化为仓库。填写真实命名空间。

**证据迁移：**本包证据复制到产品 `docs/evidence/T0/`；未运行检查不得生成通过结论。

## T1 / G1：最小垂直闭环

**Owner:** Claude Code；Codex 根据下面固定样例审查。

**Files:** `moon.mod`、各包 `moon.pkg`；`core/types.mbt`、`core/grid.mbt`、`core/audit.mbt`；`cmd/moontick/main.mbt`；`report/json.mbt`；`tests/fixtures/`、`tests/golden/`；初始 README。

**接口：**按规格定义 Grid 和 make_grid；audit 输入时间数组与网格，输出完整报告类型。T1 先实现正常/空序列/一个缺失点；尚未实现的能力明确记录，不对外发布为完整 v0.1。

- [ ] 先读工具链证据，确定可重装版本或内容哈希固定方案；采用隔离环境，避免改动全局安装。验证新配置格式与 native 构建，再确定 CI 基线。
- [ ] 在 MoonBit 中冻结可编译公开类型和错误类型；生成 `.mbti`，与规格一一对应。拒绝把 Int64 转成 Double 做网格运算。
- [ ] 写三个先失败的行为测试，然后实现：

```text
grid=(0,60,15), times=[0,15,30,45] → expected=4, covered=4, missing=0, status=pass
grid=(0,60,15), times=[]           → expected=4, covered=0, missing=4, ranges=[[0,4]]
grid=(0,60,15), times=[0,30,45]    → expected=4, covered=3, missing=1, ranges=[[1,2]]
```

- [ ] 验证配置拒绝：step=0、step<0、end<=start、window=61/step=15、Int64 窗口差溢出。错误必须是 CONFIG_INVALID。
- [ ] 用合成无表头 ticks 文件跑通读取→审计→JSON→真实退出码。零字节文件是全缺失，不能报格式错误；T3 完成全部严格行输入契约。
- [ ] 执行并记录 `moon check --target native`、`moon test --target native`、`moon build --target native`；捕获失败到通过过程的关键证据，不保存海量重复日志。
- [ ] 提交真实变更，交付编译产物位置和运行方法，Codex 从该 SHA 复现三个用例。

**通过条件：**真实文件到真实进程闭环可用。若第一天仍未跑通，先解决工具链/结构问题，削减可选工作并重排参赛期。

## T2 / G2：核心审计与规模边界

**Files:** `core/audit.mbt`、`core/missing_ranges.mbt`、对应测试。

**接口：**完成 audit 的全部分类和计数；使用已冻结 Grid/AuditReport，不改变 T1 外部语义。

- [ ] 先将下表写为精确行为测试，保存原始数组顺序。
- [ ] 实现越界→离网格→有效点分类，原始相邻逆序判断、全部时间戳重复额外计数。
- [ ] 排序去重有效索引后计算缺失区间，不生成 N 个点；区间数、缺失总数、最长缺口独立维护。
- [ ] 再加资源、截断与大整数测试，执行 native 单元测试和核心接口检查。
- [ ] Codex 用后文独立枚举 oracle 检查小样本，提出最小不一致反例；Claude 修复后回归。

基准网格均为 `(0,60,15)`，区间用 `[起索引,止索引)`：

| 输入 times | 缺失 | 重复额外行 | 乱序行 | 离网格 | 越界 | 缺失区间 |
|---|---:|---:|---:|---:|---:|---|
| 0,15,15,45 | 1 | 1 | 0 | 0 | 0 | [2,3) |
| 30,0,15,45 | 0 | 0 | 1 | 0 | 0 | 无 |
| 0,16,30,45 | 1 | 0 | 0 | 1 | 0 | [1,2) |
| -15,0,15,30,45,60 | 0 | 0 | 0 | 0 | 2 | 无 |
| 15,30 | 2 | 0 | 0 | 0 | 0 | [0,1),[3,4) |
| 0,45 | 2 | 0 | 0 | 0 | 0 | [1,3) |
| 60,60,0 | 3 | 1 | 1 | 0 | 2 | [1,4) |

大整数与规模测试：

```text
grid=(9007199254740993,9007199254740997,1), times=[9007199254740993]
→ expected=4, covered=1, missing=3，JSON 保持逐位数字。

grid=(-30,30,15), times=[-30,-15,0,15]
→ pass；负数毫秒有效。

grid=(0,1000000000000,1), times=[0,999999999999]
→ missing=999999999998, ranges=[[1,999999999999]]。

grid=(0,10000,1), times=所有偶数索引, detail_limit=1
→ missing=5000；只显示第一段缺口；truncated=true；status=fail。
```

**通过条件：**计数/定位/半开区间与规范一致；大窗口不按窗口长度消耗内存；没有溢出、假通过或隐藏截断。

## T3 / G3：严格 ticks 输入与来源定位

**Files:** `ticks_input/parse.mbt`、`read.mbt`、`*_test.mbt`、`tests/fixtures/ticks/`。

**输入：**文件字节。**输出：**时间戳数组及 1-based 行号；字节/整数错误为 InputError。无表头；记录号等于物理行号。

- [ ] 先写合法空文件、LF/CRLF、末行无换行和定位用例，再完成读取及解析。
- [ ] 不隐式 trim，不跳过空行，不接收 BOM，不支持 CSV；资源限额在读取中执行。
- [ ] token 最多 20 字节；先查长度、再查格式与 Int64 范围。

```text
空字节 → []，后续核心报告全部缺失
0\n15\n → [0,15]，行号 [1,2]
0\r\n15 → [0,15]，行号 [1,2]
0\n\n → INPUT_INVALID，line=2
单独 LF / timestamp_ms / BOM / 引号 / 逗号 / 孤立 CR / 非 ASCII → INPUT_INVALID
空格 / 01 / +1 / -0 / 1e3 / 9223372036854775808 → INPUT_INVALID
-9223372036854775808 / 9223372036854775807 → 可解析；是否越界由计划判断
21 字节 token / 超 250000 条 / 超 32MiB → RESOURCE_LIMIT
```

- [ ] Codex 从 token 语法独立写解析样例，不能调用产品函数当真值。
- [ ] 整份拒绝坏输入，不发出部分成功报告；时间数组与行号数组等长。
- [ ] 用真实进程回归空文件全缺失、坏行定位与不存在文件的区别。

**通过条件：**合法空序列可核算；坏输入明确失败；计数与定位准确；读取有界。

## T4 / G4：CLI、报告、错误与确定性

**Files:** `cmd/moontick/args.mbt`、`main.mbt`；`report/json.mbt`、`text.mbt`；`tests/cli/test_cli.py`、`tests/golden/`。

**接口：**完整实现规格第 3/4 节命令、退出码、schema；操作系统效果只在 CLI 外层。

- [ ] 先实现真实进程测试，捕获 stdout/stderr/exit，不用 mock 函数返回值替代。
- [ ] 固定参数错误行为及字节稳定 JSON 排序；同一输入运行两次，stdout 字节相同。
- [ ] 生成格式错误、文件不存在、正常但有问题、正常通过四类结果；验证 code/status 与退出码对应。
- [ ] 每类详情超过限制后完整计数仍准确，truncated 按类别标记。
- [ ] help/version 无输入文件可运行；JSON 不泄露绝对路径和完整输入内容。

下面的测试代码可以作为 `tests/cli/test_cli.py` 的最小端到端起点，随后按上述用例扩展。`MOONTICK_BIN` 指向 T1 实际生成的绝对可执行路径，由 T4 记录，不猜产物位置：

```python
import json, os, subprocess, tempfile, unittest
from pathlib import Path

class CliContract(unittest.TestCase):
    def check_ticks(self, text):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "input.ticks"
            p.write_text(text, encoding="utf-8")
            args = [os.environ["MOONTICK_BIN"], "check", str(p),
                    "--start-ms", "0", "--end-ms", "60",
                    "--step-ms", "15", "--format", "json"]
            return subprocess.run(args, capture_output=True, text=True, timeout=10)

    def test_duplicate_does_not_fill_missing_slot(self):
        r = self.check_ticks("0\n15\n15\n45\n")
        self.assertEqual(r.returncode, 1, r.stderr)
        j = json.loads(r.stdout)
        self.assertEqual(j["schema"], "moontick.audit.v1")
        self.assertEqual(j["summary"]["covered_points"], "3")
        self.assertEqual(j["summary"]["missing_points"], "1")
        self.assertEqual(j["summary"]["duplicate_extra_records"], "1")
        self.assertEqual(j["missing_ranges"], [["2", "3"]])

    def test_clean_file_passes(self):
        r = self.check_ticks("0\n15\n30\n45\n")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(json.loads(r.stdout)["status"], "pass")

    def test_empty_file_is_fully_missing(self):
        r = self.check_ticks("")
        self.assertEqual(r.returncode, 1, r.stderr)
        j = json.loads(r.stdout)
        self.assertEqual(j["summary"]["missing_points"], "4")
        self.assertEqual(j["missing_ranges"], [["0", "4"]])

    def test_blank_line_is_input_error(self):
        r = self.check_ticks("0\n\n")
        self.assertEqual(r.returncode, 2, r.stderr)
        j = json.loads(r.stdout)
        self.assertEqual(j["code"], "INPUT_INVALID")
        self.assertEqual(j["line"], 2)

if __name__ == "__main__":
    unittest.main()
```

**通过条件：**上述过程与所有错误分类在编译产物上成立；Moon 包装器行为单独记录，文档不混用两个退出码。

## T5 / G5：独立验证、CI 与发布候选

**Owner:** Codex 写独立验证；Claude 实现 CI 和修复。使用顺序交接或不同 worktree。

**Files:** `tests/oracle/reference.py`、`test_differential.py`、`tests/cli/`、`.github/workflows/ci.yml`、`docs/evidence/T5/`。

- [ ] 用下面的枚举定义建立小窗口 oracle；不得导入产品代码/照搬排序缺口算法。
- [ ] 生成至少 1000 个可重放的小案例，固定 seed=20260920；N 限制 1..200，包含重复、原始顺序打乱、窗口外和离网格整数。比较所有计数和小样本完整缺失区间/记录定位，不只比较 status。
- [ ] 每个不一致记录 seed、具体输入、配置、产品 SHA 和输出，压缩为最小回归用例。
- [ ] 加变形检查：增加重复有效点不改变覆盖/缺失；平移所有时间及窗口后网格结果不变；重排输入不改变覆盖/重复，但允许乱序/行号变化。
- [ ] 巨大 N 只用解析期望值验证，oracle 不展开巨大网格；设置进程超时并记录实际耗时与内存环境。
- [ ] CI 在固定 Moon 工具链下运行 macOS/Linux native 的 check/build/test、CLI、独立比对和格式检查；远程没跑就标未验证。
- [ ] 改动影响公共接口时生成 `.mbti` 并检查差异。建立候选版审查报告，阻断正确性/数据错误/资源无界的问题全部修复。

```python
def reference_summary(times, start, end, step):
    assert step > 0 and end > start and (end - start) % step == 0
    assert (end - start) // step <= 200  # 只用于小窗口独立真值
    expected = set(range(start, end, step))
    observed = set(times)
    missing = expected - observed
    return {
        "input_records": str(len(times)),
        "expected_points": str(len(expected)),
        "covered_points": str(len(expected & observed)),
        "missing_points": str(len(missing)),
        "duplicate_extra_records": str(len(times) - len(observed)),
        "out_of_order_records": str(sum(b < a for a, b in zip(times, times[1:]))),
        "off_grid_records": str(sum(start <= t < end and (t-start) % step != 0
                                    for t in times)),
        "out_of_range_records": str(sum(t < start or t >= end for t in times)),
    }
```

oracle 的 longest_missing_run 和区间从枚举得到的 missing 索引序列累积相邻段；不要调用产品函数。通过 G2 的手工表先验证 oracle 自己没有错。

**通过条件：**零未解释差异、明确的真实 CI 结果、无阻断缺陷、所有产品主张对应测试。测试数量是执行目标，不是当前成绩。

## T6 / G6：月度交付、安装复现与申报验收

**Files:** `README.md`、`LICENSE`、`CHANGELOG.md`、`AI_USAGE.md`、`examples/{archive,buckets,synthetic}/`、`docs/release/v0.1.md`、`docs/evidence/T6/`。

- [ ] README 写清安装、版本、输入格式、五类问题、退出码、边界；三个演示都有正常/坏样例和可人工核算 expected。
- [ ] `AI_USAGE.md` 如实说明 Codex/Claude Code 的协助范围、人工决策和验证方式；不把工具生成的代码或测试称为纯手写，也不把 AI 使用本身作为质量证明。
- [ ] 选择并核对开源许可证、依赖/参考来源；核查包内容不含密钥、身份材料或其他项目文件。
- [ ] 本地执行 `moon publish --dry-run`，保存真实输出并检查包包含公共接口/必需文件。dry-run 不是已发布。
- [ ] 准备具体远程 repo、版本、许可证、发布内容和风险清单；取得所需明确授权后执行 push/publish，保存回执。若已在会话明确授权则不重复确认。
- [ ] 在仓库外干净消费者工程从 Mooncakes 安装实际版本，导入 core 跑正常/缺失两个用例；不能通过相对路径导入源码冒充发布包。
- [ ] 你根据事实清单人工写一页申报书；Codex 校对技术事实、三场景和边界，不替你生成可直接提交的 AI 申报正文。
- [ ] 你选择参与季度评选、提交资料、入群并保存正式回执；Codex 将报名、审核、月度验收、季度资格分别记录。

**通过条件：**技术候选版可复现；“月度通过”只在收到官方验收结果后成立。项目本地完成不能代替赛方认定。

## T7 / G7：季度可选增量——多序列计划审计

**开始条件：**v0.1 稳定，至少已收集一次试用或接入反馈，确认多序列确有需要。若官方日期提前，先保证证据与演示，推迟该增量。

**Files:** `batch/manifest.mbt`、`batch/audit.mbt`、`report/batch_json.mbt`、`cmd/moontick/args.mbt`、相应测试与集成示例。

**接口：**版本化 manifest 输入预期序列及各自 Grid；batch 层分组后调用既有 audit；结果以 `moontick.batch.v1` 包裹旧报告。开始前用 ADR 冻结具体字段/错误码和上限。

- [ ] 设计示例：manifest 声明 A、B 两台设备同为 `(0,60,15)`；批量输入只有 A 的四条正确记录（本阶段另行冻结输入格式，不默认完整 CSV）；B 报 missing=4，整体 fail。
- [ ] 重复 series_id、未知序列、非法单序列 Grid 报错，不能静默忽略；同一 timestamp 跨两个序列不互相算重复。
- [ ] 为 manifest 设最多 1000 序列、输入总记录沿用 250000；聚合细节另设总预算，不能每序列上限相乘导致无限膨胀。
- [ ] 保持单序列旧命令逐字节兼容；更改旧语义必须升级 schema 并提供迁移说明。
- [ ] 完成独立小样本批量 oracle/CLI 验证和完全缺席序列演示。

**通过条件：**缺席序列可发现，隔离与旧版兼容成立；新增价值来自实际需求，不为凑季度功能数。

## T8 / G8：季度候选版和展示证据

**Files:** `docs/evidence/quarter/`、`docs/release/quarter-candidate.md`、演示脚本和参赛事实清单。

- [ ] 按证据文档收集真实试用、独立安装、Issue 修复和可复现规模测量；未获得的证据写“未获得”。
- [ ] 对比竞品相同语义范围的行为，用不同功能包对比速度没有意义；不做不公平性能宣传。
- [ ] 固定候选 commit/tag、工具链、依赖、输入、输出校验值与结果位置；冻结功能至少留出 5 天（官方日期确认后调整）。
- [ ] 你独立完成 5 分钟和 10 分钟两版演示，现场改变一个输入触发缺失/重复，解释为什么结果成立。
- [ ] 核对季度材料、资格、截止和回执；把未确认状态显式列出。

**通过条件：**评委无需对话背景即可安装、运行、复核差异与贡献；你能解释关键行为。奖项由官方评选，不把内部 gate 当成获奖保证。

## 每任务通用循环

先写明确失败用例 → 实现最小行为 → 跑相关测试 → 记录证据并提交 → Codex 独立验证 → 修复或接受 → 更新 TASK_STATE。单元任务完成后不用每次重复全量跨平台验证；在有跨层改动和候选发布时做完整 gate。
