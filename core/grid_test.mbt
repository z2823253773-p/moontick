// Configuration rejection: every case below must be CONFIG_INVALID, and the
// window difference must never be computed as a floating point value.

///|
let i64_min : Int64 = -9223372036854775807L - 1L

///|
let i64_max : Int64 = 9223372036854775807L

///|
fn rejection_message(result : Result[@core.Grid, @core.ConfigError]) -> String {
  match result {
    Ok(_) => "ACCEPTED"
    Err(error) => error.code() + ": " + error.message()
  }
}

///|
test "step_ms = 0 is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(0L, 60L, 0L)),
    "CONFIG_INVALID: step_ms must be greater than zero",
  )
}

///|
test "negative step_ms is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(0L, 60L, -15L)),
    "CONFIG_INVALID: step_ms must be greater than zero",
  )
}

///|
test "end_ms equal to start_ms is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(60L, 60L, 15L)),
    "CONFIG_INVALID: end_ms must be greater than start_ms",
  )
}

///|
test "end_ms before start_ms is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(60L, 0L, 15L)),
    "CONFIG_INVALID: end_ms must be greater than start_ms",
  )
}

///|
test "a window that is not a whole number of steps is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(0L, 61L, 15L)),
    "CONFIG_INVALID: end_ms - start_ms is not a whole number of step_ms intervals",
  )
}

///|
test "a window difference that overflows Int64 is rejected" {
  assert_eq(
    rejection_message(@core.make_grid(i64_min, i64_max, 1L)),
    "CONFIG_INVALID: end_ms - start_ms does not fit in a signed 64-bit millisecond value",
  )
}

///|
test "a whole-period window is accepted and counts exact points" {
  assert_eq(@core.make_grid(0L, 60L, 15L).unwrap().expected_points, 4L)
  assert_eq(@core.make_grid(-30L, 30L, 15L).unwrap().expected_points, 4L)
}

///|
test "an Int64-sized grid is accepted without floating point rounding" {
  let grid = @core.make_grid(9007199254740993L, 9007199254740997L, 1L).unwrap()
  assert_eq(grid.expected_points, 4L)
  assert_eq(grid.start_ms.to_string(), "9007199254740993")
}
