// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Read unsigned LEB128 as UInt (32-bit result, used by Wasm section encodings)
pub fn BinaryReader::read_uleb128_u32(
  self : BinaryReader,
) -> UInt raise ReaderError {
  let mut result : UInt = 0
  let mut shift = 0
  let start_off = self.offset
  while true {
    if self.offset >= self.bytes.length() {
      raise OutOfBounds(offset=self.offset, len=1, capacity=self.bytes.length())
    }
    let b = self.bytes[self.offset].to_uint()
    self.offset = self.offset + 1
    let val = b & 0x7F
    if shift < 35 {
      result = result | (val << shift)
    }
    if (b & 0x80) == 0 {
      break
    }
    shift = shift + 7
    if shift >= 35 {
      raise InvalidLeb128(
        reason="ULEB128 value exceeds 32-bit integer range at offset \{start_off}",
      )
    }
  }
  result
}

///|
/// Read unsigned LEB128 as UInt64
pub fn BinaryReader::read_uleb128(
  self : BinaryReader,
) -> UInt64 raise ReaderError {
  let mut result : UInt64 = 0UL
  let mut shift = 0
  let start_off = self.offset
  while true {
    if self.offset >= self.bytes.length() {
      raise OutOfBounds(offset=self.offset, len=1, capacity=self.bytes.length())
    }
    let b = self.bytes[self.offset].to_uint64()
    self.offset = self.offset + 1
    let val = b & 0x7FUL
    if shift < 64 {
      result = result | (val << shift)
    }
    if (b & 0x80UL) == 0UL {
      break
    }
    shift = shift + 7
    if shift >= 70 {
      raise InvalidLeb128(
        reason="ULEB128 value exceeds 64-bit integer range at offset \{start_off}",
      )
    }
  }
  result
}

///|
/// Read signed LEB128 as Int (32-bit result, used by Wasm i32 immediates)
pub fn BinaryReader::read_sleb128_i32(
  self : BinaryReader,
) -> Int raise ReaderError {
  let mut result : UInt = 0
  let mut shift = 0
  let start_off = self.offset
  let mut byte_val : Byte = b'\x00'
  while true {
    if self.offset >= self.bytes.length() {
      raise OutOfBounds(offset=self.offset, len=1, capacity=self.bytes.length())
    }
    byte_val = self.bytes[self.offset]
    self.offset = self.offset + 1
    let val = byte_val.to_uint() & 0x7F
    if shift < 32 {
      result = result | (val << shift)
    }
    shift = shift + 7
    if (byte_val & b'\x80') == b'\x00' {
      break
    }
    if shift >= 35 {
      raise InvalidLeb128(
        reason="SLEB128 value exceeds 32-bit integer range at offset \{start_off}",
      )
    }
  }
  // Sign extension
  let result_int = result.reinterpret_as_int()
  if shift < 32 && (byte_val & b'\x40') != b'\x00' {
    let mask = -1 << shift
    result_int | mask
  } else {
    result_int
  }
}

///|
/// Read signed LEB128 as Int64
pub fn BinaryReader::read_sleb128(
  self : BinaryReader,
) -> Int64 raise ReaderError {
  let mut result : UInt64 = 0UL
  let mut shift = 0
  let start_off = self.offset
  let mut byte_val : Byte = b'\x00'
  while true {
    if self.offset >= self.bytes.length() {
      raise OutOfBounds(offset=self.offset, len=1, capacity=self.bytes.length())
    }
    byte_val = self.bytes[self.offset]
    self.offset = self.offset + 1
    let val = byte_val.to_uint64() & 0x7FUL
    if shift < 64 {
      result = result | (val << shift)
    }
    shift = shift + 7
    if (byte_val & b'\x80') == b'\x00' {
      break
    }
    if shift >= 70 {
      raise InvalidLeb128(
        reason="SLEB128 value exceeds 64-bit integer range at offset \{start_off}",
      )
    }
  }
  // Sign extension
  if shift < 64 && (byte_val & b'\x40') != b'\x00' {
    let mask = 0xFFFFFFFFFFFFFFFFUL << shift
    result = result | mask
  }
  result.reinterpret_as_int64()
}
