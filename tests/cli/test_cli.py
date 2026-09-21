#!/usr/bin/env python3
"""Process-level checks against the real compiled MoonTick executable.

These run the actual binary and assert on its stdout, stderr and exit status.
A `moon run` wrapper exit code is not the product's exit code, so nothing here
goes through the wrapper.

Set MOONTICK_BIN to the absolute path of the built executable, for example:

    MOONTICK_BIN=$PWD/_build/native/debug/build/cmd/moontick/moontick.exe \\
        python3 tests/cli/test_cli.py

This file is a test harness only. It is not a product dependency and nothing in
the shipped module imports it.
"""

import json
import os
import socket
import subprocess
import tempfile
import unittest
from pathlib import Path

BIN = os.environ.get("MOONTICK_BIN")

WINDOW = ["--start-ms", "0", "--end-ms", "60", "--step-ms", "15"]


def run(args, cwd=None):
    return subprocess.run(
        [BIN] + args, capture_output=True, text=True, timeout=30, cwd=cwd
    )


class RealBinaryTest(unittest.TestCase):
    """Shared setup: every case here drives the compiled executable."""

    def check_ticks(self, text, extra=None):
        """Write `text` to a scratch .ticks file and run `check` on it."""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text(text, encoding="utf-8")
            args = ["check", str(path)] + WINDOW + ["--format", "json"]
            if extra:
                args += extra
            return run(args)

    def check_text(self, text, extra=None, explicit=True, window=None):
        """Run `check` in text mode and return the finished process.

        `explicit=False` omits `--format` entirely, which is how the default
        format is exercised: the default must be text, not a fallback.
        `window` overrides the shared `[0,60)` step-15 plan. The counterexamples
        below need grids whose points are neither all covered nor all missing,
        which the shared plan cannot express.
        """
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text(text, encoding="utf-8")
            args = ["check", str(path)] + (WINDOW if window is None else window)
            if explicit:
                args += ["--format", "text"]
            if extra:
                args += extra
            return run(args)


