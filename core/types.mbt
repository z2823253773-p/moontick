// Frozen core types for the T1 interface. See docs/planning/02_SPEC.md section 6.
//
// `Grid`, `RecordRef`, `DetailTruncation` and `AuditReport` are `pub struct`,
// which in this MoonBit version means "readable outside the package, but not
// constructible there". Every `Grid` therefore comes from `make_grid` and every
// `AuditReport` from `audit`; callers cannot build one with unchecked fields.

///|
/// A fixed sampling plan over the half-open window `[start_ms, end_ms)`.
///
/// A value in hand always satisfies `step_ms > 0`, `end_ms > start_ms`,
/// `(end_ms - start_ms) % step_ms == 0`, and
/// `expected_points == (end_ms - start_ms) / step_ms`.
pub struct Grid {
  start_ms : Int64
  end_ms : Int64
  step_ms : Int64
  expected_points : Int64
}

///|
/// A rejected sampling plan. Every variant reports the CLI code `CONFIG_INVALID`
/// because all of them are caller configuration mistakes, not data problems.
pub(all) enum ConfigError {
  StepNotPositive
  EndNotAfterStart
  WindowDiffOverflow
  WindowNotWholeSteps
}

///|
pub fn ConfigError::code(self : ConfigError) -> String {
  match self {
    StepNotPositive => "CONFIG_INVALID"
    EndNotAfterStart => "CONFIG_INVALID"
    WindowDiffOverflow => "CONFIG_INVALID"
    WindowNotWholeSteps => "CONFIG_INVALID"
  }
}

///|
pub fn ConfigError::message(self : ConfigError) -> String {
  match self {
    StepNotPositive => "step_ms must be greater than zero"
    EndNotAfterStart => "end_ms must be greater than start_ms"
    WindowDiffOverflow =>
      "end_ms - start_ms does not fit in a signed 64-bit millisecond value"
    WindowNotWholeSteps =>
      "end_ms - start_ms is not a whole number of step_ms intervals"
  }
}

///|
/// A request `audit` refused to honour. Neither variant is a data problem.
pub(all) enum AuditError {
  InvalidDetailLimit
  TooManyRecords
}

///|
pub fn AuditError::code(self : AuditError) -> String {
  match self {
    InvalidDetailLimit => "CONFIG_INVALID"
    TooManyRecords => "RESOURCE_LIMIT"
  }
}

///|
pub fn AuditError::message(self : AuditError) -> String {
  match self {
    InvalidDetailLimit => "detail_limit must be between 1 and 10000"
    TooManyRecords => "record count exceeds the 250000 limit"
  }
}

///|
/// One flagged input record. `record_index` is 1-based, matching the ticks
/// record number; the physical line number is supplied by the input adapter.
pub struct RecordRef {
  timestamp_ms : Int64
  record_index : Int
}

///|
/// Which detail lists were cut down to `detail_limit`. Counts stay exact.
pub struct DetailTruncation {
  missing_ranges : Bool
  duplicates : Bool
  out_of_order : Bool
  off_grid : Bool
  out_of_range : Bool
}

///|
/// The complete audit outcome.
///
/// `missing_ranges` holds half-open grid-index intervals `[k_start, k_end)`,
/// ordered and merged. The five problem counts overlap by design: one record can
/// be out of range and a duplicate at the same time, so they must never be added
/// up into a "bad record" total.
pub struct AuditReport {
  grid : Grid
  input_records : Int64
  covered_points : Int64
  missing_points : Int64
  duplicate_extra_records : Int64
  out_of_order_records : Int64
  off_grid_records : Int64
  out_of_range_records : Int64
  longest_missing_run : Int64
  missing_ranges : Array[(Int64, Int64)]
  duplicates : Array[RecordRef]
  out_of_order : Array[RecordRef]
  off_grid : Array[RecordRef]
  out_of_range : Array[RecordRef]
  truncated : DetailTruncation
  passed : Bool
}
