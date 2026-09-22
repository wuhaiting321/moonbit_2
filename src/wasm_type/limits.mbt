// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Wasm limit type for memories and tables
pub(all) struct Limits {
  min : UInt
  max : UInt?
} derive(Debug, Eq)

///|
/// Display limits in WAT notation
pub fn Limits::to_string(self : Limits) -> String {
  match self.max {
    Some(m) => "\{self.min} \{m}"
    None => "\{self.min}"
  }
}

///|
/// Parse limits from binary reader
pub fn parse_limits(reader : @binary_reader.BinaryReader) -> Limits raise Error {
  let flag = reader.read_u8()
  let min = reader.read_uleb128_u32()
  if flag == 0x01 {
    let max = reader.read_uleb128_u32()
    { min, max: Some(max), }
  } else {
    { min, max: None, }
  }
}

///|
/// Mutability flag for globals
pub(all) enum Mutability {
  Immutable
  Mutable
} derive(Debug, Eq)

///|
/// Global variable type
pub(all) struct GlobalType {
  val_type : ValType
  mutability : Mutability
} derive(Debug, Eq)

///|
/// Display global type in WAT notation
pub fn GlobalType::to_string(self : GlobalType) -> String {
  match self.mutability {
    Immutable => self.val_type.to_string()
    Mutable => "(mut \{self.val_type.to_string()})"
  }
}

///|
/// Parse global type from binary reader
pub fn parse_global_type(
  reader : @binary_reader.BinaryReader,
) -> GlobalType raise Error {
  let val_type = parse_val_type(reader)
  let mut_byte = reader.read_u8()
  let mutability : Mutability = if mut_byte == 0x01 {
    Mutable
  } else {
    Immutable
  }
  { val_type, mutability, }
}

///|
/// Table element type
pub(all) enum ElemType {
  FuncRef
  ExternRef
} derive(Debug, Eq)

///|
/// Table type
pub(all) struct TableType {
  elem_type : ElemType
  limits : Limits
} derive(Debug, Eq)

///|
/// Display table type in WAT notation
pub fn TableType::to_string(self : TableType) -> String {
  let elem_str = match self.elem_type {
    FuncRef => "funcref"
    ExternRef => "externref"
  }
  "\{self.limits.to_string()} \{elem_str}"
}

///|
/// Parse table type from binary reader
pub fn parse_table_type(
  reader : @binary_reader.BinaryReader,
) -> TableType raise Error {
  let code = reader.read_u8()
  let elem_type : ElemType = match code {
    b'\x70' => FuncRef
    b'\x6F' => ExternRef
    _ => raise UnknownRefType(code~)
  }
  let limits = parse_limits(reader)
  { elem_type, limits, }
}

///|
/// Memory type (wraps Limits)
pub(all) struct MemType {
  limits : Limits
} derive(Debug, Eq)

///|
/// Parse memory type from binary reader
pub fn parse_mem_type(
  reader : @binary_reader.BinaryReader,
) -> MemType raise Error {
  let limits = parse_limits(reader)
  { limits, }
}
