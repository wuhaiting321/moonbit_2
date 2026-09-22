// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Reader error types
pub suberror ReaderError {
  OutOfBounds(offset~ : Int, len~ : Int, capacity~ : Int)
  InvalidLeb128(reason~ : String)
  UnterminatedString(offset~ : Int)
} derive(Debug, Eq)

///|
/// Stateful binary stream reader with bounds checking and endianness support
pub(all) struct BinaryReader {
  bytes : Bytes
  mut offset : Int
  mut endian : Endian
} derive(Debug)

///|
/// Create a new BinaryReader instance with optional endianness (default LittleEndian)
pub fn BinaryReader::new(
  bytes : Bytes,
  endian? : Endian = LittleEndian,
) -> BinaryReader {
  { bytes, offset: 0, endian }
}

///|
/// Seek to absolute offset
pub fn BinaryReader::set_offset(
  self : BinaryReader,
  offset : Int,
) -> Unit raise ReaderError {
  if offset < 0 || offset > self.bytes.length() {
    raise OutOfBounds(offset~, len=0, capacity=self.bytes.length())
  }
  self.offset = offset
}

///|
/// Get current position
pub fn BinaryReader::get_offset(self : BinaryReader) -> Int {
  self.offset
}

///|
/// Check remaining readable bytes
pub fn BinaryReader::remaining(self : BinaryReader) -> Int {
  if self.offset >= self.bytes.length() {
    0
  } else {
    self.bytes.length() - self.offset
  }
}

///|
/// Ensure `len` bytes can be read from current offset
pub fn BinaryReader::ensure(
  self : BinaryReader,
  len : Int,
) -> Unit raise ReaderError {
  if len < 0 ||
    self.offset > self.bytes.length() ||
    len > self.bytes.length() - self.offset {
    raise OutOfBounds(offset=self.offset, len~, capacity=self.bytes.length())
  }
}

///|
/// Read single unsigned 8-bit byte
pub fn BinaryReader::read_u8(self : BinaryReader) -> Byte raise ReaderError {
  self.ensure(1)
  let b = self.bytes[self.offset]
  self.offset = self.offset + 1
  b
}

///|
/// Read single signed 8-bit byte
pub fn BinaryReader::read_i8(self : BinaryReader) -> Int raise ReaderError {
  let b = self.read_u8()
  let val = b.to_int()
  if val >= 128 {
    val - 256
  } else {
    val
  }
}

///|
/// Read unsigned 16-bit integer
pub fn BinaryReader::read_u16(self : BinaryReader) -> UInt raise ReaderError {
  self.ensure(2)
  let val = read_u16(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 2
  val
}

///|
/// Read signed 16-bit integer
pub fn BinaryReader::read_i16(self : BinaryReader) -> Int raise ReaderError {
  self.ensure(2)
  let val = read_i16(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 2
  val
}

///|
/// Read unsigned 32-bit integer
pub fn BinaryReader::read_u32(self : BinaryReader) -> UInt raise ReaderError {
  self.ensure(4)
  let val = read_u32(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 4
  val
}

///|
/// Read signed 32-bit integer
pub fn BinaryReader::read_i32(self : BinaryReader) -> Int raise ReaderError {
  self.ensure(4)
  let val = read_i32(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 4
  val
}

///|
/// Read unsigned 64-bit integer
pub fn BinaryReader::read_u64(self : BinaryReader) -> UInt64 raise ReaderError {
  self.ensure(8)
  let val = read_u64(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 8
  val
}

///|
/// Read signed 64-bit integer
pub fn BinaryReader::read_i64(self : BinaryReader) -> Int64 raise ReaderError {
  self.ensure(8)
  let val = read_i64(self.bytes, self.offset, self.endian)
  self.offset = self.offset + 8
  val
}

///|
/// Read slice of bytes
pub fn BinaryReader::read_bytes(
  self : BinaryReader,
  len : Int,
) -> Bytes raise ReaderError {
  self.ensure(len)
  let slice_arr = Array::make(len, b'\x00')
  let mut i = 0
  while i < len {
    slice_arr[i] = self.bytes[self.offset + i]
    i = i + 1
  }
  self.offset = self.offset + len
  Bytes::from_array(slice_arr)
}

///|
/// Peek at next byte without advancing offset
pub fn BinaryReader::peek_u8(self : BinaryReader) -> Byte raise ReaderError {
  self.ensure(1)
  self.bytes[self.offset]
}

///|
/// Skip forward by n bytes
pub fn BinaryReader::skip(
  self : BinaryReader,
  n : Int,
) -> Unit raise ReaderError {
  self.ensure(n)
  self.offset = self.offset + n
}
