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
  "moontick 0.1.0 (T1)"
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
      if as_json {
        println(@report.render_error(code, message, None, None))
      } else {
        println("moontick: " + code + ": " + message)
      }
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
      // A byte or record limit is not tied to one line; a blank line or a bad
      // token is.
      let line = if error.line == 0 { None } else { Some(error.line) }
      if as_json {
        println(@report.render_error(code, message, None, line))
      } else {
        println("moontick: " + code + ": " + message)
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
      if as_json {
        println(@report.render_error(code, message, None, None))
      } else {
        println("moontick: " + code + ": " + message)
      }
      return exit_usage_or_input
    }
  }
  match @core.audit(parsed.times, grid, arguments.detail_limit) {
    Err(error) => {
      let code = error.code()
      let message = error.message()
      if as_json {
        println(@report.render_error(code, message, None, None))
      } else {
        println("moontick: " + code + ": " + message)
      }
      exit_usage_or_input
    }
    Ok(report) => {
      // T1 renders JSON only. SPEC section 4 puts text rendering in T4; until
      // then a text request fails rather than printing a half-built report and
      // calling it a pass.
      if as_json {
        match @report.try_render_json(report, parsed.start_lines) {
          Ok(text) => println(text)
          Err(message) => {
            // The render layer rejected its own inputs, which no user action
            // can cause. Reporting this as a usage or data error would let an
            // internal defect masquerade as a finding about the input.
            eprintln("moontick: INTERNAL: " + message)
            return exit_internal
          }
        }
      } else {
        println(
          "moontick: CONFIG_INVALID: text output is not implemented in T1; " +
          "use --format json",
        )
        return exit_usage_or_input
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
