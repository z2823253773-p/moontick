// Deterministic human-readable text report. See docs/planning/02_SPEC.md
// section 4. Pure: no file, clock, host or path ever reaches the output.

///|
/// `covered / expected` as a percentage with two decimals.
///
/// The scaling happens before the division, so the intermediate value must not
/// overflow. It is a `Double` for exactly that reason: SPEC section 2.2 forbids
/// multiplying an `Int64` counter by 100, because a large `covered_points`
/// would wrap. This value is display-only and never decides pass or fail, which
/// stays the exact `Bool` the audit computed.
///
/// A zero-length window has no percentage to show; `make_grid` already requires
/// `end_ms > start_ms`, so `expected` is never zero, but the guard keeps the
/// function total for any caller.
fn percent(covered : Int64, expected : Int64) -> String {
  if expected <= 0L {
    return "n/a"
  }
  let scaled = (covered.to_double() / expected.to_double()) * 10000.0
  // Truncate towards zero and render as an integer number of hundredths, then
  // place the decimal point by hand. This avoids depending on how this
  // toolchain formats a `Double`, which is what keeps the output byte-stable.
  let hundredths = @double.trunc(scaled).to_int64()
  let whole = hundredths / 100L
  let fraction = hundredths % 100L
  let digits = if fraction < 10L {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  whole.to_string() + "." + digits + "%"
}

///|
/// One problem record as `ms=<timestamp> record=<n> line=<l>`.
fn text_record(line : Int, timestamp : Int64, record_index : Int) -> String {
  "    ms=" +
  timestamp.to_string() +
  " record=" +
  record_index.to_string() +
  " line=" +
  line.to_string()
}

///|
/// A details block. When the list was cut to the display limit the truncated
/// case says so explicitly and repeats the exact total, so a short list can
/// never be mistaken for the whole set. `shown` is the count actually printed.
fn text_details(
  buffer : StringBuilder,
  title : String,
  total : Int64,
  shown : Int,
  truncated : Bool,
) -> Unit {
  buffer.write_string("\n" + title + ":\n")
  if total == 0L {
    buffer.write_string("  none\n")
    return
  }
  if truncated {
    buffer.write_string(
      "  (showing first " +
      shown.to_string() +
      " of " +
      total.to_string() +
      "; truncated)\n",
    )
  }
}

///|
/// Render a completed audit as a stable, human-readable report.
///
/// `start_lines` maps each record to its 1-based physical line and must hold one
/// entry per input record. A mismatch is a caller defect rather than a data
/// finding — it would print the wrong line numbers — so this fails instead of
/// guessing. SPEC section 6 makes that the render layer's responsibility.
///
/// Nothing environment-specific (time, host, absolute path) is included, so the
/// same input and plan always produce byte-identical output.
pub fn render_text(
  report : @core.AuditReport,
  start_lines : Array[Int],
) -> String {
  match try_render_text(report, start_lines) {
    Ok(text) => text
    Err(message) => abort(message)
  }
}

///|
/// `render_text`, but returning the internal inconsistency instead of aborting.
///
/// The CLI maps this to the internal-error exit code, so a render-layer defect
/// is never reported as a problem with the caller's data.
pub fn try_render_text(
  report : @core.AuditReport,
  start_lines : Array[Int],
) -> Result[String, String] {
  if start_lines.length().to_int64() != report.input_records {
    return Err(
      "render needs one position per record, got " +
      start_lines.length().to_string() +
      " for " +
      report.input_records.to_string() +
      " records",
    )
  }
  let buffer = StringBuilder()
  // The verdict comes straight from the audit's exact boolean result. It is
  // never recomputed from the displayed percentage, which rounds.
  buffer.write_string(if report.passed { "PASS" } else { "FAIL" })
  buffer.write_string(
    "\ngrid: [" +
    report.grid.start_ms.to_string() +
    "," +
    report.grid.end_ms.to_string() +
    ") step_ms=" +
    report.grid.step_ms.to_string(),
  )
  buffer.write_string(
    "\nrecords: " +
    report.input_records.to_string() +
    "  expected_points: " +
    report.grid.expected_points.to_string(),
  )
  buffer.write_string(
    "\ncoverage: " +
    report.covered_points.to_string() +
    "/" +
    report.grid.expected_points.to_string() +
    " (" +
    percent(report.covered_points, report.grid.expected_points) +
    ")  missing: " +
    report.missing_points.to_string() +
    "  longest_missing_run: " +
    report.longest_missing_run.to_string(),
  )
  buffer.write_string(
    "\nproblems: duplicates=" +
    report.duplicate_extra_records.to_string() +
    " out_of_order=" +
    report.out_of_order_records.to_string() +
    " off_grid=" +
    report.off_grid_records.to_string() +
    " out_of_range=" +
    report.out_of_range_records.to_string(),
  )
  buffer.write_string("\nmissing_ranges:\n")
  if report.missing_ranges.length() == 0 {
    buffer.write_string("  none\n")
  } else {
    if report.truncated.missing_ranges {
      buffer.write_string(
        "  (showing first " +
        report.missing_ranges.length().to_string() +
        " of " +
        report.missing_points.to_string() +
        "; truncated)\n",
      )
    }
    for range in report.missing_ranges {
      buffer.write_string(
        "  [" + range.0.to_string() + "," + range.1.to_string() + ")\n",
      )
    }
  }
  text_details(
    buffer,
    "duplicates",
    report.duplicate_extra_records,
    report.duplicates.length(),
    report.truncated.duplicates,
  )
  for reference in report.duplicates {
    buffer.write_string(
      text_record(
        start_lines[reference.record_index - 1],
        reference.timestamp_ms,
        reference.record_index,
      ) + "\n",
    )
  }
  text_details(
    buffer,
    "out_of_order",
    report.out_of_order_records,
    report.out_of_order.length(),
    report.truncated.out_of_order,
  )
  for reference in report.out_of_order {
    buffer.write_string(
      text_record(
        start_lines[reference.record_index - 1],
        reference.timestamp_ms,
        reference.record_index,
      ) + "\n",
    )
  }
  text_details(
    buffer,
    "off_grid",
    report.off_grid_records,
    report.off_grid.length(),
    report.truncated.off_grid,
  )
  for reference in report.off_grid {
    buffer.write_string(
      text_record(
        start_lines[reference.record_index - 1],
        reference.timestamp_ms,
        reference.record_index,
      ) + "\n",
    )
  }
  text_details(
    buffer,
    "out_of_range",
    report.out_of_range_records,
    report.out_of_range.length(),
    report.truncated.out_of_range,
  )
  for reference in report.out_of_range {
    buffer.write_string(
      text_record(
        start_lines[reference.record_index - 1],
        reference.timestamp_ms,
        reference.record_index,
      ) + "\n",
    )
  }
  Ok(buffer.to_string())
}
