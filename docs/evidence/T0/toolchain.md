# T0 工具链隔离验证

日期：2026-09-21。此记录只证明本机临时隔离目录中的工具链与最小工程；不证明
Linux CI、发布、注册、外部安装或完整供应链验收。

## 安装范围与完整性

- 隔离位置：`/private/tmp/moontick-moon-0.10.14-OS4LNz`；未修改 `~/.moon`。
- 固定版本：`0.10.14+7d59c7ec9`。
- 官方 macOS arm64 二进制 archive sidecar 已校验：
  `20967f9389ac54508899ee2fc051a3470d051452bac5818a9696ed4c144f3ec3`。
- matching core archive 来源为官方精确 URL；观察到的本地 SHA-256：
  `6f18b8fdea18f85e628a75e4a1bd3977c5a5c9c6a836fd8824192b0e6bd91b14`。
  官方 core `.tar.gz.sha256` sidecar 在此前只读探测中仍为 HTTP 403，故该 hash
  不是发布方校验值，完整供应链/CI 发布门槛仍未通过。

## 实际版本输出

```text
moon 0.1.20260920 (914d7da 2026-09-20)
moonc v0.10.14+7d59c7ec9 (2026-09-18)
moonrun 0.1.20260920 (914d7da 2026-09-20)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

## 最小工程探测

使用隔离工具链的 `moon new` 产生 `moon.mod` 与 `moon.pkg` 格式的临时工程；其
native 命令结果为：

```text
moon check --target native  -> exit 0
moon build --target native  -> exit 0
moon test --target native   -> exit 0; Total tests: 0
```

探测工程因没有可用 Mooncakes 登录身份而使用工具默认的 `username/...` 占位命名
空间，未迁入 MoonTick。产品 T1 不能使用该占位名；等待参赛者提供真实 Mooncakes
模块用户名后，由 Claude Code 生成或写入实际 `moon.mod`。
