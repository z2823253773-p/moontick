# 0.1.1 候选独立复核与单点文案修复

日期：2026-09-23。复核起点为 `release/0.1.1-candidate` 的干净提交
`741ce756bc6d1525bdd714fd4bdee9cdb7edc1b3`，其中产品包固定于
`18f7cc3d43593dbdfe258f180240eaddccc539f3`。主工作树 `main` 保持
`44bbc6c4b777c6499135f135edeb9608576ef007`，未被修改。

## 判断与最小反例

首个候选的 CHANGELOG 在 `## 0.1.1 — candidate, 2026-09-23` 下仍写
“This is a release candidate only. Mooncakes publication and a formal
`v0.1.1` tag have not been performed.” 如果把该 ZIP 正式发布，此句会在包内
立即过时，重演 0.1.0 的 README 文案问题。首个候选因此**不接受为最终发布包**。

单点修复提交 `ed82086f613351b568521d1641a2f138d16a4450` 只更改
README 和 CHANGELOG：去掉会随发布失效的候选状态句，将安装说明写成
“version 0.1.1 的命令”，并移除依赖临时候选分支长期存在的 README 链接。
`moon.mod` 仍是 0.1.1；核心、CLI、公开 API、示例及 CI 均未改动。

## 包与行为复核

- 使用已有的隔离 MoonBit 工具链（本机缓存路径不写入公开证据），
  `moonc v0.10.14+7d59c7ec9`。`moon fmt --check`、native check/build
  均退出 0；check 为 14 warnings、0 errors；`moon test` 为 77/77。
  真正的 CLI 进程测试 42/42；独立 oracle 为手算 8、随机 1000、变形 30×3、
  大网格 `N=10^12`，退出 0。这是复核者现场运行，不只引用交接说明。
- 重新执行 `moon package --frozen` 退出 0，包内 check 通过。新的
  `z2823253773-p-moontick-0.1.1.zip` 为 **29,040 bytes / 29 个文件**，
  SHA-256 `40393815a8ae5f7f788955451e6a4cf0c907ae7b9f32e0a50c11aa94c7ed2fc0`。
  ZIP 完整性通过；与从 `v0.1.0` 重建的 29 文件 ZIP 对比，只有
  `README.md`、`CHANGELOG.md`、`moon.mod` 三项变化，其他 26 项逐字节相同。
  README 的两个相对链接 `examples/README.md`、`LICENSE` 均存在于包内；
  包中无 `docs/`、`tests/` 或 `*_test.mbt`。过时的“尚未发布”与“只是候选”
  句均不在新 ZIP 中。
- 从这个**修复后的 ZIP** 临时解包至仓库外新目录，native check/build
  均退出 0（各 6 warnings、0 errors）。真实 CLI 完整例为覆盖 4/4、
  退出 0；重复加缺失例为覆盖 3/4、退出 1；两者 stderr 均为空。
  这是本地归档复现，不是 Mooncakes 0.1.1 registry 安装或外部用户反馈。

## CI、限制与后续

最初候选 `18f7cc3` 的 [CI run 35813925913](https://github.com/z2823253773-p/moontick/actions/runs/35813925913)
和证据提交 `741ce75` 的 [run 35814133755](https://github.com/z2823253773-p/moontick/actions/runs/35814133755)
均由只读 GitHub 查询确认 macOS 15 与 Ubuntu 24.04 success。修复提交
`ed82086f613351b568521d1641a2f138d16a4450` 的
[CI run 35849740864](https://github.com/z2823253773-p/moontick/actions/runs/35849740864)
也已核对：macOS 15 和 Ubuntu 24.04 均为 success，且该 run 的 head SHA 与
修复提交一致。

交接的 0.1.1 dry-run 曾在本地 `Check passed` 后因 macOS
`system-configuration` NULL object panic 退出 255，且**没有服务端响应**。
复核者未再次运行正式或 dry-run publish；不能将本地 package 成功、旧干跑
服务端 202 或双平台 CI 解释为 0.1.1 已发布。官方 MoonBit core 发行方
checksum sidecar 仍不可用，供应链验证未完整。赛事申报、验收、季度资格亦未完成。

结论：修复后的 0.1.1 是**本地和双平台 CI 已通过的技术候选**。发布前还需将该分支
整合至主线、审查最终包并取得本次 0.1.1 正式发布授权；正式发布后再从
Mooncakes 注册表独立安装核验、保存回执与标签。不得把本地 ZIP 安装称为注册表安装。
