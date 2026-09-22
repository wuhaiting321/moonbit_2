// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Stateful Binary Writer for encoding binary streams and Wasm data
pub(all) struct BinaryWriter {
  mut buffer : Array[Byte]
  mut endian : Endian
} derive(Debug)

///|
/// Create a new BinaryWriter instance
pub fn BinaryWriter::new(endian? : Endian = LittleEndian) -> BinaryWriter {
  { buffer: [], endian, }
}

///|
/// Extract underlying bytes
pub fn BinaryWriter::to_bytes(self : BinaryWriter) -> Bytes {
  Bytes::from_array(self.buffer)
}

///|
/// Get current length
pub fn BinaryWriter::length(self : BinaryWriter) -> Int {
  self.buffer.length()
}

///|
/// Write single byte
pub fn BinaryWriter::write_u8(self : BinaryWriter, b : Byte) -> Unit {
  self.buffer.push(b)
}

///|
/// Write unsigned 16-bit integer
pub fn BinaryWriter::write_u16(self : BinaryWriter, val : UInt) -> Unit {
  let b0 = (val & 0xFF).to_byte()
  let b1 = ((val >> 8) & 0xFF).to_byte()
  match self.endian {
    LittleEndian => {
      self.buffer.push(b0)
      self.buffer.push(b1)
    }
    BigEndian => {
      self.buffer.push(b1)
      self.buffer.push(b0)
    }
  }
}

///|
/// Write unsigned 32-bit integer
pub fn BinaryWriter::write_u32(self : BinaryWriter, val : UInt) -> Unit {
  let b0 = (val & 0xFF).to_byte()
  let b1 = ((val >> 8) & 0xFF).to_byte()
  let b2 = ((val >> 16) & 0xFF).to_byte()
  let b3 = ((val >> 24) & 0xFF).to_byte()
  match self.endian {
    LittleEndian => {
      self.buffer.push(b0)
      self.buffer.push(b1)
      self.buffer.push(b2)
      self.buffer.push(b3)
    }
    BigEndian => {
      self.buffer.push(b3)
      self.buffer.push(b2)
      self.buffer.push(b1)
      self.buffer.push(b0)
    }
  }
}

///|
/// Patch an existing four-byte unsigned integer in the configured byte order.
pub fn BinaryWriter::patch_u32(
  self : BinaryWriter,
  offset : Int,
  val : UInt,
) -> Bool {
  if offset < 0 || offset > self.buffer.length() - 4 {
    false
  } else {
    let b0 = (val & 0xFF).to_byte()
    let b1 = ((val >> 8) & 0xFF).to_byte()
    let b2 = ((val >> 16) & 0xFF).to_byte()
    let b3 = ((val >> 24) & 0xFF).to_byte()
    match self.endian {
      LittleEndian => {
        self.buffer[offset] = b0
        self.buffer[offset + 1] = b1
        self.buffer[offset + 2] = b2
        self.buffer[offset + 3] = b3
      }
      BigEndian => {
        self.buffer[offset] = b3
        self.buffer[offset + 1] = b2
        self.buffer[offset + 2] = b1
        self.buffer[offset + 3] = b0
      }
    }
    true
  }
}

///|
/// Write unsigned 64-bit integer
pub fn BinaryWriter::write_u64(self : BinaryWriter, val : UInt64) -> Unit {
  let b0 = (val & 0xFFUL).to_byte()
  let b1 = ((val >> 8) & 0xFFUL).to_byte()
  let b2 = ((val >> 16) & 0xFFUL).to_byte()
  let b3 = ((val >> 24) & 0xFFUL).to_byte()
  let b4 = ((val >> 32) & 0xFFUL).to_byte()
  let b5 = ((val >> 40) & 0xFFUL).to_byte()
  let b6 = ((val >> 48) & 0xFFUL).to_byte()
  let b7 = ((val >> 56) & 0xFFUL).to_byte()
  match self.endian {
    LittleEndian => {
      self.buffer.push(b0)
      self.buffer.push(b1)
      self.buffer.push(b2)
      self.buffer.push(b3)
      self.buffer.push(b4)
      self.buffer.push(b5)
      self.buffer.push(b6)
      self.buffer.push(b7)
    }
    BigEndian => {
      self.buffer.push(b7)
      self.buffer.push(b6)
      self.buffer.push(b5)
      self.buffer.push(b4)
      self.buffer.push(b3)
      self.buffer.push(b2)
      self.buffer.push(b1)
      self.buffer.push(b0)
    }
  }
}

///|
/// Write unsigned LEB128 integer
pub fn BinaryWriter::write_uleb128(self : BinaryWriter, val : UInt64) -> Unit {
  let mut v = val
  while true {
    let mut byte_val = (v & 0x7FUL).to_byte()
    v = v >> 7
    if v != 0UL {
      byte_val = (byte_val.to_uint() | 0x80).to_byte()
      self.buffer.push(byte_val)
    } else {
      self.buffer.push(byte_val)
      break
    }
  }
}

///|
/// Write signed LEB128 integer
pub fn BinaryWriter::write_sleb128(self : BinaryWriter, val : Int64) -> Unit {
  let mut v = val
  let mut more = true
  while more {
    let mut byte_val = (v & 0x7FL).to_byte()
    v = v >> 7
    let sign_bit = (byte_val.to_uint() & 0x40) != 0
    if (v == 0L && !sign_bit) || (v == -1L && sign_bit) {
      more = false
    } else {
      byte_val = (byte_val.to_uint() | 0x80).to_byte()
    }
    self.buffer.push(byte_val)
  }
}

///|
/// Write a Wasm name (length-prefixed UTF-8 byte vector)
pub fn BinaryWriter::write_wasm_name(self : BinaryWriter, s : String) -> Unit {
  let len = s.length()
  self.write_uleb128(len.to_uint64())
  let mut i = 0
  while i < len {
    self.buffer.push(s[i].to_int().to_byte())
    i = i + 1
  }
}

///|
/// Write raw bytes without length prefix
pub fn BinaryWriter::write_raw(self : BinaryWriter, data : Bytes) -> Unit {
  let mut i = 0
  while i < data.length() {
    self.buffer.push(data[i])
    i = i + 1
  }
}
