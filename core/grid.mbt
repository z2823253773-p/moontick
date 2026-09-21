///|
/// Largest signed 64-bit millisecond value.
let i64_max : Int64 = 9223372036854775807L

///|
/// Build a validated sampling plan over `[start_ms, end_ms)`.
///
/// Rejects a non-positive step, an empty or reversed window, a window whose
/// length does not fit in Int64, and a window that is not a whole number of
/// steps. Nothing here is ever converted to `Double`, so grids near the Int64
/// edges keep every digit of precision.
pub fn make_grid(
  start_ms : Int64,
  end_ms : Int64,
  step_ms : Int64,
) -> Result[Grid, ConfigError] {
  if step_ms <= 0L {
    return Err(StepNotPositive)
  }
  if end_ms <= start_ms {
    return Err(EndNotAfterStart)
  }
  // `end_ms - start_ms` can only overflow when the two operands straddle zero
  // and the true difference exceeds i64_max. On this branch start_ms < 0, so
  // `i64_max + start_ms` is itself safe to compute.
  if start_ms < 0L && end_ms > i64_max + start_ms {
    return Err(WindowDiffOverflow)
  }
  let window = end_ms - start_ms
  if window % step_ms != 0L {
    return Err(WindowNotWholeSteps)
  }
  Ok({ start_ms, end_ms, step_ms, expected_points: window / step_ms, })
}
