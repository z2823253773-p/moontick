// Argument parsing behaviour. These run in-process: the process-level contract
// of stdout, stderr and exit codes is covered by tests/cli/test_cli.py against
// the real executable, because a `moon run` wrapper exit code is not the
// product's exit code.

///|
fn args_of(text : String) -> Array[String] {
  let items : Array[String] = []
  for piece in text.split(" ") {
    if piece.length() > 0 {
      items.push(piece.to_owned())
    }
  }
  items
}

///|
fn check_of(text : String) -> CheckArgs {
  match parse_args(args_of(text)) {
    Ok(Check(arguments)) => arguments
    Ok(_) => abort("expected a check invocation for " + text)
    Err(error) => abort("expected a valid invocation, got " + error.message())
  }
}

///|
fn error_of(text : String) -> String {
  match parse_args(args_of(text)) {
    Ok(_) => "ACCEPTED"
    Err(error) => error.message()
  }
}

///|
test "a complete check invocation parses" {
  let arguments = check_of(
    "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15",
  )
  assert_eq(arguments.path, "a.ticks")
  assert_eq(arguments.start_ms, 0L)
  assert_eq(arguments.end_ms, 60L)
  assert_eq(arguments.step_ms, 15L)
  assert_eq(arguments.format, Text)
  assert_eq(arguments.detail_limit, 1000)
}

///|
test "format and detail-limit are read" {
  let arguments = check_of(
    "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json --detail-limit 5",
  )
  assert_eq(arguments.format, Json)
  assert_eq(arguments.detail_limit, 5)
}

///|
test "negative timestamps parse" {
  let arguments = check_of(
    "check a.ticks --start-ms -30 --end-ms 30 --step-ms 15",
  )
  assert_eq(arguments.start_ms, -30L)
  assert_eq(arguments.end_ms, 30L)
}

///|
test "the Int64 endpoints parse" {
  let arguments = check_of(
    "check a.ticks --start-ms -9223372036854775808 --end-ms 9223372036854775807 --step-ms 1",
  )
  assert_eq(arguments.start_ms, -9223372036854775807L - 1L)
  assert_eq(arguments.end_ms, 9223372036854775807L)
}

///|
test "help and version win over everything else" {
  assert_eq(parse_args(args_of("--help")), Ok(ShowHelp))
  assert_eq(parse_args(args_of("--version")), Ok(ShowVersion))
  assert_eq(parse_args(args_of("check --help")), Ok(ShowHelp))
  assert_eq(parse_args(args_of("nonsense --version")), Ok(ShowVersion))
  assert_eq(parse_args(args_of("--help junk")), Ok(ShowHelp))
}

///|
test "non-canonical integers are rejected" {
  for
    text in [
      "check a.ticks --start-ms +1 --end-ms 60 --step-ms 15", "check a.ticks --start-ms 01 --end-ms 60 --step-ms 15",
      "check a.ticks --start-ms -0 --end-ms 60 --step-ms 15", "check a.ticks --start-ms 1e3 --end-ms 60 --step-ms 15",
      "check a.ticks --start-ms 1.0 --end-ms 60 --step-ms 15", "check a.ticks --start-ms 9223372036854775808 --end-ms 60 --step-ms 15",
      "check a.ticks --start-ms ab --end-ms 60 --step-ms 15",
    ] {
    let message = error_of(text)
    assert_true(message != "ACCEPTED")
  }
}

///|
test "unknown and repeated options are rejected" {
  assert_eq(
    error_of("check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --bogus 1"),
    "unknown option: \"--bogus\"",
  )
  assert_eq(
    error_of("check a.ticks --start-ms 0 --start-ms 0 --end-ms 60 --step-ms 15"),
    "--start-ms given more than once",
  )
  assert_eq(
    error_of(
      "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --format json --format json",
    ),
    "--format given more than once",
  )
}

///|
test "missing values and missing options are rejected" {
  assert_eq(
    error_of("check a.ticks --start-ms 0 --end-ms 60 --step-ms"),
    "--step-ms requires a value",
  )
  assert_eq(
    error_of("check a.ticks --start-ms 0 --end-ms 60"),
    "check requires --start-ms, --end-ms and --step-ms",
  )
  assert_eq(error_of("check --format json"), "check requires an input file")
}

///|
test "extra positionals and unknown subcommands are rejected" {
  assert_eq(
    error_of("check a.ticks b.ticks --start-ms 0 --end-ms 60 --step-ms 15"),
    "unexpected extra argument: \"b.ticks\"",
  )
  assert_eq(error_of("audit a.ticks"), "unknown subcommand: \"audit\"")
  assert_eq(error_of(""), "missing subcommand: expected `check`, `--help`")
}

///|
test "detail-limit is bounded to 1..10000" {
  assert_eq(
    error_of(
      "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --detail-limit 0",
    ),
    "--detail-limit must be between 1 and 10000",
  )
  assert_eq(
    error_of(
      "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --detail-limit 10001",
    ),
    "--detail-limit must be between 1 and 10000",
  )
  assert_eq(
    error_of(
      "check a.ticks --start-ms 0 --end-ms 60 --step-ms 15 --detail-limit 1a",
    ),
    "--detail-limit must be between 1 and 10000",
  )
}
