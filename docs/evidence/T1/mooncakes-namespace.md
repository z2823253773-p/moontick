# T1 证据：隔离 Mooncakes 登录与命名空间

日期：2026-09-21。此记录仅证明本地隔离工具链的登录及用户名回填；不代表发布、报名或
远程仓库操作。

## 登录边界

使用精确工具链目录 `/private/tmp/moontick-moon-0.10.14-OS4LNz` 启动 `moon login`，
由用户在浏览器完成 GitHub OAuth。CLI 成功输出“API token saved to
`/private/tmp/moontick-moon-0.10.14-OS4LNz/credentials.json`”。没有读取、复制、输出或
提交该凭据文件。

首次尝试在受限会话中于交换码前触发 macOS `system-configuration` 空对象 panic；在允许
macOS 网络配置访问的隔离会话重启后成功。这不影响已固定的 MoonBit 版本，也不构成任何
产品测试结果。

## 实际用户名核对

同一登录会话下，执行 `moon new` 创建仅位于 `/private/tmp` 的临时模块探针。CLI 输出：

```text
Created z2823253773-p/namespace-probe
```

生成的探针 `moon.mod` 包含：

```text
name = "z2823253773-p/namespace-probe"
```

因此产品模块名定为 `z2823253773-p/moontick`。T1 没有执行 `moon publish`、注册、报名、
远程推送或其他外部写操作。

## 命名空间变更后的本地复核

使用同一精确工具链，在当前未提交 T1 草稿上得到：

- `moon check --target native`：退出 0，4 个 deprecation warnings。
- `moon build --target native`：退出 0，4 个同类 warnings。
- `moon test --target native`：退出 255；测试二进制退出信号为 `SIGABRT`。

失败断言为 `ticks_input/parse_test.mbt:88` 的 Int64 边界用例；
`9223372036854775807` 实际被报为 `INPUT_INVALID at line 1`。这是已验证的 T1 修复起点，
不是通过结论，也未运行真实 CLI 三用例。
