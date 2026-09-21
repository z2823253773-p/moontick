// Deterministic `moontick.audit.v1` JSON. See docs/planning/02_SPEC.md section 4.

///|
/// JSON-escape `text` without the surrounding quotes.
///
/// `Char::escape` already knows the exact byte escapes this toolchain's JSON
/// expects, including `\n`, `\r`, `\b`, `\t` and `\u{...}` for the rest of the
/// control range, so it is reused rather than reimplemented. Its output is
/// wrapped in single quotes, which are stripped here; the payload itself is
/// emitted unchanged.
fn escape_text(text : String) -> String {
  let buffer = StringBuilder()
  for character in text {
    let escaped = character.escape()
    // `escape()` returns the character wrapped in single quotes, e.g. `'\n'`.
    // Dropping the first and last byte leaves exactly the JSON escape payload:
    // `\n`, `\r`, `\t`, `\b`, `\"`, `\\` or `\u{...}`. Anything shorter than
    // three bytes (a lone quoted character) is already safe unescaped.
    if escaped.length() >= 3 {
      buffer.write_string(escaped[1:escaped.length() - 1].to_owned())
    } else if escaped.length() == 1 {
      buffer.write_string(escaped)
    }
  }
  buffer.to_string()
}

///|
/// A string field. Timestamps, grid indices and every counter travel as decimal
/// strings so a value near the Int64 edges survives a JavaScript round trip.
fn decimal(value : Int64) -> Json {
  Json::string(value.to_string())
}

///|
/// A plain JSON integer. Only used for record numbers, physical line numbers and
/// the `detail_limit`, which the resource limits already bound well below
/// 2^53.
fn plain(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
/// A JSON boolean with an explicit representation, so the output never depends
/// on how this toolchain formats `Double`.
fn flag(value : Bool) -> Json {
  Json::number(0.0, repr=if value { "true" } else { "false" })
}

///|
fn object_of(fields : Array[(String, Json)]) -> Json {
  let members : Map[String, Json] = Map([])
  for field in fields {
    members.set(field.0, field.1)
  }
  Json::object(members)
}

///|
fn array_of(values : Array[Json]) -> Json {
  Json::array(values)
}

///|
/// One flagged record, positioned by its 1-based record number and physical line.
///
/// The caller has already checked that `start_lines` covers every record, so the
/// index below is in range.
fn record_ref(reference : @core.RecordRef, start_lines : Array[Int]) -> Json {
  let line = start_lines[reference.record_index - 1]
  object_of([
    ("timestamp_ms", decimal(reference.timestamp_ms)),
    ("record_index", plain(reference.record_index)),
    ("line", plain(line)),
  ])
}

///|
fn record_refs(
  references : Array[@core.RecordRef],
  start_lines : Array[Int],
) -> Json {
  let items : Array[Json] = []
  for reference in references {
    items.push(record_ref(reference, start_lines))
  }
  array_of(items)
}

///|
/// The half-open grid-index intervals that were never covered.
fn missing_ranges(report : @core.AuditReport) -> Json {
  let items : Array[Json] = []
  for range in report.missing_ranges {
    items.push(array_of([decimal(range.0), decimal(range.1)]))
  }
  array_of(items)
}

///|
/// Render a completed audit as `moontick.audit.v1`.
///
/// `start_lines` maps each record to its 1-based physical line and must hold one
/// entry per input record. A mismatch is a caller defect, not a data finding: it
/// would produce a report with the wrong line numbers, so this aborts instead of
/// guessing or reading out of bounds. SPEC section 6 makes that the render
/// layer's responsibility.
///
/// Every field is written in a fixed order and every number has an explicit
/// representation, so the same bytes in and the same plan out always produce
/// byte-identical JSON. Nothing environment-specific (time, host, absolute path)
/// is included.
pub fn render_json(
  report : @core.AuditReport,
  start_lines : Array[Int],
) -> String {
  match try_render_json(report, start_lines) {
    Ok(text) => text
    Err(message) => abort(message)
  }
}

///|
/// `render_json`, but returning the internal inconsistency instead of aborting.
///
/// The CLI maps this to the internal-error exit code, so a render-layer defect
/// is never reported as a problem with the caller's data.
pub fn try_render_json(
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
  let grid = object_of([
    ("start_ms", decimal(report.grid.start_ms)),
    ("end_ms", decimal(report.grid.end_ms)),
    ("step_ms", decimal(report.grid.step_ms)),
  ])
  let summary = object_of([
    ("input_records", decimal(report.input_records)),
    ("expected_points", decimal(report.grid.expected_points)),
    ("covered_points", decimal(report.covered_points)),
    ("missing_points", decimal(report.missing_points)),
    ("duplicate_extra_records", decimal(report.duplicate_extra_records)),
    ("out_of_order_records", decimal(report.out_of_order_records)),
    ("off_grid_records", decimal(report.off_grid_records)),
    ("out_of_range_records", decimal(report.out_of_range_records)),
    ("longest_missing_run", decimal(report.longest_missing_run)),
  ])
  let truncated = object_of([
    ("missing_ranges", flag(report.truncated.missing_ranges)),
    ("duplicates", flag(report.truncated.duplicates)),
    ("out_of_order", flag(report.truncated.out_of_order)),
    ("off_grid", flag(report.truncated.off_grid)),
    ("out_of_range", flag(report.truncated.out_of_range)),
  ])
  let document = object_of([
    ("schema", Json::string("moontick.audit.v1")),
    ("status", Json::string(if report.passed { "pass" } else { "fail" })),
    ("unit", Json::string("ms")),
    ("grid", grid),
    ("summary", summary),
    ("missing_ranges", missing_ranges(report)),
    ("duplicates", record_refs(report.duplicates, start_lines)),
    ("out_of_order", record_refs(report.out_of_order, start_lines)),
    ("off_grid", record_refs(report.off_grid, start_lines)),
    ("out_of_range", record_refs(report.out_of_range, start_lines)),
    ("details_truncated", truncated),
  ])
  Ok(document.stringify())
}

///|
/// Render a failure as `moontick.error.v1`.
///
/// This is a separate shape from the audit report on purpose: a caller must
/// never mistake an error document for a report whose counters happen to be
/// zero. `record_index` and `line` are omitted entirely when the failure cannot
/// be tied to one record, and the offending input text is never echoed back.
pub fn render_error(
  code : String,
  message : String,
  record_index : Int?,
  line : Int?,
) -> String {
  let fields : Array[(String, Json)] = [
    ("schema", Json::string("moontick.error.v1")),
    ("code", Json::string(code)),
    ("message", Json::string(message)),
  ]
  match record_index {
    Some(index) => fields.push(("record_index", plain(index)))
    None => ()
  }
  match line {
    Some(number) => fields.push(("line", plain(number)))
    None => ()
  }
  object_of(fields).stringify()
}
