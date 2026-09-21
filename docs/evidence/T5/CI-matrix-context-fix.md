# T5 CI 单点返修：矩阵 `env` 上下文（P1）

日期：2026-09-22。任务：T5 返修。状态图例：**PASS / FAIL / NOT_RUN / BLOCKED**。

> **状态依据更正（本轮现场发现）**：起草本文件时我沿用了上一轮的措辞"仓库无 remote"，
> 这是**陈旧的**。远程 `origin` 实际已在 `2026-09-22T00:28:29` 写入 `.git/config`，
> 早于本轮修复提交 `22ae166`（`00:30:18`）。逐条复核后改述为：**`origin` 已配置但为空**
> （`git ls-remote origin` 返回 0 个 ref，无分支有 upstream，**没有任何 push**）。
> 结论不变——Actions 从未运行，仍是 **NOT_RUN**——但**理由不同，必须按新依据表述**。
> 原始命令与输出：`raw/remote-ci.txt`。

## 1. 起点与返修 SHA

| 项目 | 值 |
|---|---|
| 起点 HEAD | `aa4902af1561c7d5f337d3085474d12f187db41b`（干净 `main`） |
| 被返修的原 CI SHA | `89b4e01fcece1ba8264e6109254571253c45b063` |
| 返修被测 SHA | `22ae166880d531a21ba2d28c6c0d312351f3b0ff`（CI 修复提交；本证据随后以文档提交补录，不改变被测 SHA） |
| 改动范围 | 仅 `.github/workflows/ci.yml`（+ 本证据与 `.ai/TASK_STATE.md`） |

产品代码、测试、oracle 期望、checksum 严格程度均未改动。

## 2. 缺陷与确认

原 `.github/workflows/ci.yml:52–57` 的四个矩阵属性写成 `${{ env.SHA256_* }}` /
`${{ env.OBSERVED_CORE_* }}`。矩阵定义位于 `jobs.<job_id>.strategy` 内，而
[GitHub 官方上下文可用性表](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts)
规定该位置只允许 `github, needs, vars, inputs`——**不含 `env`**。

本轮独立复核该规则（未仅依赖 Codex 结论）：官方文档的 `jobs.<job_id>.strategy`
一行确实只列出上述四个上下文。Codex 的 P1 成立。

这是**依据官方规则确认的配置阻断**，不是运行期日志观察到的失败：没有任何提交被
push，远程从未运行，因此没有对应的 Actions 错误日志。

## 3. 修复（最小改动）

把四个表达式替换为**字面量**，即已经固定且有来源记录的 SHA 与 core 观察值。
选择字面量而非 `vars` 的理由：本仓库尚无远程配置，`vars` 需要远程才存在；
字面量在文件内自证、可离线复核，且不引入任何新的远程依赖。

```diff
           - runner: macos-15
             arch: arm64
-            archive_sha256: ${{ env.SHA256_DARWIN_AARCH64 }}
-            observed_core_sha256: ${{ env.OBSERVED_CORE_SHA256_DARWIN }}
+            archive_sha256: "20967f9389ac54508899ee2fc051a3470d051452bac5818a9696ed4c144f3ec3"
+            observed_core_sha256: "6f18b8fdea18f85e628a75e4a1bd3977c5a5c9c6a836fd8824192b0e6bd91b14"
           - runner: ubuntu-24.04
             arch: x86_64
-            archive_sha256: ${{ env.SHA256_LINUX_X86_64 }}
-            observed_core_sha256: ${{ env.OBSERVED_CORE_SHA256_LINUX }}
+            archive_sha256: "9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a"
+            observed_core_sha256: "UNKNOWN_NOT_VERIFIED"
```

同时删除了只被矩阵使用的 `SHA256_*` / `OBSERVED_CORE_*` 工作流级环境变量（死引用），
并就地写明「为何用字面量而不是 `env.*`」与每个哈希的性质。

**保留未改**：runner 架构断言、发行方二进制 sidecar 比对、core 供应链限制说明、
`moonc -v` 精确版本断言、两个平台的全部 check/build/test/CLI/oracle 门槛。
**未使用 `latest`、未删平台、未放宽 checksum、未绕开失败门槛。**

矩阵修复前后全文：`raw/repair-matrix-before.txt`、`raw/repair-matrix-after.txt`。

## 4. 上下文合法性核验（本轮新增，非空跑）

