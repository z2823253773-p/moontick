# MoonTick 0.1.1 正式发布与独立消费者复现

日期：2026-09-23。用户明确同意正式发布 Mooncakes `z2823253773-p/moontick@0.1.1`。
公开 [`v0.1.1` 标签](https://github.com/z2823253773-p/moontick/tree/v0.1.1)
解引用至 `272580ed53cdbe8493b6547ee2721d9cdffc70e9`。该提交的
[GitHub Actions run 35850310805](https://github.com/z2823253773-p/moontick/actions/runs/35850310805)
已完成，`macos-15 / native` 与 `ubuntu-24.04 / native` 均为 success。

## 正式包与发布结果

- 隔离工具链的编译器为 `moonc v0.10.14+7d59c7ec9`。从固定主线重新执行
  `moon package --frozen` 退出 0，`Check passed`，14 warnings、0 errors；
  29 文件包 `z2823253773-p-moontick-0.1.1.zip` 的 SHA-256 为
  `40393815a8ae5f7f788955451e6a4cf0c907ae7b9f32e0a50c11aa94c7ed2fc0`，
  与发布前独立复核的候选归档一致。
- 用户授权后仅执行一次正式 `moon publish --frozen`：进程退出 **0**，
  包内检查 `Check passed`（6 warnings、0 errors），服务端返回 `Server status: 200 OK`。
  完整原始日志在本机私有临时目录保存，SHA-256 为
  `6d1c5231f7e38510b3dde5e05346338b2c59a587a152af0932b4f186afd848c2`；
  未将含本机路径的日志推送到公开仓库。
- [Mooncakes 精确版本页](https://mooncakes.io/docs/z2823253773-p/moontick@0.1.1)
  独立 HTTP 请求返回 **200**，页面含模块名、`0.1.1`、`MIT` 及精确安装命令。

## 仓库外消费者验证

在与产品仓库无工作区关联的新 MoonBit 模块中运行
`moon add z2823253773-p/moontick@0.1.1`，进程退出 **0**，输出包括
`Registry index updated successfully` 与 `Downloading z2823253773-p/moontick@0.1.1`。
消费者 `moon.mod` 固定该版本，`moon.pkg` 导入已安装的 `core` 包。
native `moon check` 退出 0（1 个测试专用导入未使用警告）；
native `moon test` **2/2 通过**，分别验证完整采样计划与一个缺失点。
从 registry 安装得到的 **29/29 文件**与本地候选 ZIP 对应成员逐字节一致。
这是开发者自己建立的独立消费者模块，不是外部用户试用反馈。

`v0.1.0` 既有标签和 Mooncakes 0.1.0 归档未改。官方 MoonBit core 归档的
发行方 SHA-256 sidecar 仍不可用，供应链验证并未完整。赛事申报、官方验收、
季度评选资格仍未取得回执；Mooncakes 发布不代表这些步骤完成。
