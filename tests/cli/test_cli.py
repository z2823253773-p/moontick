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


class CliContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not BIN:
            raise unittest.SkipTest("MOONTICK_BIN is not set")
        if not Path(BIN).is_file():
            raise unittest.SkipTest(f"MOONTICK_BIN does not exist: {BIN}")

    def check_ticks(self, text, extra=None):
        """Write `text` to a scratch .ticks file and run `check` on it."""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ticks"
            path.write_text(text, encoding="utf-8")
            args = ["check", str(path)] + WINDOW + ["--format", "json"]
            if extra:
                args += extra
            return run(args)

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


if __name__ == "__main__":
    unittest.main(verbosity=2)
