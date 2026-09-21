// Argument parsing for the `check` subcommand. See docs/planning/02_SPEC.md
// section 3.2: unknown options, repeated options, missing values and extra
// positional arguments are all usage errors.

///|
/// Default number of detail entries shown per problem category.
pub let default_detail_limit : Int = 1000

///|
/// Output shape requested on the command line.
pub(all) enum OutputFormat {
  Text
  Json
} derive(Eq, Debug)

///|
/// A successfully parsed `check` invocation.
pub struct CheckArgs {
  path : String
  start_ms : Int64
  end_ms : Int64
  step_ms : Int64
  format : OutputFormat
  detail_limit : Int
} derive(Eq, Debug)

///|
/// What the process was asked to do.
pub(all) enum Invocation {
  ShowHelp
  ShowVersion
  Check(CheckArgs)
} derive(Eq, Debug)

///|
/// Argument parsing failed, so no report and no input file are involved. These
/// are always written to stderr, because a JSON error document is only promised
/// once the arguments have parsed.
pub struct UsageError {
  message : String
} derive(Eq, Debug)

///|
pub fn UsageError::message(self : UsageError) -> String {
  self.message
}

///|

///|
/// A failed parse, generic in the success type so the integer helpers can reuse
/// it without wrapping.
fn[T] usage_error(message : String) -> Result[T, UsageError] {
  Err({ message, })
}

///|
/// The help text. Kept beside the parser so the two cannot drift apart.
pub fn help_text() -> String {
  "moontick - audit a fixed-interval sampling plan against observed timestamps\n" +
  "\n" +
  "Usage:\n" +
  "  moontick check <FILE> --start-ms <INT> --end-ms <INT> --step-ms <INT>\n" +
  "                        [--format text|json] [--detail-limit <INT>]\n" +
  "  moontick --help\n" +
  "  moontick --version\n" +
  "\n" +
  "The window is half-open: [start-ms, end-ms). All times are integer\n" +
  "milliseconds. FILE holds one canonical integer per line with no header.\n" +
  "\n" +
  "Options:\n" +
  "  --format <text|json>     report shape, default text\n" +
  "  --detail-limit <INT>     entries shown per problem category, 1..10000,\n" +
  "                           default 1000\n" +
  "\n" +
  "Exit codes:\n" +
  "  0  audit passed, or help/version\n" +
  "  1  audit completed and found data problems\n" +
  "  2  argument, config, input or resource error\n" +
  "  3  I/O failure\n" +
  "  4  internal error"
}

///|
/// Parse an Int64 that must already be in the canonical form of SPEC 2.1:
/// `0`, or `-` followed by a non-zero leading digit. `+1`, `-0`, `01`, spaces,
/// fractions and exponents are rejected, as is anything outside Int64.
fn parse_canonical_int64(text : String) -> Result[Int64, UsageError] {
  let length = text.length()
  if length == 0 || length > 20 {
    return usage_error("--start-ms/--end-ms/--step-ms expect an integer")
  }
  let mut index = 0
  let mut negative = false
  if text[0] == '-' {
    negative = true
    index = 1
  }
  let digits = length - index
  if digits == 0 {
    return usage_error("--start-ms/--end-ms/--step-ms expect an integer")
  }
  if text[index] == '0' {
    if digits != 1 || negative {
      return usage_error(
        "invalid integer: \"" + text + "\" is not a canonical integer",
      )
    }
    return Ok(0L)
  }
  if text[index] < '1' || text[index] > '9' {
    return usage_error(
      "invalid integer: \"" + text + "\" is not a canonical integer",
    )
  }
  let mut i = index
  while i < length {
    let character = text[i]
    if character < '0' || character > '9' {
      return usage_error(
        "invalid integer: \"" + text + "\" is not a canonical integer",
      )
    }
    i = i + 1
  }
  if digits > 19 {
    return usage_error("integer out of range: \"" + text + "\"")
  }
  if digits == 19 {
    // Compare as digits rather than as a number so the boundary check cannot
    // overflow, and never fall back to a floating point conversion.
    let bound = if negative {
      "9223372036854775808"
    } else {
      "9223372036854775807"
    }
    let mut width = 0
    while width < 19 {
      let digit = text[index + width]
      if digit != bound[width] {
        break
      }
      width = width + 1
    }
    if width < 19 {
      if text[index + width] > bound[width] {
        return usage_error("integer out of range: \"" + text + "\"")
      }
    }
    if negative && width == 19 {
      return Ok(-9223372036854775807L - 1L)
    }
  }
  let mut value : Int64 = 0L
  let mut cursor = index
  while cursor < length {
    let digit = text[cursor].to_int() - 48
    value = value * 10L + digit.to_int64()
    cursor = cursor + 1
  }
  if negative {
    Ok(-value)
  } else {
    Ok(value)
  }
}

