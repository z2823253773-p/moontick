// T2 contract tests: the classification/range cases from
// docs/handoffs/T2_CLAUDE.md plus its four requested pieces of T2 evidence
// (negative-time grids, detail truncation, library-level detail_limit
// rejection, library-level record ceiling).
//
// Every expected value below is derived from docs/planning/02_SPEC.md section
// 2.2 and the T2 task card, not read back out of core/audit.mbt. T1's own tests
// stay in audit_test.mbt and are not touched.

///|
/// Build a validated grid, failing the test if the configuration is rejected.
fn scope_grid(start_ms : Int64, end_ms : Int64, step_ms : Int64) -> @core.Grid {
  match @core.make_grid(start_ms, end_ms, step_ms) {
    Ok(grid) => grid
    Err(error) => abort("expected a valid grid, got " + error.message())
  }
}

///|
/// Audit against an arbitrary grid with an explicit detail limit.
fn scope_audit_on(
  times : Array[Int64],
  grid : @core.Grid,
  detail_limit : Int,
) -> @core.AuditReport {
  match @core.audit(times, grid, detail_limit) {
    Ok(report) => report
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
}

///|
/// The benchmark grid of the T2 table, with the default detail limit.
fn scope_audit(times : Array[Int64]) -> @core.AuditReport {
  scope_audit_on(times, scope_grid(0L, 60L, 15L), 1000)
}

///|
fn scope_error_code(
  result : Result[@core.AuditReport, @core.AuditError],
) -> String {
  match result {
    Ok(_) => "ACCEPTED"
    Err(error) => error.code()
  }
}

// ---------------------------------------------------------------------------
// The seven classification cases of the T2 table. The five counts overlap, so
// each test asserts all five separately instead of a "bad rows" total.
// ---------------------------------------------------------------------------

///|
test "grid=(0,60,15) times=[0,15,15,45]: duplicate 15, k=2 missing" {
  let report = scope_audit([0L, 15L, 15L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 4L)
  assert_eq(report.covered_points, 3L)
  assert_eq(report.missing_points, 1L)
  assert_eq(report.missing_ranges, [(2L, 3L)])
  assert_eq(report.longest_missing_run, 1L)
  assert_eq(report.duplicate_extra_records, 1L)
  assert_eq(report.duplicates.length(), 1)
  // The extra row is the third record, the second 15.
  assert_eq(report.duplicates[0].record_index, 3)
  assert_eq(report.duplicates[0].timestamp_ms, 15L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[30,0,15,45]: one out-of-order row, coverage still complete" {
  let report = scope_audit([30L, 0L, 15L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 4L)
  assert_eq(report.covered_points, 4L)
  assert_eq(report.missing_points, 0L)
  assert_eq(report.missing_ranges.length(), 0)
  assert_eq(report.longest_missing_run, 0L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 1L)
  assert_eq(report.out_of_order.length(), 1)
  // Record 2 drops below its neighbour record 1, and is equal to nothing.
  assert_eq(report.out_of_order[0].record_index, 2)
  assert_eq(report.out_of_order[0].timestamp_ms, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  // Full coverage is not a pass: an out-of-order row still fails the audit.
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[0,16,30,45]: 16 is off grid and k=1 goes missing" {
  let report = scope_audit([0L, 16L, 30L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 4L)
  assert_eq(report.covered_points, 3L)
  assert_eq(report.missing_points, 1L)
  assert_eq(report.missing_ranges, [(1L, 2L)])
  assert_eq(report.longest_missing_run, 1L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 1L)
  assert_eq(report.off_grid.length(), 1)
  // 16 sits inside the window but not on a grid point, so it is off grid only.
  assert_eq(report.off_grid[0].record_index, 2)
  assert_eq(report.off_grid[0].timestamp_ms, 16L)
  assert_eq(report.out_of_range_records, 0L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[-15,0,15,30,45,60]: two out-of-range rows, coverage complete" {
  let report = scope_audit([-15L, 0L, 15L, 30L, 45L, 60L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 6L)
  assert_eq(report.covered_points, 4L)
  assert_eq(report.missing_points, 0L)
  assert_eq(report.missing_ranges.length(), 0)
  assert_eq(report.longest_missing_run, 0L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 2L)
  assert_eq(report.out_of_range.length(), 2)
  // Original input order: record 1 is below the window, record 6 is the
  // excluded right endpoint.
  assert_eq(report.out_of_range[0].record_index, 1)
  assert_eq(report.out_of_range[0].timestamp_ms, -15L)
  assert_eq(report.out_of_range[1].record_index, 6)
  assert_eq(report.out_of_range[1].timestamp_ms, 60L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[15,30]: two separated gaps, longest run 1" {
  let report = scope_audit([15L, 30L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 2L)
  assert_eq(report.covered_points, 2L)
  assert_eq(report.missing_points, 2L)
  assert_eq(report.missing_ranges, [(0L, 1L), (3L, 4L)])
  assert_eq(report.longest_missing_run, 1L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[0,45]: one interior gap of 2, longest run 2" {
  let report = scope_audit([0L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 2L)
  assert_eq(report.covered_points, 2L)
  assert_eq(report.missing_points, 2L)
  assert_eq(report.missing_ranges, [(1L, 3L)])
  assert_eq(report.longest_missing_run, 2L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[60,60,0]: overlapping classes must not be summed" {
  let report = scope_audit([60L, 60L, 0L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 3L)
  assert_eq(report.covered_points, 1L)
  assert_eq(report.missing_points, 3L)
  assert_eq(report.missing_ranges, [(1L, 4L)])
  assert_eq(report.longest_missing_run, 3L)
  assert_eq(report.duplicate_extra_records, 1L)
  assert_eq(report.duplicates.length(), 1)
  assert_eq(report.duplicates[0].record_index, 2)
  assert_eq(report.duplicates[0].timestamp_ms, 60L)
  assert_eq(report.out_of_order_records, 1L)
  assert_eq(report.out_of_order[0].record_index, 3)
  assert_eq(report.out_of_order[0].timestamp_ms, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 2L)
  assert_eq(report.out_of_range[0].record_index, 1)
  assert_eq(report.out_of_range[1].record_index, 2)
  // Two out-of-range rows are also a duplicate pair, so 1 + 1 + 2 = 4 flagged
  // rows for 3 input records. The counts overlap by design and there is no
  // "bad row" total to compare against input_records.
  assert_eq(
    report.duplicate_extra_records +
    report.out_of_order_records +
    report.out_of_range_records,
    4L,
  )
  assert_eq(report.input_records, 3L)
  assert_false(report.passed)
}

// ---------------------------------------------------------------------------
// T2 evidence: negative grid points, detail truncation, and the two
// library-level refusals that must not depend on the CLI or ticks layer.
// ---------------------------------------------------------------------------

///|
test "grid=(-30,30,15) times=[-30,-15,0,15]: negative milliseconds are valid grid points" {
  let report = scope_audit_on(
    [-30L, -15L, 0L, 15L],
    scope_grid(-30L, 30L, 15L),
    1000,
  )
  assert_eq(report.grid.start_ms, -30L)
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 4L)
  assert_eq(report.covered_points, 4L)
  assert_eq(report.missing_points, 0L)
  assert_eq(report.missing_ranges.length(), 0)
  assert_eq(report.longest_missing_run, 0L)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_true(report.passed)
}

///|
test "grid=(0,10000,1) with every even index and detail_limit=1 truncates ranges only" {
  let times : Array[Int64] = []
  for i = 0; i < 10000; i = i + 2 {
    times.push(i.to_int64())
  }
  let report = scope_audit_on(times, scope_grid(0L, 10000L, 1L), 1)
  assert_eq(report.grid.expected_points, 10000L)
  assert_eq(report.input_records, 5000L)
  assert_eq(report.covered_points, 5000L)
  // 5000 odd points are missing: one singleton gap per retained even point,
  // plus the gap at the excluded right endpoint. Counts stay exact even though
  // only the first range survives.
  assert_eq(report.missing_points, 5000L)
  assert_eq(report.missing_ranges, [(1L, 2L)])
  assert_eq(report.longest_missing_run, 1L)
  assert_true(report.truncated.missing_ranges)
  assert_false(report.truncated.duplicates)
  assert_false(report.truncated.out_of_order)
  assert_false(report.truncated.off_grid)
  assert_false(report.truncated.out_of_range)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_false(report.passed)
}

///|
test "audit rejects detail_limit=0 and detail_limit=10001 at the library layer" {
  let times = [0L, 15L, 30L, 45L]
  let grid = scope_grid(0L, 60L, 15L)
  let below : Bool = match @core.audit(times, grid, 0) {
    Ok(_) => false
    Err(InvalidDetailLimit) => true
    Err(_) => false
  }
  let above : Bool = match @core.audit(times, grid, 10001) {
    Ok(_) => false
    Err(InvalidDetailLimit) => true
    Err(_) => false
  }
  assert_true(below)
  assert_true(above)
  assert_eq(scope_error_code(@core.audit(times, grid, 0)), "CONFIG_INVALID")
  assert_eq(scope_error_code(@core.audit(times, grid, 10001)), "CONFIG_INVALID")
}

///|
test "audit rejects 250001 parseable timestamps at the library layer" {
  let times : Array[Int64] = []
  for i = 0; i < 250001; i = i + 1 {
    times.push(i.to_int64())
  }
  assert_eq(times.length(), 250001)
  let grid = scope_grid(0L, 60L, 15L)
  let rejected : Bool = match @core.audit(times, grid, 1000) {
    Ok(_) => false
    Err(TooManyRecords) => true
    Err(_) => false
  }
  assert_true(rejected)
  assert_eq(scope_error_code(@core.audit(times, grid, 1000)), "RESOURCE_LIMIT")
}
