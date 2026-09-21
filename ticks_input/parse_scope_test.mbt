// T3 delta evidence for the ticks adapter: raw-byte syntax, library-level byte
// and record ceilings, and physical-line localisation. Scope is
// docs/handoffs/T3_CLAUDE.md; T1's parse_test.mbt is left untouched.
//
// Every input below is assembled as `Bytes`. The rejected sequences include
// bytes that are not valid UTF-8, so they must never be routed through
// `String` first: a string round trip would either mangle them or reject them
// before parse_ticks was ever called, and the test would end up measuring
// MoonBit's string handling instead of the adapter.
//
// Expected values come from docs/planning/02_SPEC.md 2.1/2.3/3.1 and the T3
// task card, not from reading ticks_input/parse.mbt back.

///|
/// Assemble raw bytes without a `String` detour.
fn t3_bytes(parts : Array[Byte]) -> Bytes {
  Bytes::from_array(parts)
}

///|
/// `"0\n"` repeated `count` times. Reaches the record ceiling from memory, so
/// no oversized fixture has to be written into the repository.
fn t3_repeat_records(count : Int) -> Bytes {
  let raw : Array[Byte] = []
  for i = 0; i < count; i = i + 1 {
    raw.push(b'0')
    raw.push(b'\n')
  }
  Bytes::from_array(raw)
}

///|
/// Assert that the bytes are accepted and that the two result arrays agree.
fn t3_expect_ok(name : String, bytes : Bytes) -> @ticks_input.ParsedInput {
  match @ticks_input.parse_ticks(bytes) {
    Ok(parsed) => {
      if parsed.times.length() != parsed.start_lines.length() {
        abort(
          name +
          ": times and start_lines must stay the same length, got " +
          parsed.times.length().to_string() +
          " and " +
          parsed.start_lines.length().to_string(),
        )
      }
      parsed
    }
    Err(error) =>
      abort(name + ": expected an accepted input, got " + error.kind.code())
  }
}

///|
/// Assert that the bytes are rejected as `INPUT_INVALID` at exactly `line`.
/// The failure message carries the case name so one broken row of the matrix
/// is attributable without re-running each case by hand.
fn t3_expect_input_invalid(name : String, bytes : Bytes, line : Int) -> Unit {
  match @ticks_input.parse_ticks(bytes) {
    Ok(_) => abort(name + ": expected a rejection, got an accepted input")
    Err(error) => {
      let code = error.kind.code()
      if code != "INPUT_INVALID" {
        abort(name + ": expected INPUT_INVALID, got " + code)
      }
      if error.line != line {
        abort(
          name +
          ": expected line " +
          line.to_string() +
          ", got " +
          error.line.to_string(),
        )
      }
    }
  }
}

