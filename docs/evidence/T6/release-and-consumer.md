# MoonTick 0.1.0 发布与独立消费者复现

日期：2026-09-22。用户明确批准 Mooncakes `z2823253773-p/moontick` 版本
`0.1.0` 正式发布，并知悉此前干跑 CLI 退出 255 以及官方 core 校验材料缺失。
发布源提交为 `30ea5ec64fc5000c84b7aa526de0d3a7e1ea97cd`，
公开 [`v0.1.0` 标签](https://github.com/z2823253773-p/moontick/tree/v0.1.0)
解引用后正好指向该提交；候选 ZIP 为 29 文件，SHA-256
`2b6d65a6b3cc64927101d0bee40115543ca281c1d7b9f5b6dd01c9026b0eea4a`。

## 正式发布

- 隔离工具链 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，`moonc v0.10.14+7d59c7ec9`。
- 仅执行一次正式 `moon publish --frozen`：进程退出 **0**，包内校验 `Check passed`（6 warnings，0 errors），服务端返回 `Server status: 200 OK`。原始输出见 [`raw/publish-0.1.0.txt.gz`](raw/publish-0.1.0.txt.gz)；压缩文件 SHA-256 `245273b761a8f262f5d48f0ff579600cdd5f10ebd685d40b5843b0c988ce18da`，原始文本 SHA-256 `a483aecf802e17964aea8ae5d79673017c5a74e2509b9882cd210621b0dc41a6`。
- [Mooncakes 精确版本页](https://mooncakes.io/docs/z2823253773-p/moontick@0.1.0) 经独立 HTTP 请求返回 **200**；页面可见 `z2823253773-p/moontick`、`0.1.0`、`MIT`、公开仓库地址及安装命令 `moon add z2823253773-p/moontick@0.1.0`。这是注册表可见性证据，不依赖 CLI 的成功消息。

## 仓库外安装和公开 API

在 `/private/tmp/moontick-consumer-v0-1-0-20260922` 创建与产品仓库无工作区关联的新 MoonBit 模块 `ci-consumer/moontick-consumer`；不使用相对路径或本地依赖。初次受限网络调用无法更新 registry index，联网重试 `moon add z2823253773-p/moontick@0.1.0` 退出 **0**，输出 `Registry index updated successfully`、`Downloading z2823253773-p/moontick@0.1.0`。消费者的 `moon.mod` 固定该版本，`moon.pkg` 导入 `"z2823253773-p/moontick/core"`。

其黑盒测试直接使用安装得到的公开 API：

```moonbit
///|
test "installed complete plan" {
  let grid = @core.make_grid(0L, 60L, 15L).unwrap()
  let report = @core.audit([0L, 15L, 30L, 45L], grid, 1000).unwrap()
  assert_true(report.passed)
  assert_eq(report.covered_points, 4L)
  assert_eq(report.missing_points, 0L)
}

///|
test "installed missing point" {
  let grid = @core.make_grid(0L, 60L, 15L).unwrap()
  let report = @core.audit([0L, 30L, 45L], grid, 1000).unwrap()
  assert_false(report.passed)
  assert_eq(report.missing_ranges, [(1L, 2L)])
}
```

隔离工具链的 `moon info`、`moon fmt` 后，native `moon check` 退出 **0**、
`moon test` 为 **2/2**。此外，消费者 `.mooncakes/z2823253773-p/moontick/`
下的 **29/29 文件**与本地发布 ZIP 对应成员逐字节一致，无缺失或不一致。
这是**开发者自己创建的独立消费者工程复现**，不能冒充外部用户反馈。

## 已知文案与未完成事项

已上传的 0.1.0 README 在发布前写成，仍有“no Mooncakes release ... yet”旧句。
发布后已更正 GitHub 主分支 README 和 CHANGELOG；注册表 0.1.0 页面仍展示归档中的
旧文案，不能称之为已修复注册表内容。后续若需修正注册表文案，应在新版本处理。

官方 core 归档仍无可用发行方 sidecar；没有第三方试用记录。赛事报名、官方验收与
季度评选资格均未取得回执；这些状态独立于 Mooncakes 发布。