YAML 解析器无法发现此类错误——合法 YAML 仍可能被 GitHub 拒绝。故本轮把官方
可用性表编码为逐位置检查：遍历解析后的工作流，记录每个标量的所在位置，比对其中
每个 `${{ }}` 表达式所用的上下文是否被该位置允许。

| 文件 | 结果 | 退出码 |
|---|---|---:|
| 修复前 `89b4e01` 的工作流 | **BAD**：`jobs.<job_id>.strategy` 使用 `env` | **1** |
| 修复后 `22ae166880d531a21ba2d28c6c0d312351f3b0ff` 的工作流 | 全部 OK，0 处非法 | **0** |

修复前能报错、修复后转绿，说明该检查不是空跑。原始输出：
`raw/repair-context-audit-before.txt`、`raw/repair-context-audit-after.txt`。

修复后全部表达式位置：

```text
OK  jobs.<job_id>.name      uses `matrix`   允许 github, inputs, matrix, needs, strategy, vars
OK  jobs.<job_id>.runs-on   uses `matrix`   允许 github, inputs, matrix, needs, strategy, vars
OK  jobs.<job_id>.steps.run uses `runner`   允许 env, github, inputs, job, matrix, needs, runner, secrets, steps, strategy, vars
OK  jobs.<job_id>.steps.run uses `matrix`   允许 env, github, inputs, job, matrix, needs, runner, secrets, steps, strategy, vars
```

其余 `MOONBIT_VERSION_ESCAPED` / `EXPECTED_MOONC` 为 `run:` 块内的普通 shell 变量，
不经 GitHub 表达式求值，`run` 位置允许 `env`，合法。

## 5. 其他静态核验（不是 CI 通过）

| 检查 | 结果 | 证据 |
|---|---|---|
| YAML 解析（Python `yaml` + Ruby `YAML`，两个独立解析器） | 均通过 | `raw/repair-workflow-static.txt` |
| 13 个 `run:` 块 `bash -n` | 0 语法错误 | `raw/repair-workflow-shell-syntax.txt` |

本机无 `actionlint` / `yamllint` / `shellcheck`，未安装（本轮未联网安装工具）。
**静态核验不能称为远程 CI 通过。**

## 6. 本机门槛回归（macOS arm64）

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `moon fmt --check` | 0 | **PASS** |
| `moon check --target native` | 0 | **PASS**（14 warnings / 0 errors） |
| `moon build --target native` | 0 | **PASS** |
| `moon test --target native` | 0 | **PASS**，77/77 |
| `MOONTICK_BIN=… python3 tests/cli/test_cli.py` | 0 | **PASS**，42/42 |
| `MOONTICK_BIN=… python3 tests/oracle/test_differential.py` | 0 | **PASS** |
| `moon info` 后 `git diff -- '*.mbti'` | 0 | 无接口漂移（幂等） |

工具链：隔离 `MOON_HOME=/private/tmp/moontick-moon-0.10.14-OS4LNz`，
`moonc v0.10.14+7d59c7ec9`（`raw/repair-toolchain.txt`）。
被测二进制 SHA-256 `99bc25ed…f28b`（`raw/repair-binary-sha256.txt`），与本轮产品代码
未变相符。原始输出：`raw/repair-*.txt`。

## 7. 状态

- （macOS arm64，本机）= **PASS**（本次返修回归）
- （Linux）= **NOT_RUN**（本机为 macOS，未下载 Linux 归档）
- （GitHub Actions，任一平台）= **NOT_RUN**（`origin` 已配置但**为空**，0 个 ref；
  没有任何提交被 push，未发布）
- 官方 core 校验仍无来源证明，**供应链阻断项保留**

必须等远程仓库建成、推送该 SHA 并取得对应 run URL 后，才能把任一平台标为 CI 通过；
`ubuntu-24.04` 的 Linux 结果尤其只能由真实 run 给出。

## 8. 限制

上下文检查编码的是官方可用性表的**当前**内容，若官方规则变更需同步更新。
矩阵字面量避免了对远程 `vars` 的依赖，但**写入在文件里的哈希仍需人工维护**：
工具链版本升级时必须同时改 `MOONBIT_VERSION_ESCAPED`、`EXPECTED_MOONC` 与两个
`archive_sha256`，否则版本断言会失败（这是刻意的——宁可失败，不要静默跑错版本）。
