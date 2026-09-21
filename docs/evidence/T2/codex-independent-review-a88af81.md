# Codex 独立复核：T2 `a88af81`

验证对象：`a88af81bf7e9ff07698c63a293111532b022ba75`，父提交为
`e329b5a935dfc22cff616fbc5239bf857c6e654a`。在 detached worktree
`/private/tmp/moontick-t2-verify` 完成；HEAD 已核对为该 SHA，不在 Claude checkout
写入产品或 oracle。

## 实测结果

使用隔离 MoonBit `moonc v0.10.14+7d59c7ec9`：

| 命令 | 独立结果 |
|---|---:|
| `moon check --target native` | 退出 0；14 warnings / 0 errors |
| `moon test --target native` | 退出 0；52 passed / 0 failed |
| `moon test --target native -p z2823253773-p/moontick/core -v` | 退出 0；22 passed / 0 failed |
| `moon build --target native` | 退出 0 |
| 真实 `moontick.exe` 的 `python3 tests/cli/test_cli.py` | 退出 0；16 passed |

独立枚举 oracle 不导入产品代码，也不复用产品的排序/缺失区间算法。它逐个比较完整 JSON
和真实退出码：T2 七个固定分类矩阵、256 个固定 seed `20260921` 的随机小网格和一个
`detail_limit=1` 截断案例，共 **264** 例全通过。

相对 `754ff0e` 的产品目录差异只有 `core/audit_scope_test.mbt` 新增；没有产品实现变更。
因此 T2 的“现有实现通过新增精确覆盖、没有 RED”与独立观察一致。

## 结论与限制

没有发现需交回修复的最小反例。库层 `InvalidDetailLimit` / `TooManyRecords` 由 core
verbose 测试覆盖；CLI 回归仍基于真实编译产物。

本 worktree 构建的 debug 二进制 SHA-256 为
`cf84224e18a66b9d2a6fad4e878008a4a0a70dfc2f2697be84fafdf302ff75dc`，未与原 checkout
的 debug 产物逐字节相同；本记录不将不同 worktree 的 debug 构建说成可复现的相同二进制。

`git diff --check a88af81^ a88af81` 退出 2：`docs/evidence/T2/raw/check.txt` 保存的
原始警告输出含尾随对齐空格，`raw/cli-three-cases.txt` 有 EOF 空行。此项不涉及产品源码
或行为，保留为后续引入格式检查时需处理的文档卫生项。

Linux native、CI、完整 text 格式、发布、报名和真实用户接入均未运行。

## 验收决定（2026-09-21）

接受 `a88af81bf7e9ff07698c63a293111532b022ba75` 的 T2 本机技术范围。
决定前在该 SHA 的独立 worktree 再次实测：check 退出 0（14 warnings）、全仓
test 52/52、core test 22/22、build 退出 0、真实 CLI 16/16。七个指定矩阵、
256 个随机小网格及一个截断案例的独立 oracle 共 264 例一致；相对 T1 已接受的
产品 SHA 没有实现文件变更。上述限制仍适用，正式赛事验收和后续任务另计。
