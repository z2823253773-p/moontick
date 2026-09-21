// Text-report rendering. See docs/planning/02_SPEC.md section 4.
//
// The process-level contract (stdout, stderr, exit codes, golden bytes) belongs
// to tests/cli/test_cli.py against the real executable. These cases pin the
// renderer itself: the exact verdict source, the display-only percentage, the
// truncation honesty rules, and the internal-error path.

///|
fn text_grid(start : Int64, end : Int64, step : Int64) -> @core.Grid {
  match @core.make_grid(start, end, step) {
    Ok(value) => value
    Err(error) => abort("expected a valid grid, got " + error.message())
  }
}

///|
fn text_report_of(
  times : Array[Int64],
  limit : Int,
) -> @core.AuditReport {
  match @core.audit(times, text_grid(0L, 60L, 15L), limit) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
}

///|
fn text_lines_of(times : Array[Int64]) -> Array[Int] {
  let positions : Array[Int] = []
  for i = 0; i < times.length(); i = i + 1 {
    positions.push(i + 1)
  }
  positions
}

///|
test "a passing audit renders PASS and a failing one renders FAIL" {
  let passed = text_report_of([0L, 15L, 30L, 45L], 1000)
  let ok = @report.render_text(passed, text_lines_of([0L, 15L, 30L, 45L]))
  assert_true(ok.contains("PASS"))
  assert_false(ok.contains("FAIL"))

  let failed = text_report_of([0L, 15L, 15L, 45L], 1000)
  let bad = @report.render_text(failed, text_lines_of([0L, 15L, 15L, 45L]))
  assert_true(bad.contains("FAIL"))
}

