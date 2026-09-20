# 工具链核验

日期：2026-09-21。只读检查与 HTTP 探测；没有安装、升级、执行安装脚本或创建工程。

## 本机输出

```text
moon 0.1.20260713 (75c7e1f 2026-07-13)
moonc v0.10.4+2cc641edf (2026-07-15)
moonrun 0.1.20260713 (75c7e1f 2026-07-13)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

执行 moon version --all 和 moon new --help；[版本原始输出](evidence/G0-R/environment.txt)。原 G0 记录 native 帮助和环境，本轮未构建工程，全部项目构建/测试 NOT_RUN。feature flags 是格式支持线索，不能代替构建。

## 配置与安装脚本

[模块文档](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) 和 [包文档](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) 要求新项目使用 moon.mod / moon.pkg，旧 JSON 支持弃用。文档为当前版本，旧工具链不一定支持全部新字段。

从 [下载页](https://www.moonbitlang.com/download) 指向的 [Unix 脚本](https://cli.moonbitlang.com/install/unix.sh) 只读检查：

- positional VERSION 优先于 MOONBIT_INSTALL_VERSION，缺省 latest；
- + 转义为 %2B；
- 下载 binaries/VERSION/moonbit-TARGET.tar.gz 和 cores/core-VERSION.tar.gz；
- 列出 darwin-aarch64、linux-x86_64、linux-aarch64；
- 脚本会删除安装目录内旧库、使用主目录临时文件并可能改 shell 配置。本次未执行；后续采用隔离方案。

脚本 SHA256：`46495f8cdc0050f79b6cb195d66478d101cb3601d68506568fbe377fcdf2a9fe`。仅识别读取版本，不是二进制验证。

## 发行物探测

候选 0.10.4+2cc641edf：三个平台归档及匹配 core 的 HEAD 请求均返回 **HTTP 403**，见 [原始 JSON](evidence/G0-R/toolchain-head.json)。

版本参数语法已确认；历史发行物可获取性未确认。不能推断版本不存在，不能声称 CI 安装已验证。没有绕过访问限制。

### 2026-09-21 后续探测：当前官方发行物

原先的四次 HEAD/403 不能代表所有发行物。后续以只读一字节 Range GET 核验：

- 官方 `version.json` 本次报告 `moonc v0.10.14+7d59c7ec9 (2026-09-18)`；它是
  此次当前候选，不把 `latest` 当作固定值。
- 精确版 `0.10.14+7d59c7ec9` 的 macOS arm64、Linux x86_64 二进制和 core 归档
  返回 HTTP 206。二进制归档的官方 `.tar.gz.sha256` 可读取；macOS 为
  `20967f...f3ec3`，Linux x86_64 为 `922669...31b6a`。
- 精确 core `.tar.gz.sha256` 仍返回 HTTP 403。因此，二进制版本/哈希的固定方式
  已明确，但 core 没有可读取的官方校验材料；不能把这次可达性记成完整可重装或
  供应链验证通过。

完整命令、URL、响应大小、ETag 与固定流程见
[`release-probe-2026-09-21.md`](evidence/G0-R/release-probe-2026-09-21.md)。
后续获授权实施时，隔离下载精确版本、验证二进制 archive sidecar、为 core 记录
观察到的本地 SHA-256，并以实际 `moonc -v`、`moon version --all` 与最小 native
工程验证作为进入 T1 的依据。若官方 core 校验仍无法取得，保留跨平台发布/CI
供应链阻断项。

## 下一轮有限任务

1. 核实官方可获取的固定发行物，记录 URL、版本与 SHA256，不把 latest 直接当固定版本。
2. 若选择当前官方发行物，按官方校验说明验证归档，固定实际版本/哈希，在隔离位置运行。无法重装则保留发行/CI 阻断。
3. 最小工程验证 moon.mod / moon.pkg 和 native check/build/test；macOS 本地与 Linux CI 分别记证据。
4. 本地/CI 使用同一发行基线，各平台分别记录归档哈希；不要求跨平台二进制哈希相同。

负责人若允许先做本地 T1，可用当前工具链做最小原型，将重装可复现性作为后续明确阻断。本包未代作实施授权。