///|
/// The value of an option that takes one, or a usage error when it is absent.
fn option_value(
  args : Array[String],
  index : Int,
  name : String,
) -> Result[String, UsageError] {
  if index + 1 >= args.length() {
    return usage_error(name + " requires a value")
  }
  let value = args[index + 1]
  if value.length() > 0 &&
    value[0] == '-' &&
    name != "--start-ms" &&
    name != "--end-ms" &&
    name != "--step-ms" {
    return usage_error(name + " requires a value")
  }
  Ok(value)
}

///|
/// Parse the arguments after the program name.
///
/// `--help` and `--version` win wherever they appear and never read a file.
/// Everything else must be one `check` invocation with no leftovers.
pub fn parse_args(args : Array[String]) -> Result[Invocation, UsageError] {
  let mut index = 0
  while index < args.length() {
    match args[index] {
      "--help" | "-h" => return Ok(ShowHelp)
      "--version" | "-V" => return Ok(ShowVersion)
      _ => index = index + 1
    }
  }
  if args.length() == 0 {
    return usage_error("missing subcommand: expected `check`, `--help`")
  }
  if args[0] != "check" {
    return usage_error("unknown subcommand: \"" + args[0] + "\"")
  }
  let mut format : OutputFormat = Text
  let mut detail_limit : Int = default_detail_limit
  let mut seen_format = false
  let mut seen_detail_limit = false
  let mut cursor = 1
  let mut path_value : String = ""
  let mut start_value : Int64 = 0L
  let mut end_value : Int64 = 0L
  let mut step_value : Int64 = 0L
  let mut have_start = false
  let mut have_end = false
  let mut have_step = false
  let mut have_path = false
  while cursor < args.length() {
    let token = args[cursor]
    match token {
      "--start-ms" => {
        if have_start {
          return usage_error("--start-ms given more than once")
        }
        match option_value(args, cursor, token) {
          Ok(text) =>
            match parse_canonical_int64(text) {
              Ok(value) => {
                start_value = value
                have_start = true
              }
              Err(error) => return Err(error)
            }
          Err(error) => return Err(error)
        }
        cursor = cursor + 2
      }
      "--end-ms" => {
        if have_end {
          return usage_error("--end-ms given more than once")
        }
        match option_value(args, cursor, token) {
          Ok(text) =>
            match parse_canonical_int64(text) {
              Ok(value) => {
                end_value = value
                have_end = true
              }
              Err(error) => return Err(error)
            }
          Err(error) => return Err(error)
        }
        cursor = cursor + 2
      }
      "--step-ms" => {
        if have_step {
          return usage_error("--step-ms given more than once")
        }
        match option_value(args, cursor, token) {
          Ok(text) =>
            match parse_canonical_int64(text) {
              Ok(value) => {
                step_value = value
                have_step = true
              }
              Err(error) => return Err(error)
            }
          Err(error) => return Err(error)
        }
        cursor = cursor + 2
      }
      "--format" => {
        if seen_format {
          return usage_error("--format given more than once")
        }
        match option_value(args, cursor, token) {
          Ok(text) =>
            match text {
              "text" => format = Text
              "json" => format = Json
              _ => return usage_error("--format expects `text` or `json`")
            }
          Err(error) => return Err(error)
        }
        seen_format = true
        cursor = cursor + 2
      }
      "--detail-limit" => {
        if seen_detail_limit {
          return usage_error("--detail-limit given more than once")
        }
        match option_value(args, cursor, token) {
          Ok(text) =>
            match parse_canonical_int64(text) {
              Ok(value) => {
                let limit = value.to_int()
                if value < 1L || value > 10000L || limit.to_int64() != value {
                  return usage_error(
                    "--detail-limit must be between 1 and 10000",
                  )
                }
                detail_limit = limit
              }
              Err(_) =>
                return usage_error("--detail-limit must be between 1 and 10000")
            }
          Err(error) => return Err(error)
        }
        seen_detail_limit = true
        cursor = cursor + 2
      }
      _ => {
        if token.length() > 0 && token[0] == '-' {
          return usage_error("unknown option: \"" + token + "\"")
        }
        if have_path {
          return usage_error("unexpected extra argument: \"" + token + "\"")
        }
        path_value = token
        have_path = true
        cursor = cursor + 1
      }
    }
  }
  if !have_path {
    return usage_error("check requires an input file")
  }
  if !have_start || !have_end || !have_step {
    return usage_error("check requires --start-ms, --end-ms and --step-ms")
  }
  Ok(
    Check({
      path: path_value,
      start_ms: start_value,
      end_ms: end_value,
      step_ms: step_value,
      format,
      detail_limit,
    }),
  )
}
