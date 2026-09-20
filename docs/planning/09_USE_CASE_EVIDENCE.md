# 两个有来源的需求场景

检索：2026-09-21。证据等级：**公开一手问题记录 + 官方语义文档 + 合成契约用例**。未联系作者、未接入 MoonTick、未运行上游系统。

## A：定频归档完整性检查

来源：[Binance public-data issue #483](https://github.com/binance/binance-public-data/issues/483)，作者 2026-07-29 报告一分钟归档缺行，提供时间段及校验过程，要求确认能否恢复。它证明真实需求被提出，不把作者统计数当作我们的实测。

语义：[官方 mark-price kline API](https://developers.binance.com/docs/derivatives/usds-margined-futures/market-data/rest-api/Mark-Price-Kline-Candlestick-Data)。使用显式 interval/window；调用方负责单位、边界与标的有效期间，不能把任意交易事件视作固定采样。

**接入位置：**下载/解压/时间列提取后，导入消费者前。上游保留顺序和重复，不补点；核心接收数组或 CLI ticks。

**计划依据：**调用方要求指定窗口每分钟一个桶；MoonTick 只说明与计划不符，不判定原因或恢复价格。

**合成复现，非原档摘录：**

```text
基准：2024-08-12 10:00:00 UTC 的 Unix 毫秒
窗口：[10:00,10:05)，step=60000
观测桶起点：10:00, 10:01, 10:04
expected=5, covered=3, missing=2
missing_ranges=[[2,4]], longest_missing_run=2
duplicate=0, disorder=0, off_grid=0, out_of_range=0
status=fail，exit=1
```

**输出决定：**定位 10:02—10:03 桶，调用方重查或记录缺失政策。恢复、插值和业务判断不在库内。

**替代与价值：**issue 作者已有领域核查方法，并非无人能解决；候选价值是把计划计数和边界做成轻量 MoonBit 组件。对方是否会采用尚未验证。

## B：聚合后消失的空桶

来源：[Flux issue #3428](https://github.com/influxdata/flux/issues/3428)，作者报告聚合后无数据日期没有预期空窗口。该历史问题已关闭，不宣称它是当前 bug。[aggregateWindow 文档](https://docs.influxdata.com/flux/v0/stdlib/universe/aggregatewindow/) 说明 selector 丢弃空表，默认输出时间取桶终点。

**接入位置：**固定窗口聚合结果导出后的交付检查。示例显式选择桶起点标记（timeSrc=_start），每 20 秒一个桶；不能把默认终点直接用于起点计划。

**合成复现，非真实 Flux 运行输出：**

```text
时间基准：相对毫秒
窗口：[0,60000)，step=20000
导出的桶起点：[0,40000]
expected=3, covered=2, missing=1
missing_ranges=[[1,2]], longest_missing_run=1
duplicate=0, disorder=0, off_grid=0, out_of_range=0
status=fail，exit=1
完全没有行：covered=0, missing=3, missing_ranges=[[0,3]]
```

**输出决定：**列出未产出桶，调用方暂缓导入或复查；若允许稀疏结果，就不应声明每桶必有记录。

**替代与边界：**数据库查询侧也能处理空桶。候选价值在于脱离数据库的导出/库调用边界核算，不把观测值 null 当成未出现，也不填值。

## 验收与限制

- [合成 JSON 用例](evidence/G0-R/use-case-fixtures.json) 固定毫秒输入与期望；不是生产输出。
- A 索引 0,1,4 缺 2,3；B 索引 0,2 缺 1。用集合枚举独立核算，后续才验证产品。
- 相邻包行为来自用户 G0，见 [来源](06_RULES_SOURCES.md)，本轮未重跑。
- 这些是用途证据，不是试用、接入承诺或独立成库必要性的最终证明。季度阶段需补真实反馈。
