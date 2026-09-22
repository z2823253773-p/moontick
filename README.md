# MoonTick

MoonTick audits a **declared fixed sampling plan** against observed integer-millisecond timestamps. It reports exact grid coverage, compresses missing points into index ranges, and identifies duplicates, out-of-order records, off-grid timestamps, and out-of-range timestamps. An empty input is a valid observation of a completely missing plan.

MoonTick is a MoonBit library and native CLI. [Version 0.1.0 is published on Mooncakes](https://mooncakes.io/docs/z2823253773-p/moontick@0.1.0); competition acceptance has not been claimed.

To use the library from a separate MoonBit project, run `moon add z2823253773-p/moontick@0.1.0`, add `"z2823253773-p/moontick/core"` to that project's `moon.pkg` imports, then call `@core.make_grid` and `@core.audit`. An [independent install check](docs/evidence/T6/release-and-consumer.md) built a fresh project against the registry copy and ran complete and missing-point cases.

## Build and try it

Use the pinned development compiler `moonc v0.10.14+7d59c7ec9`. From this repository:

```sh
moon check --target native
moon test --target native
moon build --target native
./_build/native/debug/build/cmd/moontick/moontick.exe check \
  examples/synthetic/complete.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

The last command audits the half-open window `[0,60)` at 15 ms intervals. Its four expected timestamps are `0,15,30,45`; the example covers all four and exits `0`. Replace `complete.ticks` with `duplicate-and-missing.ticks` to see a duplicate that cannot repair a missing point; that audit exits `1`. Omit `--format json` for the default text report.

[Three runnable synthetic examples](examples/README.md) cover minute archives, aggregated bucket starts, and duplicate records. Each has a complete and a failing input, a declared plan, and expected counts. MoonTick does not ingest the source systems directly; callers supply extracted timestamp ticks.

The input format is **ticks**: no header, one canonical signed `Int64` millisecond value per line. A zero-byte file is valid and reports the whole plan as missing. Blank lines, BOM, non-ASCII bytes, CSV fields, whitespace around values, and malformed integers are rejected. The declared window and step must form a positive whole number of grid intervals; MoonTick never infers them from the data.

```text
moontick check FILE --start-ms START --end-ms END --step-ms STEP
               [--format text|json] [--detail-limit N]
```

`--detail-limit` defaults to 1000 and accepts 1–10000. It limits displayed details, not complete counts. JSON audit reports use `moontick.audit.v1`; errors use a separate `moontick.error.v1` document. All timestamps, counts, and grid indices in JSON are decimal strings to preserve `Int64` precision.

| Exit | Meaning |
|---:|---|
| 0 | Audit passed, or help/version requested |
| 1 | Audit completed and found a data problem |
| 2 | Usage, configuration, input, or resource error |
| 3 | File I/O error |
| 4 | Internal error |

The reusable `core` package exposes `make_grid(start_ms, end_ms, step_ms)` and `audit(times, grid, detail_limit)`. `ticks_input` parses the strict line format; `report` renders text and JSON. The generated `pkg.generated.mbti` files document the current public signatures. Product code is MoonBit; Python is used only for independent tests.

## Verify a checkout

```sh
moon fmt --check
moon check --target native
moon build --target native
moon test --target native
MOONTICK_BIN="$PWD/_build/native/debug/build/cmd/moontick/moontick.exe" python3 tests/cli/test_cli.py
MOONTICK_BIN="$PWD/_build/native/debug/build/cmd/moontick/moontick.exe" python3 tests/oracle/test_differential.py
```

The oracle uses enumerated small grids, a fixed random seed, and metamorphic checks rather than the product's gap algorithm. [GitHub Actions run 35747020671](https://github.com/z2823253773-p/moontick/actions/runs/35747020671) passed on macOS arm64 and Linux x86_64 at commit `e047c4d` with the pinned compiler. Each platform ran 77 MoonBit tests, 42 real-process CLI tests, and the independent oracle. The publisher has not provided a usable checksum for the core archive, so its supply-chain verification remains open.

## Scope and limits

The v0.1 design audits one finite series on one constant-step integer grid. It does not parse multi-column CSV, infer a timezone, tolerate jitter, handle variable calendar intervals, predict missing values, or repair input. Resource limits are 32 MiB of input, 250,000 records, and 20 bytes per token. The expected grid may be much larger because missing intervals are compressed rather than enumerated in the product.

The implementation contract and review evidence are in the source repository's [specification](https://github.com/z2823253773-p/moontick/blob/main/docs/planning/02_SPEC.md) and [evidence directory](https://github.com/z2823253773-p/moontick/tree/main/docs/evidence); they are intentionally excluded from the small Mooncakes archive. Independent third-party user feedback remains pending.

Licensed under [MIT](LICENSE).
