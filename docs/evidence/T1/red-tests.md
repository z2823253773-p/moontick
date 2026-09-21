# T1 证据：RED 阶段

日期：2026-09-21。工具链：隔离 `moon 0.1.20260920` / `moonc v0.10.14+7d59c7ec9`。

本文件记录**先失败**的行为测试。测试按 `docs/handoffs/T1_CLAUDE.md` 写好后，先对
无校验的占位实现运行，取得真实失败输出，再写实现。占位实现随后被替换，不留在提交里。

## 命令

```bash
moon test --target native
```

退出码 `2`。汇总：`Total tests: 11, passed: 1, failed: 10.`

## 逐字失败输出（节选，未改写）

```text
[moontick] test core/grid_test.mbt:21 ("step_ms = 0 is rejected") failed: core/grid_test.mbt:22:3-25:4@moontick FAILED: `"ACCEPTED" != "CONFIG_INVALID: step_ms must be greater than zero"`
diff:
-"ACCEPTED" +"CONFIG_INVALID: step_ms must be greater than zero"
[moontick] test core/grid_test.mbt:29 ("negative step_ms is rejected") failed: ... FAILED: `"ACCEPTED" != "CONFIG_INVALID: step_ms must be greater than zero"`
[moontick] test core/grid_test.mbt:37 ("end_ms equal to start_ms is rejected") failed: ... FAILED: `"ACCEPTED" != "CONFIG_INVALID: end_ms must be greater than start_ms"`
[moontick] test core/grid_test.mbt:45 ("end_ms before start_ms is rejected") failed: ... FAILED: `"ACCEPTED" != "CONFIG_INVALID: end_ms must be greater than start_ms"`
[moontick] test core/grid_test.mbt:53 ("a window that is not a whole number of steps is rejected") failed: ... FAILED: `"ACCEPTED" != "CONFIG_INVALID: end_ms - start_ms is not a whole number of step_ms intervals"`
[moontick] test core/grid_test.mbt:61 ("a window difference that overflows Int64 is rejected") failed: ... FAILED: `"ACCEPTED" != "CONFIG_INVALID: end_ms - start_ms does not fit in a signed 64-bit millisecond value"`
[moontick] test core/grid_test.mbt:75 ("an Int64-sized grid is accepted without floating point rounding") failed: ... FAILED: `0 != 4`
[moontick] test core/audit_test.mbt:20 ("grid=(0,60,15) times=[0,15,30,45] is full coverage and passes") failed: ... FAILED: `0 != 4`
[moontick] test core/audit_test.mbt:36 ("grid=(0,60,15) times=[] is entirely missing and fails") failed: ... FAILED: `0 != 4`
[moontick] test core/audit_test.mbt:48 ("grid=(0,60,15) times=[0,30,45] misses exactly one point") failed: ... FAILED: `0 != 3`
Total tests: 11, passed: 1, failed: 10.
```

## 说明

- 六个 `grid_test` 失败证明：占位实现**不拒绝**任何非法配置，五个 `CONFIG_INVALID`
  用例全部先红。
- 四个失败里三个是 handoff 规定的 T1 行为用例（全覆盖 / 空序列 / 缺一点），全部先红。
- 唯一先绿的是 `a whole-period window is accepted and counts exact points`：占位实现
  恰好对 `(0,60,15)`、`(-30,30,15)` 算出 4，属于巧合，不是通过证据。该用例在实现后
  仍保留，用于锁定合法路径。

由此进入实现阶段；实现后的同一命令输出见 `docs/evidence/T1/gates.md`。
