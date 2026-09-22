// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Wasm type parsing errors
pub suberror TypeError {
  UnknownValueType(code~ : Byte)
  UnknownRefType(code~ : Byte)
} derive(Debug, Eq)

///|
/// Wasm numeric and reference value types
pub(all) enum ValType {
  I32
  I64
  F32
  F64
  FuncRef
  ExternRef
} derive(Debug, Eq)

///|
/// Display name for a value type
pub fn ValType::to_string(self : ValType) -> String {
  match self {
    I32 => "i32"
    I64 => "i64"
    F32 => "f32"
    F64 => "f64"
    FuncRef => "funcref"
    ExternRef => "externref"
  }
}

///|
/// Decode a value type from a byte code
pub fn parse_val_type(
  reader : @binary_reader.BinaryReader,
) -> ValType raise Error {
  let code = reader.read_u8()
  match code {
    b'\x7F' => I32
    b'\x7E' => I64
    b'\x7D' => F32
    b'\x7C' => F64
    b'\x70' => FuncRef
    b'\x6F' => ExternRef
    _ => raise UnknownValueType(code~)
  }
}

///|
/// Decode a vector of value types
pub fn parse_val_types(
  reader : @binary_reader.BinaryReader,
) -> Array[ValType] raise Error {
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let types = Array(capacity=count)
  let mut i = 0
  while i < count {
    types.push(parse_val_type(reader))
    i = i + 1
  }
  types
}

///|
/// Wasm function type signature
pub(all) struct FuncType {
  params : Array[ValType]
  results : Array[ValType]
} derive(Debug, Eq)

///|
/// Display a function type in WAT notation
pub fn FuncType::to_string(self : FuncType) -> String {
  let buf = StringBuilder()
  buf.write_string("(func")
  if self.params.length() > 0 {
    buf.write_string(" (param")
    for p in self.params {
      buf.write_string(" ")
      buf.write_string(p.to_string())
    }
    buf.write_string(")")
  }
  if self.results.length() > 0 {
    buf.write_string(" (result")
    for r in self.results {
      buf.write_string(" ")
      buf.write_string(r.to_string())
    }
    buf.write_string(")")
  }
  buf.write_string(")")
  buf.to_string()
}

///|
/// Parse a function type from binary reader
pub fn parse_func_type(
  reader : @binary_reader.BinaryReader,
) -> FuncType raise Error {
  let tag = reader.read_u8()
  if tag != b'\x60' {
    raise UnknownValueType(code=tag)
  }
  let params = parse_val_types(reader)
  let results = parse_val_types(reader)
  { params, results }
}

///|
/// Block type for control instructions
pub(all) enum BlockType {
  Empty
  Value(ValType)
  TypeIndex(UInt)
} derive(Debug, Eq)

///|
/// Decode a block type (signed LEB128 encoded)
pub fn parse_block_type(
  reader : @binary_reader.BinaryReader,
) -> BlockType raise Error {
  let saved = reader.get_offset()
  let raw = reader.read_sleb128_i32()
  if raw == -64 {
    // 0x40 = empty block type
    Empty
  } else if raw >= 0 {
    // Type index reference
    TypeIndex(raw.reinterpret_as_uint())
  } else {
    // Re-read as value type byte
    reader.set_offset(saved)
    let vt = parse_val_type(reader)
    Value(vt)
  }
}