///|
/// Assert that the bytes are rejected with an exact kind, code and line.
fn t3_expect_error(
  name : String,
  bytes : Bytes,
  kind : @ticks_input.InputErrorKind,
  code : String,
  line : Int,
) -> Unit {
  match @ticks_input.parse_ticks(bytes) {
    Ok(_) => abort(name + ": expected a rejection, got an accepted input")
    Err(error) => {
      if error.kind != kind {
        abort(name + ": wrong error kind; expected " + code + " at line " + line.to_string())
      }
      if error.kind.code() != code {
        abort(
          name +
          ": expected code " +
          code +
          ", got " +
          error.kind.code(),
        )
      }
      if error.line != line {
        abort(
          name +
          ": expected line " +
          line.to_string() +
          ", got " +
          error.line.to_string(),
        )
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 1. Physical line numbers and boundaries.
// ---------------------------------------------------------------------------

///|
test "LF and CRLF report the same times on the same physical lines" {
  let lf = t3_expect_ok("0\\n15\\n", t3_bytes([b'0', b'\n', b'1', b'5', b'\n']))
  assert_eq(lf.times, [0L, 15L])
  assert_eq(lf.start_lines, [1, 2])
  // The second record has no trailing newline: a final line without a
  // terminator is still one record.
  let crlf = t3_expect_ok("0\\r\\n15", t3_bytes([b'0', b'\r', b'\n', b'1', b'5']))
  assert_eq(crlf.times, [0L, 15L])
  assert_eq(crlf.start_lines, [1, 2])
}

///|
test "a lone LF and a lone CRLF are each an empty line 1" {
  // Neither is a record: the terminator ends a line whose body is empty.
  // Dropping empty lines is exactly the split behaviour SPEC 3.1 forbids.
  t3_expect_error(
    "lone LF",
    t3_bytes([b'\n']),
    @ticks_input.BlankLine,
    "INPUT_INVALID",
    1,
  )
  t3_expect_error(
    "lone CRLF",
    t3_bytes([b'\r', b'\n']),
    @ticks_input.BlankLine,
    "INPUT_INVALID",
    1,
  )
}

///|
test "0\\n\\n is rejected at line 2 with no partial success" {
  let bytes = t3_bytes([b'0', b'\n', b'\n'])
  t3_expect_error("0\\n\\n", bytes, @ticks_input.BlankLine, "INPUT_INVALID", 2)
  // The whole input fails: the accepted first record must not be handed back
  // as a partial ParsedInput.
  match @ticks_input.parse_ticks(bytes) {
    Ok(parsed) =>
      abort(
        "a rejected input produced " + parsed.times.length().to_string() + " records",
      )
    Err(_) => ()
  }
}

///|
test "every accepted input reports equally long time and line arrays" {
  // t3_expect_ok enforces this; the cases below give it something to check on
  // both terminator styles and on the empty sequence.
  assert_eq(t3_expect_ok("empty", t3_bytes([])).times.length(), 0)
  assert_eq(t3_expect_ok("one LF", t3_bytes([b'7', b'\n'])).times, [7L])
  assert_eq(
    t3_expect_ok("three CRLF", t3_bytes([b'7', b'\r', b'\n', b'8', b'\r', b'\n', b'9'])).start_lines,
    [1, 2, 3],
  )
}

// ---------------------------------------------------------------------------
// 2. Raw byte rejections.
// ---------------------------------------------------------------------------

///|
test "BOM, non-ASCII, invalid UTF-8, header, quotes, commas and isolated CR" {
  // The BOM is a single invisible prefix on an otherwise valid record.
  t3_expect_input_invalid(
    "UTF-8 BOM",
    t3_bytes([b'\xEF', b'\xBB', b'\xBF', b'0', b'\n']),
    1,
  )
  // Two-byte and three-byte UTF-8 sequences, as raw bytes.
  t3_expect_input_invalid(
    "two-byte UTF-8 (U+00E9)",
    t3_bytes([b'1', b'\xC3', b'\xA9', b'\n']),
    1,
  )
  t3_expect_input_invalid(
    "three-byte UTF-8 (U+4E2D)",
    t3_bytes([b'\xE4', b'\xB8', b'\xAD', b'0', b'\n']),
    1,
  )
  // A single byte that cannot start any UTF-8 sequence.
  t3_expect_input_invalid("illegal UTF-8 0xFF", t3_bytes([b'0', b'\xFF', b'\n']), 1)
  t3_expect_input_invalid("illegal UTF-8 continuation 0x80", t3_bytes([b'\x80', b'\n']), 1)
  // A header row is just a non-numeric token.
  t3_expect_input_invalid(
    "timestamp_ms header",
    t3_bytes([
      b't', b'i', b'm', b'e', b's', b't', b'a', b'm', b'p', b'_', b'm', b's', b'\n',
    ]),
    1,
  )
  t3_expect_input_invalid(
    "quoted value",
    t3_bytes([b'"', b'1', b'5', b'"', b'\n']),
    1,
  )
  t3_expect_input_invalid(
    "comma separated row",
    t3_bytes([b'0', b',', b'1', b'5', b'\n']),
    1,
  )
  // An isolated CR is not a terminator, so it stays inside the token.
  t3_expect_input_invalid(
    "isolated CR inside line 1",
    t3_bytes([b'0', b'\r', b'1', b'\n']),
    1,
  )
  t3_expect_input_invalid(
    "isolated CR inside line 2",
    t3_bytes([b'0', b'\n', b'1', b'\r', b'2', b'\n']),
    2,
  )
}

///|
test "a rejected byte keeps the physical line it appeared on" {
  // A BOM on line 2 of an otherwise valid file, and a non-ASCII byte on line
  // 3: the reported line is the physical line, not the record count so far.
  t3_expect_input_invalid(
    "BOM on line 2",
    t3_bytes([b'0', b'\n', b'\xEF', b'\xBB', b'\xBF', b'1', b'\n']),
    2,
  )
  t3_expect_input_invalid(
    "non-ASCII on line 3",
    t3_bytes([b'0', b'\n', b'1', b'\n', b'\xC3', b'\xA9', b'\n']),
    3,
  )
  // The blank line is reported as an empty line, not as an invalid token.
  t3_expect_error(
    "blank line 3",
    t3_bytes([b'0', b'\n', b'1', b'\n', b'\n']),
    @ticks_input.BlankLine,
    "INPUT_INVALID",
    3,
  )
}

// ---------------------------------------------------------------------------
// 3. Token length is checked before content, and before the Int64 range.
// ---------------------------------------------------------------------------

///|
test "20 bytes is judged on content, 21 bytes is rejected on length alone" {
  // 20 bytes, the longest accepted token, at the Int64 minimum.
  assert_eq(
    t3_expect_ok(
      "-9223372036854775808",
      t3_bytes([
        b'-', b'9', b'2', b'2', b'3', b'3', b'7', b'2', b'0', b'3', b'6', b'8', b'5',
        b'4', b'7', b'7', b'5', b'8', b'0', b'8', b'\n',
      ]),
    ).times,
    [-9223372036854775807L - 1L],
  )
  // 20 bytes, well formed digits, past the Int64 upper bound: a content error,
  // not a length error.
  t3_expect_error(
    "20-digit overflow",
    t3_bytes([
      b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'9',
      b'9', b'9', b'9', b'9', b'9', b'9', b'9', b'\n',
    ]),
    @ticks_input.InvalidToken,
    "INPUT_INVALID",
    1,
  )
  // 21 bytes with no digit past the first: if length were checked after
  // content it would still be rejected, so this case alone would not prove the
  // order. The case that does is below.
  t3_expect_error(
    "21 bytes of trailing zeros",
    t3_bytes([
      b'1', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0',
      b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'\n',
    ]),
    @ticks_input.OverlongToken,
    "RESOURCE_LIMIT",
    1,
  )
}

///|
test "a 21 byte token containing illegal characters is still RESOURCE_LIMIT" {
  // The decisive ordering case: 20 zeros followed by a comma is 21 bytes and
  // also contains a character that is illegal in any token. Length wins, so
  // the result is OverlongToken / RESOURCE_LIMIT rather than INPUT_INVALID.
  // It sits on line 2 so the reported line is the physical line, not line 1.
  t3_expect_error(
    "21 bytes with a comma",
    t3_bytes([
      b'0', b'\n', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0',
      b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b',', b'\n',
    ]),
    @ticks_input.OverlongToken,
    "RESOURCE_LIMIT",
    2,
  )
  // The same shape with only 20 bytes is a content error, which is what makes
  // the length-first rule observable.
  t3_expect_error(
    "20 bytes with a comma",
    t3_bytes([
      b'0', b'\n', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0',
      b'0', b'0', b'0', b'0', b'0', b'0', b'0', b'0', b',', b'\n',
    ]),
    @ticks_input.InvalidToken,
    "INPUT_INVALID",
    2,
  )
}

// ---------------------------------------------------------------------------
// 4 and 5. Library-level ceilings. These call parse_ticks directly, so the
// CLI's read path is not involved; T1 covered the read path on the real
// binary and is not repeated here.
// ---------------------------------------------------------------------------

///|
test "the library accepts 250000 records and rejects the 250001st" {
  // The ceiling constant is private, so the boundary itself is the assertion:
  // exactly 250000 records must be accepted, which pins the value to SPEC
  // section 5 without widening the package's public surface for a test.
  let accepted = t3_expect_ok("250000 records", t3_repeat_records(250000))
  assert_eq(accepted.times.length(), 250000)
  assert_eq(accepted.start_lines.length(), 250000)
  assert_eq(accepted.start_lines[249999], 250000)
  // One record past the ceiling. The line is the offending record's physical
  // line, and no partial ParsedInput is returned.
  t3_expect_error(
    "250001 records",
    t3_repeat_records(250001),
    @ticks_input.TooManyRecords,
    "RESOURCE_LIMIT",
    250001,
  )
}

///|
test "the library rejects 32 MiB + 1 bytes and admits exactly 32 MiB" {
  let limit = 33554432
  // 32 MiB + 1: over the byte ceiling. This failure is a property of the whole
  // input rather than of one record, so it carries no line.
  t3_expect_error(
    "32 MiB + 1 bytes",
    Bytes::make(limit + 1, b'0'),
    @ticks_input.TooManyBytes,
    "RESOURCE_LIMIT",
    0,
  )
  // Exactly 32 MiB is not over the ceiling: the byte gate lets it through and
  // the per-line rules then reject the single 32 MiB token as over-long. If
  // the gate were `>=` instead of `>`, this case would report TooManyBytes.
  t3_expect_error(
    "32 MiB exactly",
    Bytes::make(limit, b'0'),
    @ticks_input.OverlongToken,
    "RESOURCE_LIMIT",
    1,
  )
}
