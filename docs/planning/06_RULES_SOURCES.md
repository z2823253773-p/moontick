# 规则、来源与未决事项

更新：2026-09-21。以下为原 v1 历史读取记录及用户提供的 G0。本轮官网文本抓取未获得正文，章程/表单未重读，规则当前有效性与日期冲突未独立重证；不替代最新官方确认。

## 1. 官方入口

- [赛事官网](https://moonbitlang.github.io/Hackathon2026/)
- [正式章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)
- [项目报名表](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)

## 2. 原 v1 记录的要求（当前细则待复核）

申报时需人工撰写一页 Markdown，说明项目价值、边界、实现路线，列至少三个使用场景和参考来源；公开仓库须有至少十个有效提交。AI 可辅助开发，参赛者须掌握成果。验收包括 MoonBit 主要实现、公开代码、可复现说明、测试、CI、开源许可及 Mooncakes 发布。支持单人或最多三人团队。

季度评选涉及完成度、生态贡献和工程质量；主要贡献者须为参赛者本人。表单有“新项目申报—参与季度评选”选项。选择它并保存确认，不能只依赖首页所说的自动纳入。上述要求来自正式章程及表单。[章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd) · [表单](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)

## 3. 已发现的冲突

| 项目 | 官网/表单 | 章程 | 执行方式 |
|---|---|---|---|
| 九月日期 | 官网：9/30 报名与验收 | 章程流程与时间表：9/24，部分标题注明 24 点 | 9/24 仅为内部检查点；9/30 为 G0 当日官网记载，精确截止/时区待确认 |
| 季度纳入 | 官网：新项目验收后纳入；表单允许选参与/不参与 | 章程同时有自动参与、择优展示及季度评选描述 | 明确选参与，询问是否需额外报名/材料，并保留资格确认 |
| 季度时间 | 官网：第一赛季度 8—10 月 | 章程时间表的具体评选时间/线下形式带未确定表述 | 10 月底只作内部里程碑，不宣称官方截止 |
| 远期奖励 | 官网宣传半年度/年度奖额 | 当前章程部分远期计划待通知 | 项目策略不以远期奖金保证为前提 |

本次没有发现公开、可直接使用的精确评分权重；不得编造“技术占 40%”一类规则。

## 4. 发给赛方的问题草稿

下面仅是你可自行发送的问题清单，本工具未代发：

1. 九月赛官网写 9 月 30 日，章程写 9 月 24 日，请确认项目申报、审核修改和最终验收分别何时截止？
2. 新项目选择参与季度评选并通过月度验收后，是否还需另交季度报名或更新材料？本季度材料截止、展示方式及评审安排何时公布？
3. 申报书当前通过哪个字段/入口提交，是否放仓库指定文件？有效提交的计数范围和审核方式是什么？
4. 拟做“显式采样计划的完整性核算”，相邻库已有时间间隔检查，我们会提供差异用例。这个范围是否符合新生态项目方向？
5. 若赶不上九月期，十月新项目是否仍可参与当前季度评选？请按届时最新安排确认。

状态均为 **未询问/未确认**。回复保存日期、渠道及必要原文；公开证据只放脱敏结论，身份/银行卡资料保存在你自己的安全位置。

## 5. 生态核查来源（原始初查与后续 G0 分开）

| 来源 | 当前能支持的判断 | 证据限制 |
|---|---|---|
| [Mooncakes](https://mooncakes.io/) | 当前包检索入口，支持包摘要搜索 | 搜索未命中不等于不存在 |
| [MoonSignalKit 0.3.0](https://mooncakes.io/docs/cn-wn/moonsignalkit%400.3.0) | 实际读取公共接口；TimestampMonitor 接收 max_gap，提供迟到/间隔观测 | 没做仓库全量实现审计，不把未列能力断定不存在 |
| [MoonVerity](https://mooncakes.io/docs/Wchwch777/moonverity) | 通用 CSV/JSONL 契约与质量检查方向已存在 | G0 继续核对与采样计划语义的重叠 |
| [MoonSplit](https://mooncakes.io/docs/AlexenderSokolov/moonsplit%400.1.1) | 分组划分与泄漏审计已存在 | 因重叠排除了该候选方向 |
| [MoonBit Ocean QC](https://mooncakes.io/docs/lwq443/moonbit-ocean-qc) | 领域时序 QC 含重复、间隔等能力 | G0 对照窗口首尾、全缺席、精确覆盖等行为 |

用户随后提供的 G0 已记录固定版本：MoonSignalKit 0.3.0 / b3bb29419e60b66c156e9d06d89311dc2445eb6b；MoonVerity 0.1.2 / a865a85510590a4410b87afe5034b27c8e792a04；Ocean QC 0.3.0 / 4e66c8ee0458bc6329a68c068919bb478a331823。G0 对照支持候选差异，本轮未重新执行这些项目。NyaCSV 定位能力不足也来自用户 G0；本轮网页读取失败，未独立验证，不据此宣称没有其他 CSV 库。

## 6. 工程资料与本机快照

- [Moon 命令说明](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html)
- [使用与发布包](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html)
- [测试语言文档](https://docs.moonbitlang.com/en/latest/language/tests.html)

原 v1 记录，且本轮再次只读执行 `moon version --all` 得到：

```text
moon 0.1.20260713 (75c7e1f 2026-07-13)
moonc v0.10.4+2cc641edf (2026-07-15)
moonrun 0.1.20260713 (75c7e1f 2026-07-13)
路径 ~/.moon/bin/
```

`moon publish --help` 显示本机支持 `--dry-run`。这些只是环境探测，**没有**执行项目检查、升级、注册或发布。工具链在 G0 选择并记录确切版本，CI 与本机用同一基线；不要直接写“latest”后忽略版本漂移。

`/Users/henryz/Desktop/比赛` 不是 Git 仓库；当前只新增独立规划目录。产品 repo 的命名空间、远程地址与发布账户尚未确定。


## 7. v1.1 增补证据

固定 commit 链接：[MoonSignalKit](https://github.com/cn-wn/MoonSignalKit/commit/b3bb29419e60b66c156e9d06d89311dc2445eb6b)、[MoonVerity](https://github.com/Wchwch777/MoonVerity/commit/a865a85510590a4410b87afe5034b27c8e792a04)、[Ocean QC](https://github.com/lwq443/moonbit-ocean-qc/commit/4e66c8ee0458bc6329a68c068919bb478a331823)。链接与结论来自用户 G0，本轮未重新执行项目。

[需求证据卡](09_USE_CASE_EVIDENCE.md) 与 [工具链核验](10_TOOLCHAIN_BASELINE.md) 记录本轮新增内容。两个来源场景是内部选题依据，不能替代章程可能要求的三个申报场景。历史版本四个 HEAD 均 403，工具链固定尚未完成。没有测试、报名、季度资格或发布通过记录。
