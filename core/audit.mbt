///|
/// Most records a single audit accepts.
let max_records : Int = 250000

///|
let min_detail_limit : Int = 1

///|
let max_detail_limit : Int = 10000

///|
/// At most `limit` leading elements, without copying when nothing is dropped.
fn[T] first_n(items : Array[T], limit : Int) -> Array[T] {
  if items.length() <= limit {
    items
  } else {
    items[0:limit].to_owned()
  }
}

///|
/// Audit `times` against `grid`.
///
/// One pass over the caller's original order classifies every record and finds
/// out-of-order neighbours. A sort of the valid grid indices then derives the
/// missing ranges, so the cost is O(m log m) in time and O(m) in memory. The
/// expected grid is never enumerated point by point, which is what keeps a
/// window of 10^12 points with a handful of records cheap: `N` never sizes an
/// allocation.
///
/// The five problem counts overlap on purpose. A record outside the window is
/// neither on-grid nor a valid point, but it still counts towards duplicates,
/// so the counts must never be added into a single "bad rows" total.
pub fn audit(
  times : Array[Int64],
  grid : Grid,
  detail_limit : Int,
) -> Result[AuditReport, AuditError] {
  if detail_limit < min_detail_limit || detail_limit > max_detail_limit {
    return Err(InvalidDetailLimit)
  }
  let input_records = times.length()
  if input_records > max_records {
    return Err(TooManyRecords)
  }
  let out_of_order_all : Array[RecordRef] = []
  let off_grid_all : Array[RecordRef] = []
  let out_of_range_all : Array[RecordRef] = []
  let valid_ks : Array[Int64] = []
  let mut out_of_order_count : Int64 = 0L
  let mut off_grid_count : Int64 = 0L
  let mut out_of_range_count : Int64 = 0L
  let mut previous : Int64 = 0L
  for i = 0; i < input_records; i = i + 1 {
    let timestamp = times[i]
    if i > 0 && timestamp < previous {
      out_of_order_count = out_of_order_count + 1L
      out_of_order_all.push({ timestamp_ms: timestamp, record_index: i + 1 })
    }
    previous = timestamp
    // Window membership is decided before any relative offset is computed, so
    // the subtraction below always stays inside the safe range.
    if timestamp < grid.start_ms || timestamp >= grid.end_ms {
      out_of_range_count = out_of_range_count + 1L
      out_of_range_all.push({ timestamp_ms: timestamp, record_index: i + 1 })
    } else {
      let offset = timestamp - grid.start_ms
      if offset % grid.step_ms != 0L {
        off_grid_count = off_grid_count + 1L
        off_grid_all.push({ timestamp_ms: timestamp, record_index: i + 1 })
      } else {
        valid_ks.push(offset / grid.step_ms)
      }
    }
  }
  // Duplicates: every parseable timestamp contributes (occurrences - 1),
  // including out-of-range and off-grid ones. Sorting (timestamp, index) pairs
  // groups equal timestamps while keeping the original index of each later
  // occurrence.
  let ordered : Array[(Int64, Int)] = []
  for i = 0; i < input_records; i = i + 1 {
    ordered.push((times[i], i))
  }
  ordered.sort()
  let mut duplicate_extra_count : Int64 = 0L
  let duplicate_indices : Array[Int] = []
  let mut group_start = 0
  while group_start < input_records {
    let (timestamp, _) = ordered[group_start]
    let mut next = group_start + 1
    while next < input_records {
      let (candidate, index) = ordered[next]
      if candidate != timestamp {
        break
      }
      duplicate_extra_count = duplicate_extra_count + 1L
      duplicate_indices.push(index)
      next = next + 1
    }
    group_start = next
  }
  duplicate_indices.sort()
  let duplicates_all : Array[RecordRef] = []
  for index in duplicate_indices {
    duplicates_all.push({ timestamp_ms: times[index], record_index: index + 1 })
  }
  // Missing ranges: fold the sorted, de-duplicated valid indices into ordered
  // half-open intervals, then close the tail against the end of the window.
  valid_ks.sort()
  let distinct_ks : Array[Int64] = []
  for k in valid_ks {
    if distinct_ks.length() == 0 || distinct_ks[distinct_ks.length() - 1] != k {
      distinct_ks.push(k)
    }
  }
  let missing_ranges_all : Array[(Int64, Int64)] = []
  let mut cursor : Int64 = 0L
  let mut missing_points : Int64 = 0L
  let mut longest_missing_run : Int64 = 0L
  for k in distinct_ks {
    if k > cursor {
      missing_ranges_all.push((cursor, k))
      let run = k - cursor
      missing_points = missing_points + run
      if run > longest_missing_run {
        longest_missing_run = run
      }
    }
    cursor = k + 1L
  }
  if cursor < grid.expected_points {
    missing_ranges_all.push((cursor, grid.expected_points))
    let run = grid.expected_points - cursor
    missing_points = missing_points + run
    if run > longest_missing_run {
      longest_missing_run = run
    }
  }
  let truncated : DetailTruncation = {
    missing_ranges: missing_ranges_all.length() > detail_limit,
    duplicates: duplicates_all.length() > detail_limit,
    out_of_order: out_of_order_all.length() > detail_limit,
    off_grid: off_grid_all.length() > detail_limit,
    out_of_range: out_of_range_all.length() > detail_limit,
  }
  let passed = missing_points == 0L &&
    duplicate_extra_count == 0L &&
    out_of_order_count == 0L &&
    off_grid_count == 0L &&
    out_of_range_count == 0L
  Ok({
    grid: grid,
    input_records: input_records.to_int64(),
    covered_points: distinct_ks.length().to_int64(),
    missing_points: missing_points,
    duplicate_extra_records: duplicate_extra_count,
    out_of_order_records: out_of_order_count,
    off_grid_records: off_grid_count,
    out_of_range_records: out_of_range_count,
    longest_missing_run: longest_missing_run,
    missing_ranges: first_n(missing_ranges_all, detail_limit),
    duplicates: first_n(duplicates_all, detail_limit),
    out_of_order: first_n(out_of_order_all, detail_limit),
    off_grid: first_n(off_grid_all, detail_limit),
    out_of_range: first_n(out_of_range_all, detail_limit),
    truncated: truncated,
    passed: passed,
  })
}
