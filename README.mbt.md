# moontick

Audit a fixed-interval sampling plan against observed tick timestamps.

**Status: T1 only.** This is the minimal vertical slice described in
`docs/handoffs/T1_CLAUDE.md`. It is not a v0.1 release and must not be presented
as one.

## What works today

- `core` — validated `Grid` construction (`make_grid`) and `audit`, integer
  milliseconds only. No file, shell, network, or clock access.
- `ticks_input` — headerless ticks files, one canonical integer millisecond per
  line; record number equals physical line number.
- `report` — deterministic `moontick.audit.v1` JSON.
- `cmd/moontick` — `check` with real process exit codes.

## Build and run

```bash
moon check --target native
moon test --target native
moon build --target native
```

The executable is produced at
`_build/native/debug/build/cmd/moontick/moontick.exe`.

```bash
moontick check tests/fixtures/full.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json
```

Exit codes: `0` audit passed, `1` audit completed with data problems, `2`
argument/config/input/resource error, `3` I/O failure, `4` internal error.

## Deliberate T1 limits

These are known gaps, not oversights. They are owned by later tasks:

- **Text output is not implemented** (`report/text.mbt`, T4). `--format` accepts
  only `json`; `--format text` is rejected as a usage error.
- **Full strict ticks byte handling is T3.** BOM, isolated CR, byte limits and
  the exhaustive bad-token table still need their dedicated tests.
- `moontick.batch.v1`, CSV, multiple series, CI, and release packaging are out of
  scope for T1.
