// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
pub(all) enum Endian {
  LittleEndian
  BigEndian
} derive(Debug, Eq)

///|
pub fn Endian::is_little(self : Endian) -> Bool {
  match self {
    LittleEndian => true
    BigEndian => false
  }
}

///|
pub fn Endian::is_big(self : Endian) -> Bool {
  match self {
    LittleEndian => false
    BigEndian => true
  }
}

///|
/// Read unsigned 16-bit integer from byte array at offset with specified endianness
pub fn read_u16(bytes : Bytes, offset : Int, endian : Endian) -> UInt {
  let b0 = bytes[offset].to_uint()
  let b1 = bytes[offset + 1].to_uint()
  match endian {
    LittleEndian => b0 | (b1 << 8)
    BigEndian => (b0 << 8) | b1
  }
}

///|
/// Read signed 16-bit integer
pub fn read_i16(bytes : Bytes, offset : Int, endian : Endian) -> Int {
  let raw = read_u16(bytes, offset, endian).reinterpret_as_int()
  if raw >= 0x8000 {
    raw - 0x10000
  } else {
    raw
  }
}

///|
/// Read unsigned 32-bit integer from byte array at offset with specified endianness
pub fn read_u32(bytes : Bytes, offset : Int, endian : Endian) -> UInt {
  let b0 = bytes[offset].to_uint()
  let b1 = bytes[offset + 1].to_uint()
  let b2 = bytes[offset + 2].to_uint()
  let b3 = bytes[offset + 3].to_uint()
  match endian {
    LittleEndian => b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    BigEndian => (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
  }
}

///|
/// Read signed 32-bit integer
pub fn read_i32(bytes : Bytes, offset : Int, endian : Endian) -> Int {
  read_u32(bytes, offset, endian).reinterpret_as_int()
}

///|
/// Read unsigned 64-bit integer from byte array at offset with specified endianness
pub fn read_u64(bytes : Bytes, offset : Int, endian : Endian) -> UInt64 {
  let b0 = bytes[offset].to_uint64()
  let b1 = bytes[offset + 1].to_uint64()
  let b2 = bytes[offset + 2].to_uint64()
  let b3 = bytes[offset + 3].to_uint64()
  let b4 = bytes[offset + 4].to_uint64()
  let b5 = bytes[offset + 5].to_uint64()
  let b6 = bytes[offset + 6].to_uint64()
  let b7 = bytes[offset + 7].to_uint64()
  match endian {
    LittleEndian =>
      b0 |
      (b1 << 8) |
      (b2 << 16) |
      (b3 << 24) |
      (b4 << 32) |
      (b5 << 40) |
      (b6 << 48) |
      (b7 << 56)
    BigEndian =>
      (b0 << 56) |
      (b1 << 48) |
      (b2 << 40) |
      (b3 << 32) |
      (b4 << 24) |
      (b5 << 16) |
      (b6 << 8) |
      b7
  }
}

///|
/// Read signed 64-bit integer
pub fn read_i64(bytes : Bytes, offset : Int, endian : Endian) -> Int64 {
  read_u64(bytes, offset, endian).reinterpret_as_int64()
}
