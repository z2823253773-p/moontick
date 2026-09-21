// Native file access for ticks input. MoonBit's own `String` is UTF-16, so a
// path must be re-encoded to UTF-8 bytes and NUL-terminated before it can be
// handed to libc; reinterpreting the string buffer would send C the wrong bytes.

///|
/// Why reading failed. I/O failures stay distinct from data problems because
/// they map to a different exit code.
pub(all) enum ReadErrorKind {
  FileUnavailable
  ReadFailed
  InputTooLarge
} derive(Eq, Debug)

///|
pub fn ReadErrorKind::code(self : ReadErrorKind) -> String {
  match self {
    FileUnavailable => "IO_ERROR"
    ReadFailed => "IO_ERROR"
    InputTooLarge => "RESOURCE_LIMIT"
  }
}

///|
pub fn ReadErrorKind::message(self : ReadErrorKind) -> String {
  match self {
    FileUnavailable => "cannot open the input file"
    ReadFailed => "failed while reading the input file"
    InputTooLarge => "input exceeds the 33554432 byte limit"
  }
}

///|
pub struct ReadError {
  kind : ReadErrorKind
}

///|
/// Bytes of a NUL-terminated UTF-8 C string.
fn c_string(value : String) -> Bytes {
  let encoded = @utf8.encode(value)
  let raw : Array[Byte] = []
  for i = 0; i < encoded.length(); i = i + 1 {
    raw.push(encoded.at(i))
  }
  raw.push(b'\x00')
  Bytes::from_array(raw)
}

///|
let read_chunk_bytes : Int = 65536

///|
/// `O_RDONLY` from libc's `<fcntl.h>`. Opening read-only means a mistyped path
/// can never truncate or create a file while auditing.
let open_read_only : Int = 0

///|
#borrow(path)
extern "C" fn c_open(path : Bytes, flags : Int) -> Int = "open"

///|
#borrow(buffer)
extern "C" fn c_read(descriptor : Int, buffer : Bytes, count : Int) -> Int = "read"

///|
extern "C" fn c_close(descriptor : Int) -> Int = "close"

///|
/// Read a whole ticks file.
///
/// The loop asks for at most one byte past the limit, so an oversized file is
/// detected without ever being buffered in full and the size is bounded by the
/// read itself rather than by file metadata.
pub fn read_ticks(path : String) -> Result[Bytes, ReadError] {
  let descriptor = c_open(c_string(path), open_read_only)
  if descriptor < 0 {
    return Err({ kind: FileUnavailable, })
  }
  let buffer = Bytes::make(read_chunk_bytes, b'\x00')
  let collected : Array[Byte] = []
  let mut failure : ReadErrorKind? = None
  let mut finished = false
  while !finished {
    let remaining = max_input_bytes + 1 - collected.length()
    // The loop stops as soon as this run has read the one permitted byte past
    // the limit, so the file is never buffered in full just to measure it.
    let wanted = if remaining < read_chunk_bytes && remaining > 0 {
      remaining
    } else {
      read_chunk_bytes
    }
    let got = c_read(descriptor, buffer, wanted)
    if got < 0 {
      failure = Some(ReadFailed)
      finished = true
    } else if got == 0 {
      finished = true
    } else {
      for i = 0; i < got; i = i + 1 {
        collected.push(buffer.at(i))
      }
      if collected.length() > max_input_bytes {
        failure = Some(InputTooLarge)
        finished = true
      }
    }
  }
  ignore(c_close(descriptor))
  match failure {
    Some(kind) => Err({ kind, })
    None => Ok(Bytes::from_array(collected))
  }
}
