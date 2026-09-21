"""Independent, deliberately small-grid MoonTick reference model.

This enumerates the declared grid and compares set membership. It must remain
independent of the MoonBit implementation's sorted-index gap algorithm.
"""


def audit(times, start, end, step, detail_limit):
    assert step > 0 and end > start and (end - start) % step == 0
    count = (end - start) // step
    assert 1 <= count <= 200, "reference model only enumerates small grids"
    assert 1 <= detail_limit <= 10000

    positions = [start + step * index for index in range(count)]
    observed = set(times)
    missing_indices = [index for index, value in enumerate(positions) if value not in observed]
    ranges = []
    for index in missing_indices:
        if ranges and ranges[-1][1] == index:
            ranges[-1][1] = index + 1
        else:
            ranges.append([index, index + 1])

    seen = set()
    duplicates = []
    out_of_order = []
    off_grid = []
    out_of_range = []
    for offset, value in enumerate(times):
        record = {"timestamp_ms": str(value), "record_index": offset + 1, "line": offset + 1}
        if value in seen:
            duplicates.append(record)
        seen.add(value)
        if offset and value < times[offset - 1]:
            out_of_order.append(record)
        if value < start or value >= end:
            out_of_range.append(record)
        elif (value - start) % step:
            off_grid.append(record)

    details = {
        "missing_ranges": [[str(first), str(last)] for first, last in ranges],
        "duplicates": duplicates,
        "out_of_order": out_of_order,
        "off_grid": off_grid,
        "out_of_range": out_of_range,
    }
    covered = count - len(missing_indices)
    summary = {
        "input_records": str(len(times)),
        "expected_points": str(count),
        "covered_points": str(covered),
        "missing_points": str(len(missing_indices)),
        "duplicate_extra_records": str(len(duplicates)),
        "out_of_order_records": str(len(out_of_order)),
        "off_grid_records": str(len(off_grid)),
        "out_of_range_records": str(len(out_of_range)),
        "longest_missing_run": str(max((last - first for first, last in ranges), default=0)),
    }
    passed = covered == count and not (duplicates or out_of_order or off_grid or out_of_range)
    return {
        "schema": "moontick.audit.v1",
        "status": "pass" if passed else "fail",
        "unit": "ms",
        "grid": {"start_ms": str(start), "end_ms": str(end), "step_ms": str(step)},
        "summary": summary,
        **{name: values[:detail_limit] for name, values in details.items()},
        "details_truncated": {
            name: len(values) > detail_limit for name, values in details.items()
        },
    }
