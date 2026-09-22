// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "endian_decoding" {
  let b : Bytes = b"\x78\x56\x34\x12"

  let r_le = BinaryReader::new(b, endian=LittleEndian)
  let val_le = r_le.read_u32()
  inspect(val_le, content="305419896") // 0x12345678

  let r_be = BinaryReader::new(b, endian=BigEndian)
  let val_be = r_be.read_u32()
  inspect(val_be, content="2018915346") // 0x78563412
}

///|
test "uleb128_decoding" {
  // ULEB128 for 624485 is [0xE5, 0x8E, 0x26]
  let b : Bytes = b"\xE5\x8E\x26"

  let r = BinaryReader::new(b)
  let val = r.read_uleb128()
  inspect(val, content="624485")
}

///|
test "sleb128_decoding" {
  // SLEB128 for -624485 is [0x9B, 0xF1, 0x59]
  let b : Bytes = b"\x9B\xF1\x59"

  let r = BinaryReader::new(b)
  let val = r.read_sleb128()
  inspect(val, content="-624485")
}

///|
test "uleb128_u32_single_byte" {
  let r = BinaryReader::new(b"\x0A")
  let val = r.read_uleb128_u32()
  inspect(val, content="10")
}

///|
test "uleb128_u32_multi_byte" {
  // 624485 = 0x98765
  let r = BinaryReader::new(b"\xE5\x8E\x26")
  let val = r.read_uleb128_u32()
  inspect(val, content="624485")
}

///|
test "sleb128_i32_positive" {
  let r = BinaryReader::new(b"\x0A")
  let val = r.read_sleb128_i32()
  inspect(val, content="10")
}

///|
test "sleb128_i32_negative" {
  // -10 in SLEB128 is 0x76
  let r = BinaryReader::new(b"\x76")
  let val = r.read_sleb128_i32()
  inspect(val, content="-10")
}

///|
test "wasm_name_decoding" {
  // Length 5 followed by "hello"
  let b : Bytes = b"\x05hello"
  let r = BinaryReader::new(b)
  let name = r.read_wasm_name()
  inspect(name, content="hello")
  inspect(r.get_offset(), content="6")
}

///|
test "cstring_decoding" {
  let b : Bytes = b"world\x00"

  let r = BinaryReader::new(b)
  let s = r.read_cstring()
  inspect(s, content="world")
  inspect(r.get_offset(), content="6")
}

///|
test "negative_read_length_is_rejected" {
  let reader = BinaryReader::new(b"abc")
  let rejected = try {
    let _ = reader.read_bytes(-1)
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "seek_beyond_bounds_is_rejected" {
  let rejected = try {
    BinaryReader::new(b"abc").set_offset(4)
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "peek_does_not_advance_offset" {
  let r = BinaryReader::new(b"\x42\x43")
  let peeked = r.peek_u8()
  inspect(peeked, content="b'\\x42'") // 0x42
  inspect(r.get_offset(), content="0")
}

///|
test "skip_advances_offset" {
  let r = BinaryReader::new(b"\x01\x02\x03\x04")
  r.skip(2)
  inspect(r.get_offset(), content="2")
  let val = r.read_u8()
  inspect(val, content="b'\\x03'") // 0x03
}

///|
test "writer_roundtrip_u32" {
  let w = BinaryWriter::new()
  w.write_u32(0x12345678)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let val = r.read_u32()
  inspect(val, content="305419896") // 0x12345678
}

///|
test "writer_roundtrip_uleb128" {
  let w = BinaryWriter::new()
  w.write_uleb128(624485UL)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let val = r.read_uleb128()
  inspect(val, content="624485")
}

///|
test "writer_roundtrip_wasm_name" {
  let w = BinaryWriter::new()
  w.write_wasm_name("test_func")
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let name = r.read_wasm_name()
  inspect(name, content="test_func")
}

///|
test "writer_write_u8" {
  let w = BinaryWriter::new()
  w.write_u8(b'\xAB')
  w.write_u8(b'\xCD')
  let bytes = w.to_bytes()
  inspect(bytes.length(), content="2")
  let r = BinaryReader::new(bytes)
  inspect(r.read_u8(), content="b'\\xAB'")
  inspect(r.read_u8(), content="b'\\xCD'")
}

///|
test "writer_write_u16_roundtrip" {
  let w = BinaryWriter::new()
  w.write_u16(0x1234)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  inspect(r.read_u16(), content="4660")
}

///|
test "writer_write_u64_roundtrip" {
  let w = BinaryWriter::new()
  w.write_u64(0x123456789ABCDEF0UL)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let val = r.read_u64()
  inspect(val, content="1311768467463790320")
}

///|
test "writer_write_sleb128_roundtrip" {
  let w = BinaryWriter::new()
  w.write_sleb128(-42L)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let val = r.read_sleb128()
  inspect(val, content="-42")
}

///|
test "writer_write_sleb128_positive" {
  let w = BinaryWriter::new()
  w.write_sleb128(100L)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  let val = r.read_sleb128()
  inspect(val, content="100")
}

///|
test "writer_write_raw" {
  let w = BinaryWriter::new()
  w.write_raw(b"\x01\x02\x03")
  w.write_raw(b"\x04\x05")
  inspect(w.length(), content="5")
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  inspect(r.read_u8(), content="b'\\x01'")
  inspect(r.read_u8(), content="b'\\x02'")
  inspect(r.read_u8(), content="b'\\x03'")
  inspect(r.read_u8(), content="b'\\x04'")
  inspect(r.read_u8(), content="b'\\x05'")
}

///|
test "writer_patch_u32" {
  let w = BinaryWriter::new()
  w.write_u32(0)
  w.write_u32(0)
  let ok = w.patch_u32(0, 0xDEADBEEF)
  inspect(ok, content="true")
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes)
  inspect(r.read_u32(), content="3735928559")
}

///|
test "writer_big_endian_u32" {
  let w = BinaryWriter::new(endian=BigEndian)
  w.write_u32(0x01020304)
  let bytes = w.to_bytes()
  inspect(bytes.length(), content="4")
  let r = BinaryReader::new(bytes, endian=BigEndian)
  inspect(r.read_u32(), content="16909060")
}

///|
test "writer_big_endian_u16" {
  let w = BinaryWriter::new(endian=BigEndian)
  w.write_u16(0x0102)
  let bytes = w.to_bytes()
  let r = BinaryReader::new(bytes, endian=BigEndian)
  inspect(r.read_u16(), content="258")
}

///|
test "truncated_uleb128_is_rejected" {
  let rejected = try {
    let _ = BinaryReader::new(b"\x80").read_uleb128()
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}