///|
test "the percentage is display-only and rounds while the verdict does not" {
  // 3 of 4 covered is exactly 75.00%.
  let report = text_report_of([0L, 15L, 30L, 45L], 1000)
  let text = @report.render_text(report, text_lines_of([0L, 15L, 30L, 45L]))
  assert_true(text.contains("4/4 (100.00%)"))
  // The verdict comes from `passed`, not from the percentage. A window with a
  // single expected point that is covered must still be PASS.
  let one = match @core.audit([0L], text_grid(0L, 1L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let one_text = @report.render_text(one, [1])
  assert_true(one_text.contains("1/1 (100.00%)"))
  assert_true(one_text.contains("PASS"))
}

///|
test "the percentage renders two decimals in integer arithmetic" {
  // 1 of 3 is 33.333...%, which rounds down to 33.33 rather than up to 33.34.
  let report = match @core.audit([0L], text_grid(0L, 3L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let text = @report.render_text(report, [1])
  assert_true(text.contains("1/3 (33.33%)"))

  // 2 of 3 is 66.666...%, which SPEC section 2.2 wants shown as 66.67%.
  let two = match @core.audit([0L, 1L], text_grid(0L, 3L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let two_text = @report.render_text(two, [1, 2])
  assert_true(two_text.contains("2/3 (66.67%)"))
}

///|
test "a whole percentage is exact, not one hundredth low" {
  // 57 of 100 is exactly 57%: no rounding decision is involved, so the displayed
  // value must be exact. Computing the hundredths through a `Double` used to
  // land a hair below 5700 and print 56.99%.
  let times : Array[Int64] = []
  for index = 0; index < 57; index = index + 1 {
    times.push(index.to_int64())
  }
  let report = match @core.audit(times, text_grid(0L, 100L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let positions : Array[Int] = []
  for index = 0; index < 57; index = index + 1 {
    positions.push(index + 1)
  }
  let text = @report.render_text(report, positions)
  assert_true(text.contains("57/100 (57.00%)"))

  // The same window with nothing covered: 0.00%, not a negative zero or a
  // rounding artefact.
  let empty = match @core.audit([], text_grid(0L, 100L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  assert_true(@report.render_text(empty, []).contains("0/100 (0.00%)"))
}

///|
test "a rounded-up 100.00% does not decide pass or fail" {
  // 19999 of 20000 is 99.995%, which rounds half up to 100.00% while one point
  // is still missing. SPEC section 2.2 calls this out by name: the display must
  // not be read back as the verdict, so this report has to say FAIL.
  let times : Array[Int64] = []
  for index = 0; index < 19999; index = index + 1 {
    times.push(index.to_int64())
  }
  let report = match @core.audit(times, text_grid(0L, 20000L, 1L), 1000) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let positions : Array[Int] = []
  for index = 0; index < 19999; index = index + 1 {
    positions.push(index + 1)
  }
  let text = @report.render_text(report, positions)
  assert_true(text.contains("19999/20000 (100.00%)"))
  assert_true(text.contains("missing: 1"))
  assert_false(report.passed)
  assert_true(text.contains("FAIL"))
}

///|
test "every category shows its exact count even when the list is cut" {
  // Two duplicates with detail_limit 1: the list must be short but the count
  // must stay exact, and the block must say it is truncated.
  let report = text_report_of([0L, 0L, 0L, 15L, 30L, 45L], 1)
  let text = @report.render_text(report, text_lines_of([0L, 0L, 0L, 15L, 30L, 45L]))
  assert_true(text.contains("duplicates=2"))
  // Here the shown count and the total count *are* the same kind of thing — both
  // are records — so "first N of M" stays correct for the record categories.
  assert_true(text.contains("showing first 1 of 2; truncated"))
}

///|
test "a fully shown category is never labelled truncated" {
  let report = text_report_of([0L, 0L, 15L, 30L, 45L], 1)
  let text = @report.render_text(report, text_lines_of([0L, 0L, 15L, 30L, 45L]))
  // One duplicate and detail_limit 1: the list is exactly full, not cut. The
  // heading stays plain — only a cut list may carry the notice.
  assert_true(text.contains("duplicates:\n    ms=0 record=2 line=2"))
  assert_false(text.contains("duplicates (truncated)"))
}

///|
test "a truncated block never presents the shown entries as the whole set" {
  let times = [0L, 30L]
  let report = text_report_of(times, 1)
  let text = @report.render_text(report, text_lines_of(times))
  // Two missing points across two ranges, only the first shown. The notice keeps
  // the two quantities apart: one range listed, two missing points in total.
  assert_true(text.contains("missing: 2"))
  assert_true(text.contains("missing_ranges (truncated):"))
  assert_true(text.contains("ranges shown: 1; missing points in total: 2"))
  assert_true(text.contains("[1,2)"))
}

///|
test "the missing-range notice does not label missing points as ranges" {
  // [0,100) step 1 with 0 and 50 covered: 98 missing points over two ranges.
  // Saying "showing first 1 of 98" would read as 98 *ranges*, which is wrong —
  // the report does not carry a range count and must not imply one.
  let times = [0L, 50L]
  let report = match @core.audit(times, text_grid(0L, 100L, 1L), 1) {
    Ok(value) => value
    Err(error) => abort("expected a completed audit, got " + error.message())
  }
  let text = @report.render_text(report, text_lines_of(times))
  assert_true(text.contains("missing_ranges (truncated):"))
  assert_true(text.contains("ranges shown: 1; missing points in total: 98"))
  // The old wording passed the point count off as a range count.
  assert_false(text.contains("of 98"))
}

///|
test "an untruncated report never claims truncation" {
  let times = [0L, 15L, 30L, 45L]
  let report = text_report_of(times, 1000)
  let text = @report.render_text(report, text_lines_of(times))
  assert_false(text.contains("truncated"))
  assert_true(text.contains("none"))
}

///|
test "a report with no problems of a category prints none for it" {
  let times = [0L, 15L, 30L, 45L]
  let report = text_report_of(times, 1000)
  let text = @report.render_text(report, text_lines_of(times))
  for title in ["duplicates:", "out_of_order:", "off_grid:", "out_of_range:"] {
    assert_true(text.contains(title + "\n  none"))
  }
}

///|
test "details carry the timestamp, record number and physical line" {
  // The duplicate is the third record; give it a non-trivial physical line so
  // the renderer cannot pass by echoing the record number.
  let report = text_report_of([0L, 15L, 15L, 45L], 1000)
  let text = @report.render_text(report, [1, 2, 3, 4])
  assert_true(text.contains("ms=15 record=3 line=3"))
}

///|
test "the renderer uses the supplied physical lines, not the record numbers" {
  let report = text_report_of([0L, 15L, 15L, 45L], 1000)
  // Positions deliberately offset: a renderer that ignored `start_lines` would
  // print line=3 here.
  let text = @report.render_text(report, [10, 20, 30, 40])
  assert_true(text.contains("ms=15 record=3 line=30"))
}

///|
test "the renderer reports a position mismatch instead of guessing" {
  let report = text_report_of([0L, 15L, 30L, 45L], 1000)
  // Three positions for four records is a caller defect, not a data finding.
  match @report.try_render_text(report, [1, 2, 3]) {
    Ok(_) => abort("expected the renderer to reject a short position array")
    Err(message) => assert_true(message.contains("4"))
  }
  // The JSON renderer reaches the same verdict.
  match @report.try_render_json(report, [1, 2, 3]) {
    Ok(_) => abort("expected the renderer to reject a short position array")
    Err(message) => assert_true(message.contains("4"))
  }
}

///|
test "the text report is a pure function of the report and the positions" {
  let times = [0L, 15L, 15L, 45L]
  let report = text_report_of(times, 1000)
  let lines = text_lines_of(times)
  let first = @report.render_text(report, lines)
  let second = @report.render_text(report, lines)
  // Same inputs, same bytes: nothing time-, host- or path-dependent leaked in.
  assert_eq(first, second)
  // The window is printed from the grid it was audited against, not read back
  // from anything ambient.
  assert_true(first.contains("[0,60) step_ms=15"))
}
