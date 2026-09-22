# Three synthetic sampling-plan examples

All files contain one integer-millisecond tick per line. They are invented examples, not downloaded exchange or database records. Run commands from the repository or extracted Mooncakes module root after building the native CLI:

```sh
moon build --target native
BIN=./_build/native/debug/build/cmd/moontick/moontick.exe
```

## One-minute archive check

The caller declares five minute-bucket starts in `[1723456800000,1723457100000)`, step `60000`. The start is 2024-08-12 10:00:00 UTC. This is a synthetic version of a post-extraction archive check; it does not inspect CSV or prices.

```sh
"$BIN" check examples/archive/complete.ticks --start-ms 1723456800000 --end-ms 1723457100000 --step-ms 60000 --format json
"$BIN" check examples/archive/missing-middle.ticks --start-ms 1723456800000 --end-ms 1723457100000 --step-ms 60000 --format json
```

The complete file covers all 5 planned points and exits 0. The second covers indices 0, 1, and 4, so it has 3/5 coverage, 2 missing points, one missing range `[2,4)`, and exits 1.

## Aggregated 20-second buckets

The caller has exported bucket **start** timestamps for `[0,60000)` with step `20000`. A system that labels buckets by their end would need conversion before this check.

```sh
"$BIN" check examples/buckets/complete.ticks --start-ms 0 --end-ms 60000 --step-ms 20000 --format json
"$BIN" check examples/buckets/missing-middle.ticks --start-ms 0 --end-ms 60000 --step-ms 20000 --format json
```

The complete file covers 3/3 planned buckets and exits 0. The second covers indices 0 and 2: 2/3 coverage, 1 missing point, missing range `[1,2)`, and exit 1.

## Duplicate cannot repair a gap

The caller declares `[0,60)` with step `15`, or ticks 0, 15, 30, and 45. A duplicate line at 15 does not cover the absent 30.

```sh
"$BIN" check examples/synthetic/complete.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
"$BIN" check examples/synthetic/duplicate-and-missing.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

The complete file covers 4/4 and exits 0. The second has four input rows but covers 3/4: 1 missing point at index range `[2,3)`, 1 extra duplicate record, and exit 1.
