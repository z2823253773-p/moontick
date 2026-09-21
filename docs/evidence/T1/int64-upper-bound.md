# T1 证据：`9223372036854775807` 被错误拒绝的根因与修复

日期：2026-09-21。工具链：隔离 `moon 0.1.20260920` / `moonc v0.10.14+7d59c7ec9`。

## 起点

上一会话遗留的未提交草稿中，`ticks_input/parse_test.mbt:88` 的
“the Int64 endpoints are accepted” 断言 `9223372036854775807` 应被接受，实际得到
`INPUT_INVALID at line 1`，测试子进程以 `SIGABRT` 退出，`moon test --target native`
退出码 255。该断言自始至终未被修改。

## 定位

草稿把上界判断写成字符串比较：

```moonbit
let magnitude = slice_to_string(node, position, end)
} else if magnitude > "9223372036854775807" {
  return None
}
```

按代码阅读，该分支本应放过恰好等于上界的值，因此不能凭推理下结论。用一个临时
whitebox 探针（跑完即删，未进入提交）向工具链直接提问，得到三条实测结果：

| 探针 | 实测输出 |
|---|---|
| `slice_to_string(utf8("9223372036854775807"), 0, 19)` | `"9223372036854775807"`（正常） |
| `parse_canonical(utf8("9223372036854775807"), 0, 19)` | `NONE` |
| `"9223372036854775807" > "9223372036854775807"` | **`true`** |

第三条是根因：当前 MoonBit 版本对**两个等长数字串**的 `String` 比较不走字典序，
而走数值比较，导致自反比较返回 `true`。任何 19 位数值（含 `i64_max`）都会被
`> bound` 判为越界。这与算术溢出无关，也没有 `Double` 参与。

## 修复

`compare_digits(bytes, start, end, bound)` 改为逐字节比较数字切片与上界，返回
-1/0/1，不再构造 `String`、不调用 `<`/`>`、不转换 `Double`。判界逻辑随之变为：

```moonbit
let bound = if negative { "9223372036854775808" } else { "9223372036854775807" }
let order = compare_digits(node, position, end, bound)
if order > 0 { return None }
if negative && order == 0 { return Some(i64_min) }
```

负数侧仍单独处理 `|i64_min|`：它比 `i64_max` 大 1，不能靠取负得到。

## 修复后实测

```bash
moon test --target native
```

退出码 `0`。汇总 `Total tests: 41, passed: 41, failed: 0.`（含 `parse_test.mbt:88`
的端点断言）。原 `slice_to_string` 修复后成为死代码，连带删除。

## 影响面与限制

- 只改了 `parse_canonical` 的 19 位判界路径与一个辅助函数；未改任何测试期望。
- 未验证：其他 MoonBit 版本是否同样如此。结论仅对本轮固定的
  `moonc v0.10.14+7d59c7ec9` 成立。
