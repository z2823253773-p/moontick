// Behaviour of the ticks adapter: byte sequences in, timestamps and 1-based
// physical line numbers out. See docs/planning/02_SPEC.md section 2.

///|
fn bytes_of(text : String) -> Bytes {
  @utf8.encode(text)
}

///|
fn parse_ok(text : String) -> @ticks_input.ParsedInput {
  match @ticks_input.parse_ticks(bytes_of(text)) {
    Ok(parsed) => parsed
    Err(error) =>
      abort(
        "expected an accepted input, got " +
        error.kind.code() +
        " at line " +
        error.line.to_string(),
      )
  }
}

///|
fn parse_err(text : String) -> @ticks_input.InputError {
  match @ticks_input.parse_ticks(bytes_of(text)) {
    Ok(_) => abort("expected a rejected input for " + text)
    Err(error) => error
  }
}

///|
test "empty file is a valid empty sequence" {
  let parsed = parse_ok("")
  assert_eq(parsed.times.length(), 0)
  assert_eq(parsed.start_lines.length(), 0)
}

///|
test "single line without a trailing newline is one record" {
  let parsed = parse_ok("0")
  assert_eq(parsed.times, [0L])
}

///|
test "LF and CRLF both terminate a record" {
  assert_eq(parse_ok("0\n15\n30\n").times, [0L, 15L, 30L])
  assert_eq(parse_ok("0\r\n15\r\n30\r\n").times, [0L, 15L, 30L])
  assert_eq(parse_ok("0\r\n15\n30").times, [0L, 15L, 30L])
}

///|
test "start lines are 1-based physical line numbers" {
  let parsed = parse_ok("7\n8\n9")
  assert_eq(parsed.start_lines, [1, 2, 3])
}

///|
test "an isolated CR is not a terminator" {
  let error = parse_err("0\r1\n")
  assert_eq(error.kind, @ticks_input.InvalidToken)
  assert_eq(error.line, 1)
}

///|
test "a blank line is rejected with its line number" {
  let error = parse_err("0\n\n15\n")
  assert_eq(error.kind, @ticks_input.BlankLine)
  assert_eq(error.line, 2)
  assert_eq(error.kind.code(), "INPUT_INVALID")
}

///|
test "a trailing newline does not create a phantom blank line" {
  let parsed = parse_ok("0\n15\n")
  assert_eq(parsed.times.length(), 2)
}

///|
test "non-canonical spellings are rejected" {
  for text in ["+1", "-0", "01", " 1", "1 ", "1.0", "1e3", "0x1", "--1", "1-"] {
    let error = parse_err(text + "\n")
    assert_eq(error.kind, @ticks_input.InvalidToken)
    assert_eq(error.line, 1)
  }
}

///|
test "the Int64 endpoints are accepted" {
  assert_eq(parse_ok("9223372036854775807\n").times, [9223372036854775807L])
  assert_eq(parse_ok("-9223372036854775808\n").times, [
    -9223372036854775807L - 1L,
  ])
  assert_eq(parse_ok("-1\n").times, [-1L])
}

///|
test "values outside the Int64 range are rejected" {
  let error = parse_err("9223372036854775808\n")
  assert_eq(error.kind, @ticks_input.InvalidToken)
  let error = parse_err("-9223372036854775809\n")
  assert_eq(error.kind, @ticks_input.InvalidToken)
  let error = parse_err("99999999999999999999\n")
  assert_eq(error.kind, @ticks_input.InvalidToken)
}

///|
test "a token of exactly 20 bytes is checked, 21 bytes is over-long" {
  // 20 digits: a well-formed but out-of-range number.
  assert_eq(parse_err("10000000000000000000\n").kind, @ticks_input.InvalidToken)
  // 21 digits: rejected on length before any numeric interpretation.
  let error = parse_err("100000000000000000000\n")
  assert_eq(error.kind, @ticks_input.OverlongToken)
  assert_eq(error.kind.code(), "RESOURCE_LIMIT")
}

///|
test "the first bad record fails the whole input" {
  let error = parse_err("0\n15\nbad\n30\n")
  assert_eq(error.kind, @ticks_input.InvalidToken)
  assert_eq(error.line, 3)
}
