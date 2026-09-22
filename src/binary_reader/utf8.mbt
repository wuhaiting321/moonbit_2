// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Read a UTF-8 encoded byte vector with explicit length prefix (Wasm name encoding)
pub fn BinaryReader::read_wasm_name(
  self : BinaryReader,
) -> String raise ReaderError {
  let byte_len = self.read_uleb128_u32()
  self.ensure(byte_len.reinterpret_as_int())
  let start_off = self.offset
  let end_off = start_off + byte_len.reinterpret_as_int()
  let buf = StringBuilder()
  let mut i = start_off
  while i < end_off {
    buf.write_char(self.bytes[i].to_int().unsafe_to_char())
    i = i + 1
  }
  self.offset = end_off
  buf.to_string()
}

///|
/// Read null-terminated UTF-8 / ASCII string from reader
pub fn BinaryReader::read_cstring(
  self : BinaryReader,
) -> String raise ReaderError {
  let start_off = self.offset
  let mut end_off = start_off
  let len = self.bytes.length()
  while end_off < len && self.bytes[end_off] != b'\x00' {
    end_off = end_off + 1
  }
  if end_off >= len {
    raise UnterminatedString(offset=start_off)
  }
  let buf = StringBuilder()
  for i = start_off; i < end_off; i = i + 1 {
    buf.write_char(self.bytes[i].to_int().unsafe_to_char())
  }
  self.offset = end_off + 1
  buf.to_string()
}

///|
/// Extract string from a specific offset without advancing current reader offset
pub fn BinaryReader::get_cstring_at(
  bytes : Bytes,
  offset : Int,
) -> String raise ReaderError {
  if offset < 0 || offset >= bytes.length() {
    raise OutOfBounds(offset~, len=1, capacity=bytes.length())
  }
  let mut end_off = offset
  let len = bytes.length()
  while end_off < len && bytes[end_off] != b'\x00' {
    end_off = end_off + 1
  }
  if end_off >= len {
    raise UnterminatedString(offset~)
  }
  let buf = StringBuilder()
  for i = offset; i < end_off; i = i + 1 {
    buf.write_char(bytes[i].to_int().unsafe_to_char())
  }
  buf.to_string()
}

///|
/// Read a fixed-length UTF-8 string without length prefix
pub fn BinaryReader::read_fixed_string(
  self : BinaryReader,
  len : Int,
) -> String raise ReaderError {
  self.ensure(len)
  let buf = StringBuilder()
  let mut i = 0
  while i < len {
    buf.write_char(self.bytes[self.offset + i].to_int().unsafe_to_char())
    i = i + 1
  }
  self.offset = self.offset + len
  buf.to_string()
}
