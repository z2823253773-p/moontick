// MoonTick entry point: parse, read, audit, render, exit.
//
// Everything environment-facing lives here. `core` never touches a file, the
// shell, the network or the clock. See docs/planning/02_SPEC.md section 3.

///|
/// `exit` from libc. A MoonBit `main` cannot return a status, so the product
/// exit-code contract is delivered through this boundary and only ever after
/// the report has been flushed to stdout.
extern "C" fn exit_with(code : Int) = "exit"

///|
/// Exit codes from SPEC section 3.2.
let exit_pass : Int = 0

///|
let exit_data_problems : Int = 1

///|
let exit_usage_or_input : Int = 2

///|
let exit_io : Int = 3

///|
let exit_internal : Int = 4

///|
fn version_text() -> String {
  "moontick 0.1.0"
}

///|
/// Report an error that happened after the arguments parsed.
///
/// The output format is known here, so JSON mode writes one `moontick.error.v1`
/// document to stdout and text mode writes a diagnostic line to stderr with
/// stdout left empty. Neither echoes the input contents or an absolute path.
fn report_error(
  as_json : Bool,
  code : String,
  message : String,
  record_index : Int?,
  line : Int?,
) -> Unit {
  if as_json {
    println(@report.render_error(code, message, record_index, line))
  } else {
    eprintln("moontick: " + code + ": " + message)
  }
}

///|
/// Audit one file and print the report. Returns the process exit code.
fn run_check(arguments : CheckArgs) -> Int {
  let as_json = arguments.format is Json
  let bytes = match @ticks_input.read_ticks(arguments.path) {
    Ok(value) => value
    Err(error) => {
      let code = error.kind.code()
      let message = error.kind.message()
      // A file that could not be read has no record and no line to point at.
      report_error(as_json, code, message, None, None)
      return if code == "RESOURCE_LIMIT" {
        exit_usage_or_input
      } else {
        exit_io
      }
    }
  }
  let parsed = match @ticks_input.parse_ticks(bytes) {
    Ok(value) => value
    Err(error) => {
      let code = error.kind.code()
      let message = error.kind.message()
      // One bad record rejects the whole input, and that record *is* the
      // location: its 1-based record number equals the physical line the
      // adapter stopped on. A byte or record limit is not tied to one line, so
      // both position fields stay absent.
      if error.line == 0 {
        report_error(as_json, code, message, None, None)
      } else {
        report_error(as_json, code, message, Some(error.line), Some(error.line))
      }
      return exit_usage_or_input
    }
  }
  let grid = match @core.make_grid(
    arguments.start_ms,
    arguments.end_ms,
    arguments.step_ms,
  ) {
    Ok(value) => value
    Err(error) => {
      let code = error.code()
      let message = error.message()
      // A bad plan is a property of the invocation, not of any record.
      report_error(as_json, code, message, None, None)
      return exit_usage_or_input
    }
  }
  match @core.audit(parsed.times, grid, arguments.detail_limit) {
    Err(error) => {
      let code = error.code()
      let message = error.message()
      report_error(as_json, code, message, None, None)
      exit_usage_or_input
    }
    Ok(report) => {
      let rendered = if as_json {
        @report.try_render_json(report, parsed.start_lines)
      } else {
        @report.try_render_text(report, parsed.start_lines)
      }
      match rendered {
        Ok(text) => println(text)
        Err(message) => {
          // The render layer rejected its own inputs, which no user action can
          // cause. Reporting this as a usage or data error would let an
          // internal defect masquerade as a finding about the input.
          eprintln("moontick: INTERNAL: " + message)
          return exit_internal
        }
      }
      if report.passed {
        exit_pass
      } else {
        exit_data_problems
      }
    }
  }
}

///|
fn main {
  let arguments = @env.args()
  // Drop the executable prefix: the parser sees only real arguments.
  let rest : Array[String] = []
  for i = 1; i < arguments.length(); i = i + 1 {
    rest.push(arguments[i])
  }
  let code = match parse_args(rest) {
    Err(error) => {
      // The arguments never parsed, so the output format is unknown and the
      // error goes to stderr only.
      eprintln("moontick: USAGE: " + error.message())
      eprintln("run `moontick --help` for usage")
      exit_usage_or_input
    }
    Ok(ShowHelp) => {
      println(help_text())
      exit_pass
    }
    Ok(ShowVersion) => {
      println(version_text())
      exit_pass
    }
    Ok(Check(arguments)) => run_check(arguments)
  }
  exit_with(code)
}
