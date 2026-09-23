# MoonTick 五分钟演示

从公开仓库根目录演示；需要可用的 MoonBit native 工具链。本仓库的 CI 使用
`moonc v0.10.14+7d59c7ec9`。以下文件都是合成时间戳，单位为整数毫秒。

## 0–1 分钟：解释计划

MoonTick 由调用者明确给出半开窗口 `[start,end)` 和固定步长。它按计划核算应有
时间点，而不是从输入的首尾推测计划。指向 [README](../../README.md) 的输入契约：
ticks 文件无表头，每行一个整数时间戳。

```sh
moon build --target native
BIN=./_build/native/debug/build/cmd/moontick/moontick.exe
```

## 1–2 分钟：正常归档

```sh
"$BIN" check examples/archive/complete.ticks --start-ms 1723456800000 --end-ms 1723457100000 --step-ms 60000 --format json
```

五个计划时间点全部出现，`status=pass`，`covered_points=5`，退出码 0。

## 2–3 分钟：中间两分钟缺席

```sh
"$BIN" check examples/archive/missing-middle.ticks --start-ms 1723456800000 --end-ms 1723457100000 --step-ms 60000 --format json
```

预期 5 点、覆盖 3 点、缺失 2 点，`missing_ranges=[["2","4"]]`，退出码 1。
区间是网格索引 `[2,4)`，对应计划中的第 2、3 个时间点。该命令用于检查
**提取后的时间列**；MoonTick 不直接打开归档或读取价格。

## 3–4 分钟：重复不能补覆盖

```sh
"$BIN" check examples/synthetic/duplicate-and-missing.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

输入四行 `0,15,15,45`，计划也是四点 `0,15,30,45`。报告应为覆盖 3/4、
缺失区间 `[2,3)`、额外重复 1 条，退出码 1。解释为什么“文件行数等于计划点数”
不能证明完整。

## 4–5 分钟：让观众改一个输入

把 `examples/synthetic/complete.ticks` 与上面的坏例对比，或让观众手算
`[0,60)`、步长 15 的四个预期点。随后说明零字节 ticks 文件也会按“计划内全缺席”
处理。若现场需要展示文本格式，省略 `--format json`；通过/失败依据实际报告和
退出码，不依据显示百分比反推。

不要把演示称为生产接入或第三方试用。用例的原始数据、命令和期望值在
[examples/README.md](../../examples/README.md)。