class CliContract(RealBinaryTest):
    def report(self, text, extra=None):
        result = self.check_ticks(text, extra)
        self.assertEqual(result.stderr, "", result.stderr)
        return json.loads(result.stdout)

    # -- the three T1 behaviour cases -------------------------------------

    def test_full_coverage_passes_with_exit_zero(self):
        result = self.check_ticks("0\n15\n30\n45\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["schema"], "moontick.audit.v1")
        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["unit"], "ms")
        self.assertEqual(report["summary"]["expected_points"], "4")
        self.assertEqual(report["summary"]["covered_points"], "4")
        self.assertEqual(report["summary"]["missing_points"], "0")
        self.assertEqual(report["missing_ranges"], [])

    def test_empty_file_is_entirely_missing(self):
        # A zero-byte file is a valid empty sequence, not a format error.
        result = self.check_ticks("")
        self.assertEqual(result.returncode, 1, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["summary"]["input_records"], "0")
        self.assertEqual(report["summary"]["expected_points"], "4")
        self.assertEqual(report["summary"]["covered_points"], "0")
        self.assertEqual(report["summary"]["missing_points"], "4")
        self.assertEqual(report["missing_ranges"], [["0", "4"]])
        self.assertEqual(report["summary"]["longest_missing_run"], "4")

    def test_one_missing_point_is_located(self):
        result = self.check_ticks("0\n30\n45\n")
        self.assertEqual(result.returncode, 1, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["summary"]["covered_points"], "3")
        self.assertEqual(report["summary"]["missing_points"], "1")
        self.assertEqual(report["missing_ranges"], [["1", "2"]])

    # -- classification and positioning -----------------------------------

    def test_duplicate_does_not_fill_the_missing_slot(self):
        result = self.check_ticks("0\n15\n15\n45\n")
        self.assertEqual(result.returncode, 1, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["summary"]["covered_points"], "3")
        self.assertEqual(report["summary"]["missing_points"], "1")
        self.assertEqual(report["summary"]["duplicate_extra_records"], "1")
        self.assertEqual(report["missing_ranges"], [["2", "3"]])
        self.assertEqual(
            report["duplicates"],
            [{"timestamp_ms": "15", "record_index": 3, "line": 3}],
        )

    def test_out_of_range_and_off_grid_are_separate(self):
        report = self.report("0\n15\n30\n45\n60\n")
        self.assertEqual(report["summary"]["out_of_range_records"], "1")
        self.assertEqual(report["summary"]["off_grid_records"], "0")
        self.assertEqual(
            report["out_of_range"],
            [{"timestamp_ms": "60", "record_index": 5, "line": 5}],
        )

    def test_big_integers_keep_every_digit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "big.ticks"
            path.write_text("9007199254740993\n", encoding="utf-8")
            result = run(
                [
                    "check",
                    str(path),
                    "--start-ms",
                    "9007199254740993",
                    "--end-ms",
                    "9007199254740997",
                    "--step-ms",
                    "1",
                    "--format",
                    "json",
                ]
            )
        self.assertEqual(result.returncode, 1, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["grid"]["start_ms"], "9007199254740993")
        self.assertEqual(report["summary"]["expected_points"], "4")
        self.assertEqual(report["summary"]["missing_points"], "3")
        self.assertEqual(report["missing_ranges"], [["1", "4"]])

    # -- input errors ------------------------------------------------------

    def test_blank_line_is_an_input_error_with_a_line_number(self):
        result = self.check_ticks("0\n\n")
        self.assertEqual(result.returncode, 2, result.stderr)
        error = json.loads(result.stdout)
        self.assertEqual(error["schema"], "moontick.error.v1")
        self.assertEqual(error["code"], "INPUT_INVALID")
        self.assertEqual(error["line"], 2)
        self.assertNotIn("summary", error)

    def test_a_bad_token_fails_the_whole_input(self):
        result = self.check_ticks("0\n15\nbad\n30\n")
        self.assertEqual(result.returncode, 2, result.stderr)
        error = json.loads(result.stdout)
        self.assertEqual(error["code"], "INPUT_INVALID")
        self.assertEqual(error["line"], 3)

    def test_isolated_carriage_return_is_rejected(self):
        result = self.check_ticks("0\r1\n")
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(json.loads(result.stdout)["code"], "INPUT_INVALID")

    def check_raw_ticks(self, data):
        """Run `check` over bytes that are deliberately not valid UTF-8.

        `check_ticks` encodes text as UTF-8, which cannot express a BOM or a
        malformed sequence. Writing the bytes directly is the only way to test
        what the file-reading path does with them, and that path is where a
        byte-preserving bug would hide: if the file were decoded to a `String`
        first, these inputs would be rejected or mangled before the parser ever
        saw them.
        """
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_bytes(data)
            return run(["check", str(path)] + WINDOW + ["--format", "json"])

    def test_raw_bytes_are_rejected_verbatim_with_a_line_number(self):
        cases = [
            ("BOM on line 1", b"\xef\xbb\xbf0\n", 1),
            ("BOM on line 2", b"0\n\xef\xbb\xbf1\n", 2),
            ("invalid UTF-8 byte", b"0\n\xff\n", 2),
            ("non-ASCII UTF-8", b"0\n\xe4\xb8\xad\n", 2),
        ]
        for name, data, expected_line in cases:
            with self.subTest(case=name):
                result = self.check_raw_ticks(data)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertEqual(result.stderr, "")
                error = json.loads(result.stdout)
                self.assertEqual(error["schema"], "moontick.error.v1")
                self.assertEqual(error["code"], "INPUT_INVALID")
                # The physical line of the offending bytes, not the count of
                # records accepted so far.
                self.assertEqual(error["line"], expected_line)

    # -- configuration errors ---------------------------------------------

    def test_invalid_step_is_a_config_error(self):
        for step in ["0", "-15"]:
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "input.ticks"
                path.write_text("0\n", encoding="utf-8")
                result = run(
                    [
                        "check",
                        str(path),
                        "--start-ms",
                        "0",
                        "--end-ms",
                        "60",
                        "--step-ms",
                        step,
                        "--format",
                        "json",
                    ]
                )
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertEqual(json.loads(result.stdout)["code"], "CONFIG_INVALID")

    def test_non_whole_period_window_is_a_config_error(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text("0\n", encoding="utf-8")
            result = run(
                [
                    "check",
                    str(path),
                    "--start-ms",
                    "0",
                    "--end-ms",
                    "61",
                    "--step-ms",
                    "15",
                    "--format",
                    "json",
                ]
            )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(json.loads(result.stdout)["code"], "CONFIG_INVALID")

    # -- I/O and usage -----------------------------------------------------

    def test_missing_file_is_an_io_error(self):
        result = run(
            ["check", "/nonexistent/path/input.ticks"] + WINDOW + ["--format", "json"]
        )
        self.assertEqual(result.returncode, 3, result.stderr)
        error = json.loads(result.stdout)
        self.assertEqual(error["schema"], "moontick.error.v1")
        self.assertEqual(error["code"], "IO_ERROR")
        # The error must not leak the absolute path back to stdout.
        self.assertNotIn("/nonexistent", result.stdout)

    def test_help_and_version_need_no_input_file(self):
        for flag in ["--help", "--version"]:
            with tempfile.TemporaryDirectory() as directory:
                result = run([flag], cwd=directory)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotEqual(result.stdout.strip(), "")

    def test_usage_errors_go_to_stderr_only(self):
        # Arguments never parsed, so the output format is unknown: a JSON error
        # document is not promised and stdout must stay empty.
        result = run(["check", "--format", "json"])
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("USAGE", result.stderr)

    def test_unknown_option_is_rejected(self):
        result = self.check_ticks("0\n", extra=["--bogus", "1"])
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("USAGE", result.stderr)

    # -- determinism -------------------------------------------------------

    def test_the_same_input_renders_identical_bytes(self):
        first = self.check_ticks("0\n15\n15\n45\n")
        second = self.check_ticks("0\n15\n15\n45\n")
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(first.returncode, second.returncode)


GOLDEN_DIR = Path(__file__).resolve().parent.parent / "golden"


class TextReport(RealBinaryTest):
    """The default text report. See docs/planning/02_SPEC.md section 4."""

    # -- default format ----------------------------------------------------

    def test_the_default_format_is_a_text_report(self):
        result = self.check_text("0\n15\n30\n45\n", explicit=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        # Not JSON, and not an error: an actual report.
        self.assertNotIn("{", result.stdout)
        self.assertIn("PASS", result.stdout)

    def test_explicit_text_is_byte_identical_to_the_default(self):
        default = self.check_text("0\n15\n30\n45\n", explicit=False)
        explicit = self.check_text("0\n15\n30\n45\n", explicit=True)
        self.assertEqual(default.stdout, explicit.stdout)
        self.assertEqual(default.returncode, explicit.returncode)

    def test_a_problem_file_fails_with_exit_code_one(self):
        result = self.check_text("0\n15\n15\n45\n")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("FAIL", result.stdout)

    def test_the_text_report_is_deterministic(self):
        first = self.check_text("0\n15\n15\n45\n")
        second = self.check_text("0\n15\n15\n45\n")
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(first.returncode, second.returncode)

    def test_the_text_report_carries_the_required_fields(self):
        # 0,15000... no: the window here is [0,60) step 15. Input
        # 0,15,15,45 covers grid indices 0,1,1,3: index 2 is missing.
        result = self.check_text("0\n15\n15\n45\n")
        report = result.stdout
        for fragment in [
            "FAIL",
            "[0,60)",
            "step_ms",
            "15",
            "3/4",  # covered_points / expected_points
            "75.00%",
            "missing",
            "1",
        ]:
            self.assertIn(fragment, report, report)

    def test_the_text_report_names_no_host_or_absolute_path_or_clock(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text("0\n15\n30\n45\n", encoding="utf-8")
            result = run(["check", str(path)] + WINDOW)
        self.assertEqual(result.returncode, 0, result.stderr)
        # A reproducible report must not carry environment-specific values.
        self.assertNotIn(str(path), result.stdout)
        self.assertNotIn(directory, result.stdout)
        self.assertNotIn(socket.gethostname(), result.stdout)
        # No date or time of day.
        self.assertNotRegex(result.stdout, r"\d{4}-\d{2}-\d{2}")
        self.assertNotRegex(result.stdout, r"\d{2}:\d{2}:\d{2}")

    def test_text_reports_do_not_leak_the_input_contents(self):
        result = self.check_text("0\n15\nbad\n30\n")
        self.assertEqual(result.returncode, 2)
        self.assertNotIn("bad", result.stdout)
        self.assertNotIn("bad", result.stderr)

    # -- golden ------------------------------------------------------------

    def test_golden_text_reports(self):
        cases = [
            ("complete", "0\n15\n30\n45\n", 0),
            ("empty", "", 1),
            ("duplicates-and-missing", "0\n15\n15\n45\n", 1),
        ]
        for name, text, expected_code in cases:
            with self.subTest(case=name):
                golden = GOLDEN_DIR / f"text-{name}.txt"
                self.assertTrue(golden.is_file(), f"missing golden {golden}")
                result = self.check_text(text)
                self.assertEqual(result.returncode, expected_code, result.stderr)
                self.assertEqual(result.stdout, golden.read_text(encoding="utf-8"))


class TextErrorChannel(RealBinaryTest):
    """Errors once the arguments have parsed go to stderr in text mode."""

    def text_run(self, text):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text(text, encoding="utf-8")
            return run(["check", str(path)] + WINDOW)

    def test_input_error_goes_to_stderr_with_stdout_empty(self):
        # The path comes first: once the arguments parse, text mode must use
        # stderr even for a data error, and stdout must stay empty.
        result = self.text_run("0\n\n")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("INPUT_INVALID", result.stderr)

    def test_config_error_goes_to_stderr_with_stdout_empty(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text("0\n", encoding="utf-8")
            result = run(
                [
                    "check",
                    str(path),
                    "--start-ms",
                    "0",
                    "--end-ms",
                    "61",
                    "--step-ms",
                    "15",
                ]
            )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("CONFIG_INVALID", result.stderr)

    def test_io_error_goes_to_stderr_with_stdout_empty(self):
        result = run(["check", "/nonexistent/path/input.ticks"] + WINDOW)
        self.assertEqual(result.returncode, 3)
        self.assertEqual(result.stdout, "")
        self.assertIn("IO_ERROR", result.stderr)
        self.assertNotIn("/nonexistent", result.stderr + result.stdout)

    def test_json_mode_still_writes_one_error_document_to_stdout(self):
        result = self.check_ticks("0\n\n")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stderr, "")
        error = json.loads(result.stdout)
        self.assertEqual(error["schema"], "moontick.error.v1")
        self.assertEqual(error["code"], "INPUT_INVALID")

    def test_a_located_input_error_carries_record_index_and_line(self):
        # The bad token sits on physical line 3, which is also record 3.
        result = self.check_ticks("0\n15\nbad\n30\n")
        self.assertEqual(result.returncode, 2)
        error = json.loads(result.stdout)
        self.assertEqual(error["code"], "INPUT_INVALID")
        self.assertEqual(error["record_index"], 3)
        self.assertEqual(error["line"], 3)

    def test_an_unlocated_error_omits_both_position_fields(self):
        # A file that does not exist has no record and no line.
        result = run(
            ["check", "/nonexistent/path/input.ticks"] + WINDOW + ["--format", "json"]
        )
        error = json.loads(result.stdout)
        self.assertEqual(error["code"], "IO_ERROR")
        self.assertNotIn("record_index", error)
        self.assertNotIn("line", error)

    def test_a_config_error_omits_both_position_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text("0\n", encoding="utf-8")
            result = run(
                [
                    "check",
                    str(path),
                    "--start-ms",
                    "0",
                    "--end-ms",
                    "61",
                    "--step-ms",
                    "15",
                    "--format",
                    "json",
                ]
            )
        error = json.loads(result.stdout)
        self.assertEqual(error["code"], "CONFIG_INVALID")
        self.assertNotIn("record_index", error)
        self.assertNotIn("line", error)


class DetailTruncation(RealBinaryTest):
    """`--detail-limit 1` over all five detail categories, via the real binary.

    Grid is [0,60) step 15, so there are four expected points. Each case is a
    separate file and each is built so that exactly one category overflows.
    """

    def check_limited(self, text):
        return self._run(text, ["--detail-limit", "1"])

    def _run(self, text, extra):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text(text, encoding="utf-8")
            return run(
                ["check", str(path)] + WINDOW + ["--format", "json"] + extra
            )

    CASES = [
        # name, ticks text, category, exact count, detail list key
        ("missing_ranges", "0\n30\n", "missing_points", "2", "missing_ranges"),
        (
            "duplicates",
            "0\n0\n0\n15\n30\n45\n",
            "duplicate_extra_records",
            "2",
            "duplicates",
        ),
        (
            "out_of_order",
            "30\n0\n45\n15\n",
            "out_of_order_records",
            "2",
            "out_of_order",
        ),
        (
            "off_grid",
            "0\n1\n2\n15\n30\n45\n",
            "off_grid_records",
            "2",
            "off_grid",
        ),
        (
            "out_of_range",
            "-2\n-1\n0\n15\n30\n45\n",
            "out_of_range_records",
            "2",
            "out_of_range",
        ),
    ]

    def test_each_category_truncates_independently(self):
        for name, text, count_key, count, list_key in self.CASES:
            with self.subTest(category=name):
                result = self.check_limited(text)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertEqual(result.stderr, "")
                report = json.loads(result.stdout)
                # The exact count is unaffected by the display limit.
                self.assertEqual(report["summary"][count_key], count)
                # Truncation is reported for the overflowing category only.
                for key in (
                    "missing_ranges",
                    "duplicates",
                    "out_of_order",
                    "off_grid",
                    "out_of_range",
                ):
                    self.assertEqual(
                        report["details_truncated"][key],
                        key == list_key,
                        f"{name}: details_truncated[{key}]",
                    )
                # detail_limit 1 shows exactly the first detail entry.
                self.assertEqual(len(report[list_key]), 1)

    def test_the_truncated_category_shows_the_first_entry_only(self):
        # The exact first entry per category, so a limit that showed the wrong
        # element (last instead of first, or a sorted-away one) would fail.
        expected = {
            "missing_ranges": [["1", "2"]],
            "duplicates": [{"timestamp_ms": "0", "record_index": 2, "line": 2}],
            "out_of_order": [{"timestamp_ms": "0", "record_index": 2, "line": 2}],
            "off_grid": [{"timestamp_ms": "1", "record_index": 2, "line": 2}],
            "out_of_range": [{"timestamp_ms": "-2", "record_index": 1, "line": 1}],
        }
        for name, text, _count_key, _count, list_key in self.CASES:
            with self.subTest(category=name):
                report = json.loads(self.check_limited(text).stdout)
                self.assertEqual(report[list_key], expected[list_key])

    def test_a_category_at_the_limit_is_not_marked_truncated(self):
        # One duplicate and detail_limit 1: the list is exactly full, which is
        # not truncation. This pins the comparison to `>`, not `>=`.
        report = json.loads(self.check_limited("0\n0\n15\n30\n45\n").stdout)
        self.assertEqual(report["summary"]["duplicate_extra_records"], "1")
        self.assertEqual(len(report["duplicates"]), 1)
        self.assertFalse(report["details_truncated"]["duplicates"])

    def test_a_larger_limit_restores_the_full_details(self):
        full = json.loads(self._run("0\n0\n0\n15\n30\n45\n", []).stdout)
        self.assertEqual(len(full["duplicates"]), 2)
        self.assertFalse(full["details_truncated"]["duplicates"])


class TextAccuracyRegressions(RealBinaryTest):
    """The two text counterexamples from Codex's review of `6d97745`.

    Both are process-level: they are the exact invocations the reviewer ran
    against the compiled executable, kept so the repaired behaviour cannot
    regress silently.
    """

    PERCENT_GRID = ["--start-ms", "0", "--end-ms", "3", "--step-ms", "1"]
    HUNDRED_GRID = ["--start-ms", "0", "--end-ms", "100", "--step-ms", "1"]

    def test_two_of_three_rounds_up_to_the_nearest_hundredth(self):
        # 0 and 1 covered out of [0,3) step 1 is exactly 2/3 = 66.666...%, which
        # SPEC 2.2 wants displayed with two decimals as 66.67%. Trimming the
        # third decimal printed 66.66%.
        result = self.check_text("0\n1\n", window=self.PERCENT_GRID)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("coverage: 2/3 (66.67%)", result.stdout, result.stdout)

    def test_a_whole_percentage_is_not_shaved_by_binary_rounding(self):
        # 57 of 100 covered is exactly 57%, so no rounding decision is involved
        # at all. Scaling the ratio through a Double landed a hair under 5700
        # hundredths and printed 56.99%.
        ticks = "".join(f"{index}\n" for index in range(57))
        result = self.check_text(ticks, window=self.HUNDRED_GRID)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("coverage: 57/100 (57.00%)", result.stdout, result.stdout)

    def test_rounded_up_hundred_percent_still_fails(self):
        # 19999 of 20000 is 99.995%, which displays as 100.00% while one point is
        # missing. SPEC 2.2 names this case: the rounded display must never decide
        # the verdict. The report shows 100.00% and still exits 1 with FAIL.
        ticks = "".join(f"{index}\n" for index in range(19999))
        result = self.check_text(
            ticks, window=["--start-ms", "0", "--end-ms", "20000", "--step-ms", "1"]
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("coverage: 19999/20000 (100.00%)", result.stdout, result.stdout)
        self.assertIn("missing: 1", result.stdout, result.stdout)
        self.assertIn("FAIL", result.stdout, result.stdout)

    def test_missing_range_notice_does_not_pass_off_points_as_ranges(self):
        # [0,100) step 1 with 0 and 50 covered: 98 missing points split over two
        # ranges, [1,50) and [51,100). The notice must not read as "98 missing
        # ranges"; the two quantities are different and are labelled separately.
        result = self.check_text(
            "0\n50\n", extra=["--detail-limit", "1"], window=self.HUNDRED_GRID
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("missing_ranges (truncated):", result.stdout, result.stdout)
        self.assertIn(
            "ranges shown: 1; missing points in total: 98",
            result.stdout,
            result.stdout,
        )
        # The old wording presented the point count as a range count.
        self.assertNotIn("of 98", result.stdout, result.stdout)

    def test_golden_truncated_missing_ranges(self):
        # The three T4 goldens never trigger detail truncation, so the truncated
        # text path had no byte-level golden. This closes that gap.
        golden = GOLDEN_DIR / "text-truncated-missing.txt"
        self.assertTrue(golden.is_file(), f"missing golden {golden}")
        result = self.check_text(
            "0\n50\n", extra=["--detail-limit", "1"], window=self.HUNDRED_GRID
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout, golden.read_text(encoding="utf-8"))


class VersionAndBoundaries(RealBinaryTest):
    """Version text and the documented CLI boundaries."""

    def test_version_keeps_the_version_and_drops_the_development_marker(self):
        result = run(["--version"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("0.1.0", result.stdout)
        # The development-phase marker is gone now that text output lands.
        self.assertNotIn("(T1)", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
