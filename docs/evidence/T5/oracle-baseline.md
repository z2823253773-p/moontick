# T5 独立差分基线（macOS native）

- 产品被测 SHA：`e35fbb2c44ca3c9b4bec69ed528cabb2e944b06c`，从独立 detached worktree `/private/tmp/moontick-t4-fix-verify` 的真实 native 二进制运行；二进制 SHA-256：`3c9683942f414743c0873aab8beec842e5bd03d5d933c916175ab50cf2860873`。
- oracle 实现提交：`4de792d86a3848d2f387d4dc774033edaa9b0f07`。`reference.py` 枚举小网格并用集合判定覆盖，不调用产品代码，也不复用产品的排序缺口算法。
- 环境：macOS Darwin 25.4.0 arm64；隔离 MoonBit 工具链 `0.10.14+7d59c7ec9`。系统内存容量查询被本机权限拒绝；本轮未取得峰值 RSS。
- 命令：`MOONTICK_BIN=/private/tmp/moontick-t4-fix-verify/_build/native/debug/build/cmd/moontick/moontick.exe python3 tests/oracle/test_differential.py`。
- 结果：退出 0；G2 手算表 7 行另加空输入 1 行先独立校验 oracle，再与产品比较；固定 `seed=20260920` 的 1000 个随机小网格（`N=1..200`）逐字段比较 JSON、各类详情、位置、截断标志和真实退出码；前 30 个随机案例另外检查重复、平移、重排三类变形关系，全部一致。
- 巨大网格：`N=10^12` 仅按解析期望验证两个已覆盖点与一个压缩缺口，不调用枚举 oracle；进程耗时约 0.002 秒，单次超时 10 秒。此为该机器该输入的观察值，不是性能承诺。

独立差分未发现需交回的最小反例。这不能证明所有输入或 Linux 平台正确。CI、Linux native、公开远程及发布仍未运行。

另现场运行 `moon fmt --check` 退出 255，列出 `moon.mod` 和若干既有 MoonBit 测试文件的格式差异；格式门槛当前 **FAIL**，不是 T4 产品行为反例。后续 CI 任务必须先整理并重新验证，不能把该门槛写成已通过。
