# MoonBit 发行物只读探测：2026-09-21

范围：只读 HTTPS 获取 `version.json`、一字节 Range 响应头和很小的
`.sha256` sidecar；没有下载完整归档、运行安装脚本、创建工程或改动全局工具链。

## 结论

- 旧候选 `0.10.4+2cc641edf` 的 macOS 二进制 Range GET 返回 HTTP 403；这
  只说明该具体 URL 在本次请求时拒绝访问，不能推断版本不存在。
- 官方 `https://cli.moonbitlang.com/version.json` 本次返回 HTTP 206，JSON
  中的 `moonc` 为 `v0.10.14+7d59c7ec9 (2026-09-18)`。
- 这个精确版本的 macOS arm64、Linux x86_64 二进制和 core 归档，均在一字节
  Range GET 时返回 HTTP 206；不能使用 `latest` 作为 CI 固定值。
- 两个二进制归档有官方 `.tar.gz.sha256` sidecar；精确 core sidecar URL 返回
  HTTP 403。故版本固定和二进制归档完整性校验已可设计，但 core 的官方校验
  材料尚未取得，完整可重装/供应链验收仍是阻断项。

## 实测摘要

| 资源 | URL 版本 | HTTP | 内容范围/大小 | ETag 或 SHA-256 |
|---|---|---:|---|---|
| macOS archive | `0.10.14+7d59c7ec9` | 206 | `0-0/85223029` | ETag `ddb5fcfd8fee8f976d2ebcfaf0106c15-11`; SHA-256 `20967f9389ac54508899ee2fc051a3470d051452bac5818a9696ed4c144f3ec3` |
| Linux x86_64 archive | `0.10.14+7d59c7ec9` | 206 | `0-0/94206941` | ETag `b514d4133cfb9cec94d2d8e79d2b47b1-12`; SHA-256 `9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a` |
| core archive | `0.10.14+7d59c7ec9` | 206 | `0-0/1782652` | ETag `385be7a65bf49193b24115a34c9315fb`; `.tar.gz.sha256` is HTTP 403 |
| historical macOS archive | `0.10.4+2cc641edf` | 403 | unavailable | S3 `AccessDenied` XML |

The exact URLs use `%2B` for `+` in the version.

## Fixed-install protocol for a later authorized implementation round

1. Put `0.10.14+7d59c7ec9` in a versioned, reviewed CI variable; never use
   `latest`. Download the exact platform archive and its `.tar.gz.sha256`
   sidecar, then run `shasum -a 256 -c` before extraction.
2. Download the matching exact core URL into the same isolated temporary
   directory. Because no official core sidecar was available in this probe,
   record its locally calculated SHA-256 and provenance as an **observed
   bootstrap hash**, not as an official verification. Do not claim the
   supply-chain gate is complete without a publisher-provided core checksum
   or an equivalent official integrity mechanism.
3. Extract only into a disposable project-local/CI location; then assert
   `moonc -v` contains `0.10.14` and record `moon version --all`. Only after
   a minimal `moon.mod` / `moon.pkg` native check, build, and test are green
   may this be called an implementation baseline.

Sources: official `version.json`, `install/unix.sh`, exact artifact endpoints,
and the official download page's binary-verification section. These findings
are a network observation at the stated time, not a completed installation.
