# MoonTick 独立试用步骤

这份步骤用于让没有参与开发的人从公开仓库复现一个好例和一个坏例。请记录实际
操作与遇到的障碍；只有本人真正运行之后，才算独立试用证据。

1. 在自己的电脑上记录系统、CPU 架构和 `moon version --all` 输出。CI 已在
   macOS arm64 与 Linux x86_64 的 `moonc v0.10.14+7d59c7ec9` 运行通过；
   其他工具链或平台的结果请按实际记录，不预先标为通过。
2. 获取公开仓库，按 README 构建：

   ```sh
   git clone https://github.com/z2823253773-p/moontick.git
   cd moontick
   moon build --target native
   BIN=./_build/native/debug/build/cmd/moontick/moontick.exe
   ```

3. 分别运行：

   ```sh
   "$BIN" check examples/synthetic/complete.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
   "$BIN" check examples/synthetic/duplicate-and-missing.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
   ```

   第一个应通过：`covered_points=4`、`missing_points=0`、退出 0。
   第二个应失败：`covered_points=3`、`missing_points=1`、
   `duplicate_extra_records=1`、`missing_ranges=[["2","3"]]`、退出 1。
   这些计数位于 JSON 的 `summary` 对象中；缺失区间位于顶层。

4. 可选：在另一个全新 MoonBit 工程运行
   `moon add z2823253773-p/moontick@0.1.0`，确认包能从 Mooncakes 下载。
   仓库内的[安装复现记录](../evidence/T6/release-and-consumer.md)提供了
   公开 `core` API 的两个独立用例。不要使用本地相对路径代替 registry 包。

请把反馈集中在四件事：哪一步无法照做；实际退出码和关键输出；`[start,end)`、
毫秒单位和索引区间是否容易理解；你自己的固定采样工作流能否用现有 ticks 输入。
不需要提供私有原始数据。若发现错误，请附最小合成输入、命令、环境和预期结果；
若目前没有适用场景，也请直说。反馈经本人同意后再公开为 Issue 或引用。
