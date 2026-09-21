// The ticks adapter: raw bytes in, timestamps plus 1-based physical line numbers
// out. It knows nothing about sampling plans, so it can be reused by any caller
// that supplies its own grid. See docs/planning/02_SPEC.md section 3.1.

///|
/// Longest accepted timestamp token, excluding the line terminator.
let max_token_bytes : Int = 20

///|
/// Largest accepted input for one run.
let max_input_bytes : Int = 33554432

///|
/// Most records accepted for one run.
let max_records : Int = 250000

///|
let i64_min : Int64 = -9223372036854775807L - 1L

///|
/// Why a byte sequence was rejected. Nothing is ever silently skipped.
pub(all) enum InputErrorKind {
  BlankLine
  OverlongToken
  InvalidToken
  TooManyRecords
  TooManyBytes
} derive(Eq, Debug)

///|
pub fn InputErrorKind::code(self : InputErrorKind) -> String {
  match self {
    BlankLine => "INPUT_INVALID"
    OverlongToken => "RESOURCE_LIMIT"
    InvalidToken => "INPUT_INVALID"
    TooManyRecords => "RESOURCE_LIMIT"
    TooManyBytes => "RESOURCE_LIMIT"
  }
}

///|
pub fn InputErrorKind::message(self : InputErrorKind) -> String {
  match self {
    BlankLine => "blank lines are not records"
    OverlongToken => "timestamp token exceeds 20 bytes"
    InvalidToken =>
      "timestamp is not a canonical signed 64-bit millisecond value"
    TooManyRecords => "record count exceeds the 250000 limit"
    TooManyBytes => "input exceeds the 33554432 byte limit"
  }
}

///|
/// A rejected input. `line` is the 1-based physical line, or 0 when the failure
/// cannot be tied to a single line.
pub struct InputError {
  kind : InputErrorKind
  line : Int
}

///|
/// Accepted records plus the 1-based physical line each came from. The two
/// arrays always have the same length.
pub struct ParsedInput {
  times : Array[Int64]
  start_lines : Array[Int]
}

///|
/// Order the digit slice `[start, end)` against `bound`, an unsigned decimal
/// string. Returns -1, 0 or 1. Both sides are known to be ASCII digits.
///
/// This compares bytes one at a time rather than building a `String` and using
/// `<` / `>`. In this MoonBit version `String` comparison is *not* lexicographic
/// for two equal-length digit runs: it compares them numerically, so
/// `"9223372036854775807" > "9223372036854775807"` evaluates to `true`. A bound
/// check written that way therefore rejects every 19-digit value, including
/// `i64_max`, with no arithmetic overflow to blame. Staying on bytes keeps the
/// check exact, allocation-free, and free of any `Double` conversion.
fn compare_digits(node : Bytes, start : Int, end : Int, bound : String) -> Int {
  let length = end - start
  let bound_length = bound.length()
  if length != bound_length {
    if length < bound_length {
      return -1
    } else {
      return 1
    }
  }
  for i = 0; i < length; i = i + 1 {
    // `bound[i]` is a `UInt16`; both sides reduce to the digit value 0..9.
    let digit = node.at(start + i).to_int() - 48
    let target = bound[i].to_int() - 48
    if digit != target {
      if digit < target {
        return -1
      } else {
        return 1
      }
    }
  }
  0
}

///|
/// Parse one token in the canonical integer form of SPEC 2.1: `0`, or `-`
/// followed by a non-zero leading digit. Rejects `+1`, `-0`, `01`, whitespace,
/// floats, exponents, and any value outside the Int64 range.
fn parse_canonical(node : Bytes, start : Int, end : Int) -> Int64? {
  let length = end - start
  if length == 0 || length > max_token_bytes {
    return None
  }
  let mut position = start
  let mut negative = false
  if node.at(position) == b'-' {
    negative = true
    position = position + 1
  }
  let digits = end - position
  if digits == 0 {
    return None
  }
  let first = node.at(position)
  if first == b'0' {
    // `0` is the only accepted form that starts with a zero.
    if digits != 1 || negative {
      return None
    }
    return Some(0L)
  }
  if first < b'1' || first > b'9' {
    return None
  }
  let mut i = position
  while i < end {
    let byte = node.at(i)
    if byte < b'0' || byte > b'9' {
      return None
    }
    i = i + 1
  }
  if digits > 19 {
    return None
  }
  if digits == 19 {
    // Only a 19-digit magnitude can reach past Int64. The largest magnitude is
    // i64_max (9223372036854775807), and the negative side additionally admits
    // |i64_min| = 9223372036854775808.
    let bound = if negative {
      "9223372036854775808"
    } else {
      "9223372036854775807"
    }
    let order = compare_digits(node, position, end, bound)
    if order > 0 {
      return None
    }
    if negative && order == 0 {
      // |i64_min| does not fit in an Int64, so return it without negating.
      return Some(i64_min)
    }
  }
  let mut value : Int64 = 0L
  i = position
  while i < end {
    value = value * 10L + (node.at(i).to_int() - 48).to_int64()
    i = i + 1
  }
  if negative {
    Some(-value)
  } else {
    Some(value)
  }
}

///|
/// Parse one physical line. `terminated` says whether the line ended in LF, so
/// that a CRLF terminator can be recognised while an isolated CR stays part of
/// the token and is rejected.
fn parse_line(
  bytes : Bytes,
  start : Int,
  end : Int,
  terminated : Bool,
  line : Int,
) -> Result[Int64, InputError] {
  let mut limit = end
  if terminated && limit > start && bytes.at(limit - 1) == b'\r' {
    limit = limit - 1
  }
  let length = limit - start
  if length == 0 {
    return Err({ kind: BlankLine, line: line })
  }
  if length > max_token_bytes {
    return Err({ kind: OverlongToken, line: line })
  }
  match parse_canonical(bytes, start, limit) {
    Some(value) => Ok(value)
    None => Err({ kind: InvalidToken, line: line })
  }
}

///|
/// Parse a whole ticks file.
///
/// Accepts LF and CRLF endings, an optional single trailing newline, and a
/// completely empty file (a valid empty sequence). Rejects blank lines,
/// non-canonical tokens, and the byte and record limits. The first bad record
/// fails the whole input: no partial report is ever produced.
pub fn parse_ticks(bytes : Bytes) -> Result[ParsedInput, InputError] {
  let total = bytes.length()
  if total > max_input_bytes {
    return Err({ kind: TooManyBytes, line: 0 })
  }
  let times : Array[Int64] = []
  let start_lines : Array[Int] = []
  let mut line = 1
  let mut line_start = 0
  let mut i = 0
  while i < total {
    if bytes.at(i) == b'\n' {
      match parse_line(bytes, line_start, i, true, line) {
        Ok(value) => {
          if times.length() >= max_records {
            return Err({ kind: TooManyRecords, line: line })
          }
          times.push(value)
          start_lines.push(line)
        }
        Err(error) => return Err(error)
      }
      line = line + 1
      line_start = i + 1
    }
    i = i + 1
  }
  if line_start < total {
    match parse_line(bytes, line_start, total, false, line) {
      Ok(value) => {
        if times.length() >= max_records {
          return Err({ kind: TooManyRecords, line: line })
        }
        times.push(value)
        start_lines.push(line)
      }
      Err(error) => return Err(error)
    }
  }
  Ok({ times: times, start_lines: start_lines })
}
