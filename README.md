# MoonTick

MoonTick audits a **declared fixed sampling plan** against observed integer-millisecond timestamps. It reports exact grid coverage, compresses missing points into index ranges, and identifies duplicates, out-of-order records, off-grid timestamps, and out-of-range timestamps. An empty input is a valid observation of a completely missing plan.

MoonTick is a MoonBit library and native CLI in pre-release development. Version `0.1.0` is declared in `moon.mod`; no Mooncakes release or competition acceptance is claimed yet.

## Build and try it

Use the pinned development compiler `moonc v0.10.14+7d59c7ec9`. From this repository:

```sh
moon check --target native
moon test --target native
moon build --target native
./_build/native/debug/build/cmd/moontick/moontick.exe check \
  tests/fixtures/full.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

The last command audits the half-open window `[0,60)` at 15 ms intervals. Its four expected timestamps are `0,15,30,45`; the fixture covers all four and exits `0`. To see one missing point and exit `1`, replace `full.ticks` with `one_missing.ticks`. Omit `--format json` for the default text report.

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

The oracle uses enumerated small grids, a fixed random seed, and metamorphic checks rather than the product's gap algorithm. The GitHub Actions workflow is a candidate for macOS arm64 and Linux x86_64; platform support should be read from **actual run results**, not from the presence of a workflow file.

## Scope and limits

The v0.1 design audits one finite series on one constant-step integer grid. It does not parse multi-column CSV, infer a timezone, tolerate jitter, handle variable calendar intervals, predict missing values, or repair input. Resource limits are 32 MiB of input, 250,000 records, and 20 bytes per token. The expected grid may be much larger because missing intervals are compressed rather than enumerated in the product.

The implementation contract and evidence are in `docs/planning/02_SPEC.md` and `docs/evidence/`. Published package installation, Linux CI, and external-user validation should be treated as pending until their own evidence exists.

Licensed under [MIT](LICENSE).
