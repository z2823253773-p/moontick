# T4 修复独立复核：接受（macOS native 范围）

- 被测实现：`e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c`
- 修复起点：`23d25dd`；首轮未接受实现：`6d9774519c2c9cb20376af7d79a32c0fea63732e`
- 复核方式：在 `/private/tmp/moontick-t4-fix-verify` 建立固定 SHA 的独立 detached worktree；使用隔离 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，现场核对 `moonc v0.10.14+7d59c7ec9`；未使用全局工具链或登录凭据。

## 独立门槛

| 检查 | 结果 |
|---|---|
| `moon check --target native` | 退出 0；14 warnings，0 errors |
| `moon test --target native` | 退出 0；77/77 |
| `moon test --target native -p z2823253773-p/moontick/report -v` | 退出 0；23/23 |
| `moon build --target native` | 退出 0 |
| 构建出的真实 `moontick.exe` 运行 `python3 tests/cli/test_cli.py` | 退出 0；42/42 |

独立 Python `Decimal` / `ROUND_HALF_UP` 参考值核对 262 个覆盖率案例（包括 `2/3`、`57/100`、`19999/20000` 与固定种子的 256 个随机小网格），文本百分比、PASS/FAIL 与退出码全部一致。关键值分别为 `66.67%`、`57.00%`，以及显示 `100.00%` 但仍有一个缺失点、FAIL、退出 1。通过判定来自精确覆盖结果，未从显示值反推。

缺失区间截断场景输出 `ranges shown: 1; missing points in total: 98`，分别陈述已显示的区间数和缺失点总数；没有虚构总区间数。措辞与首轮复核给出的示例不同，但满足同一语义要求，接受。

用首轮与修复后的真实编译二进制，对重复、空输入、缺失区间截断三个 JSON 用例逐一比较退出码、stdout 和 stderr，均逐字节相同。此比较只证明所选用例的 JSON 行为未变，不替代所有输入上的形式证明。

## 范围与限制

相对 `23d25dd`，产品变更仅在 `report/text.mbt` 与 `report/moon.pkg`；另有 `report/text_test.mbt`、`tests/cli/test_cli.py` 和新的截断文本 golden。`core/`、`ticks_input/`、`cmd/`、`report/json.mbt` 未改。百分比先求商和余数，再缩放余数并四舍五入；余数受最多 250000 条输入约束，避免对可能很大的预期点数先乘 10000。

`git diff --check 23d25dd e35fbb2` 因原样保存的编译器 warning 文本尾随空格及新增 golden 的末尾空行退出 2；这些是提交文本格式问题，未影响上述行为门槛。独立 worktree 的 debug 二进制 SHA-256 为 `3c9683942f414743c0873aab8beec842e5bd03d5d933c916175ab50cf2860873`，与实现者在另一 worktree 中记录的 SHA 不同，故不声称 debug 产物跨 worktree 逐字节可复现。

Linux native、CI、发布、报名和终端列对齐未在本轮验证。结论仅是固定实现 SHA 的 macOS native 技术验收，不代表赛事验收或发布完成。
