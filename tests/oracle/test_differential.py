#!/usr/bin/env python3
"""Reproducible process-level differential and metamorphic checks.

Run with MOONTICK_BIN set to the absolute path of a native build. The oracle
does not import MoonBit code and never expands the large-grid resource case.
"""

import json
import os
from pathlib import Path
import random
import subprocess
import tempfile
import time

from reference import audit

SEED = 20260920
COUNT = 1000
BIN = Path(os.environ["MOONTICK_BIN"]).resolve()


def invoke(path, times, start, end, step, detail_limit):
    path.write_bytes(("".join(f"{value}\n" for value in times)).encode("ascii"))
    args = [
        str(BIN), "check", str(path),
        "--start-ms", str(start), "--end-ms", str(end), "--step-ms", str(step),
        "--format", "json", "--detail-limit", str(detail_limit),
    ]
    began = time.monotonic()
    process = subprocess.run(args, capture_output=True, text=True, timeout=10)
    elapsed = time.monotonic() - began
    if process.stderr or process.returncode not in (0, 1):
        raise AssertionError((args, process.returncode, process.stdout, process.stderr))
    return json.loads(process.stdout), process.returncode, elapsed


def assert_case(path, case_id, times, start, end, step, detail_limit):
    expected = audit(times, start, end, step, detail_limit)
    actual, code, elapsed = invoke(path, times, start, end, step, detail_limit)
    expected_code = 0 if expected["status"] == "pass" else 1
    if actual != expected or code != expected_code:
        reproduction = {
            "seed": SEED, "case": case_id, "times": times, "start": start,
            "end": end, "step": step, "detail_limit": detail_limit,
            "expected_exit": expected_code, "actual_exit": code,
            "expected": expected, "actual": actual,
        }
        raise AssertionError(json.dumps(reproduction, ensure_ascii=False, indent=2))
    return actual, elapsed


def generate(rng, case_id):
    count = rng.randint(1, 200)
    step = rng.randint(1, 40)
    start = rng.randint(-100000, 100000)
    end = start + count * step
    times = []
    for _ in range(rng.randrange(0, 41)):
        kind = rng.randrange(5)
        if kind == 0 and times:
            value = rng.choice(times)
        elif kind == 1 and step > 1:
            value = start + rng.randrange(count) * step + rng.randrange(1, step)
        elif kind == 2:
            value = start - rng.randrange(1, 4) * step
        elif kind == 3:
            value = end + rng.randrange(0, 4) * step
        else:
            value = start + rng.randrange(count) * step
        times.append(value)
    limit = (1, 2, 5, 1000)[case_id % 4]
    return times, start, end, step, limit


def check_metamorphic(path, case_id, times, start, end, step, limit):
    # Adding an extra copy of an already observed valid point cannot add cover.
    valid = start + (end - start) // (2 * step) * step
    original = times + [valid]
    with_duplicate = original + [valid]
    first, _ = assert_case(path, f"{case_id}-duplicate-base", original, start, end, step, limit)
    second, _ = assert_case(path, f"{case_id}-duplicate", with_duplicate, start, end, step, limit)
    for key in ("covered_points", "missing_points", "longest_missing_run"):
        assert first["summary"][key] == second["summary"][key], (case_id, key)
    assert first["missing_ranges"] == second["missing_ranges"], case_id

    delta = 1000000
    shifted, _ = assert_case(
        path, f"{case_id}-shift", [value + delta for value in times],
        start + delta, end + delta, step, limit,
    )
    base, _ = assert_case(path, f"{case_id}-base", times, start, end, step, limit)
    assert base["summary"] == shifted["summary"], case_id
    assert base["missing_ranges"] == shifted["missing_ranges"], case_id

    reordered = list(reversed(times))
    reordered_result, _ = assert_case(
        path, f"{case_id}-reorder", reordered, start, end, step, limit
    )
    for key in ("covered_points", "missing_points", "duplicate_extra_records"):
        assert base["summary"][key] == reordered_result["summary"][key], (case_id, key)
    assert base["missing_ranges"] == reordered_result["missing_ranges"], case_id


def main():
    if not BIN.is_file():
        raise SystemExit(f"MOONTICK_BIN is not a file: {BIN}")
    rng = random.Random(SEED)
    # First seven expected rows come from the hand-calculated G2 table. They
    # check the oracle itself before comparing it with the executable.
    manual = [
        ([0, 15, 15, 45], (1, 1, 0, 0, 0), [["2", "3"]]),
        ([30, 0, 15, 45], (0, 0, 1, 0, 0), []),
        ([0, 16, 30, 45], (1, 0, 0, 1, 0), [["1", "2"]]),
        ([-15, 0, 15, 30, 45, 60], (0, 0, 0, 0, 2), []),
        ([15, 30], (2, 0, 0, 0, 0), [["0", "1"], ["3", "4"]]),
        ([0, 45], (2, 0, 0, 0, 0), [["1", "3"]]),
        ([60, 60, 0], (3, 1, 1, 0, 2), [["1", "4"]]),
        ([], (4, 0, 0, 0, 0), [["0", "4"]]),
    ]
    with tempfile.TemporaryDirectory(prefix="moontick-oracle-") as directory:
        path = Path(directory) / "case.ticks"
        manual_keys = (
            "missing_points", "duplicate_extra_records", "out_of_order_records",
            "off_grid_records", "out_of_range_records",
        )
        for index, (times, expected_counts, expected_ranges) in enumerate(manual):
            reference = audit(times, 0, 60, 15, 1000)
            actual_counts = tuple(int(reference["summary"][key]) for key in manual_keys)
            assert (actual_counts, reference["missing_ranges"]) == (
                expected_counts, expected_ranges
            ), f"hand table disagrees with oracle at row {index}"
            assert_case(path, f"manual-{index}", times, 0, 60, 15, 1000)
        for index in range(COUNT):
            times, start, end, step, limit = generate(rng, index)
            assert_case(path, index, times, start, end, step, limit)
            if index < 30:
                check_metamorphic(path, index, times, start, end, step, limit)

        # N=10^12 is checked analytically: never call the enumerating oracle.
        huge, code, elapsed = invoke(path, [0, 999999999999], 0, 1000000000000, 1, 1)
        assert code == 1 and huge["summary"]["expected_points"] == "1000000000000"
        assert huge["summary"]["covered_points"] == "2"
        assert huge["summary"]["missing_points"] == "999999999998"
        assert huge["missing_ranges"] == [["1", "999999999999"]]
        assert huge["summary"]["longest_missing_run"] == "999999999998"
        print(f"manual=8 random={COUNT} seed={SEED} metamorphic=30x3 large_N=10^12")
        print(f"large-grid process elapsed={elapsed:.3f}s timeout=10s")


if __name__ == "__main__":
    main()
