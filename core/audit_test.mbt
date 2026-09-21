// The three T1 behaviour cases from docs/handoffs/T1_CLAUDE.md.

///|
fn grid_of(start : Int64, end : Int64, step : Int64) -> @core.Grid {
  match @core.make_grid(start, end, step) {
    Ok(g) => g
    Err(error) => abort("expected a valid grid, got " + error.message())
  }
}

///|
fn audit_of(times : Array[Int64]) -> @core.AuditReport {
  match @core.audit(times, grid_of(0L, 60L, 15L), 1000) {
    Ok(r) => r
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
}

///|
test "grid=(0,60,15) times=[0,15,30,45] is full coverage and passes" {
  let report = audit_of([0L, 15L, 30L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 4L)
  assert_eq(report.covered_points, 4L)
  assert_eq(report.missing_points, 0L)
  assert_eq(report.missing_ranges.length(), 0)
  assert_eq(report.duplicate_extra_records, 0L)
  assert_eq(report.out_of_order_records, 0L)
  assert_eq(report.off_grid_records, 0L)
  assert_eq(report.out_of_range_records, 0L)
  assert_eq(report.longest_missing_run, 0L)
  assert_true(report.passed)
}

///|
test "grid=(0,60,15) times=[] is entirely missing and fails" {
  let report = audit_of([])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 0L)
  assert_eq(report.covered_points, 0L)
  assert_eq(report.missing_points, 4L)
  assert_eq(report.missing_ranges, [(0L, 4L)])
  assert_eq(report.longest_missing_run, 4L)
  assert_false(report.passed)
}

///|
test "grid=(0,60,15) times=[0,30,45] misses exactly one point" {
  let report = audit_of([0L, 30L, 45L])
  assert_eq(report.grid.expected_points, 4L)
  assert_eq(report.input_records, 3L)
  assert_eq(report.covered_points, 3L)
  assert_eq(report.missing_points, 1L)
  assert_eq(report.missing_ranges, [(1L, 2L)])
  assert_eq(report.longest_missing_run, 1L)
  assert_false(report.passed)
}
