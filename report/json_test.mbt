// Report shape and determinism. See docs/planning/02_SPEC.md section 4.

///|
fn grid_of(start : Int64, end : Int64, step : Int64) -> @core.Grid {
  match @core.make_grid(start, end, step) {
    Ok(value) => value
    Err(error) => abort("expected a valid grid, got " + error.message())
  }
}

///|
fn report_of(times : Array[Int64], limit : Int) -> @core.AuditReport {
  match @core.audit(times, grid_of(0L, 60L, 15L), limit) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
}

///|
test "a passing report carries the T1 schema and string counters" {
  let report = report_of([0L, 15L, 30L, 45L], 1000)
  let json = @report.render_json(report, [1, 2, 3, 4])
  for
    fragment in [
      "\"schema\":\"moontick.audit.v1\"", "\"status\":\"pass\"", "\"unit\":\"ms\"",
      "\"input_records\":\"4\"", "\"expected_points\":\"4\"", "\"covered_points\":\"4\"",
      "\"missing_points\":\"0\"", "\"longest_missing_run\":\"0\"", "\"missing_ranges\":[]",
    ] {
    assert_true(json.contains(fragment))
  }
}

///|
test "grid values survive as exact decimal strings" {
  let times : Array[Int64] = []
  let report = match
    @core.audit(times, grid_of(9007199254740993L, 9007199254740997L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let json = @report.render_json(report, [])
  // 2^53 + 1 would round to 2^53 if it ever travelled as a JSON number.
  assert_true(json.contains("\"start_ms\":\"9007199254740993\""))
  assert_true(json.contains("\"missing_points\":\"4\""))
  assert_true(json.contains("[\"0\",\"4\"]"))
}

///|
test "duplicates and off-grid records keep their line numbers" {
  // Window [0, 75) so both 60 and 62 are inside it: 60 is on the grid and 62 is
  // off it. The repeated 15 makes record 3 the duplicate.
  let report = match
    @core.audit([0L, 15L, 15L, 45L, 62L], grid_of(0L, 75L, 15L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let json = @report.render_json(report, [1, 2, 3, 4, 5])
  assert_true(json.contains("\"duplicate_extra_records\":\"1\""))
  assert_true(json.contains("\"off_grid_records\":\"1\""))
  // The duplicate is the second occurrence, at record 3 and line 3.
  assert_true(
    json.contains("{\"timestamp_ms\":\"15\",\"record_index\":3,\"line\":3}"),
  )
  assert_true(
    json.contains("{\"timestamp_ms\":\"62\",\"record_index\":5,\"line\":5}"),
  )
}

///|
test "out-of-range records are reported with their line numbers" {
  let report = report_of([-15L, 0L, 15L, 30L, 60L], 1000)
  let json = @report.render_json(report, [1, 2, 3, 4, 5])
  // -15 is before the window and 60 is past its exclusive end.
  assert_true(json.contains("\"out_of_range_records\":\"2\""))
  assert_true(
    json.contains("{\"timestamp_ms\":\"-15\",\"record_index\":1,\"line\":1}"),
  )
  assert_true(
    json.contains("{\"timestamp_ms\":\"60\",\"record_index\":5,\"line\":5}"),
  )
}

///|
test "rendering is byte-identical for the same report" {
  let first = @report.render_json(report_of([0L, 30L, 45L], 1000), [1, 2, 3])
  let second = @report.render_json(report_of([0L, 30L, 45L], 1000), [1, 2, 3])
  assert_eq(first, second)
  assert_true(first.contains("\"missing_ranges\":[[\"1\",\"2\"]]"))
}

///|
test "a position array that does not match the record count is refused" {
  // Two records but one position: emitting a report here would attach the wrong
  // line number to record 2, so the render layer must refuse rather than guess.
  let report = report_of([0L, 30L], 1000)
  match @report.try_render_json(report, [1]) {
    Ok(_) => abort("expected the mismatched position array to be refused")
    Err(message) => assert_true(message.contains("one position per record"))
  }
}

///|
test "an error document is shaped separately and omits unknown positions" {
  let json = @report.render_error(
    "CONFIG_INVALID",
    "step_ms must be greater than zero",
    None,
    None,
  )
  assert_true(json.contains("\"schema\":\"moontick.error.v1\""))
  assert_true(json.contains("\"code\":\"CONFIG_INVALID\""))
  assert_true(!json.contains("record_index"))
  assert_true(!json.contains("\"line\""))
}

///|
test "an error document carries a line when one is known" {
  let json = @report.render_error(
    "INPUT_INVALID",
    "blank lines are not records",
    None,
    Some(2),
  )
  assert_true(json.contains("\"line\":2"))
  // A line number is a safe JSON integer, not a quoted string.
  assert_true(!json.contains("\"line\":\"2\""))
}
