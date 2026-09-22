// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Parse the Type section payload (vector of function types)
pub fn parse_type_section(
  payload : Bytes,
) -> Array[@wasm_type.FuncType] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let types = Array(capacity=count)
  let mut i = 0
  while i < count {
    types.push(@wasm_type.parse_func_type(reader))
    i = i + 1
  }
  types
}

///|
/// Parse the Function section payload (vector of type indices)
pub fn parse_function_section(payload : Bytes) -> Array[UInt] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let indices = Array(capacity=count)
  let mut i = 0
  while i < count {
    indices.push(reader.read_uleb128_u32())
    i = i + 1
  }
  indices
}

///|
/// Parsed Table section entry
pub(all) struct TableEntry {
  table_type : @wasm_type.TableType
} derive(Debug, Eq)

///|
/// Parse the Table section payload
pub fn parse_table_section(payload : Bytes) -> Array[TableEntry] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let tables = Array(capacity=count)
  let mut i = 0
  while i < count {
    let tt = @wasm_type.parse_table_type(reader)
    tables.push({ table_type: tt, })
    i = i + 1
  }
  tables
}

///|
/// Parsed Memory section entry
pub(all) struct MemoryEntry {
  mem_type : @wasm_type.MemType
} derive(Debug, Eq)

///|
/// Parse the Memory section payload
pub fn parse_memory_section(payload : Bytes) -> Array[MemoryEntry] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let memories = Array(capacity=count)
  let mut i = 0
  while i < count {
    let mt = @wasm_type.parse_mem_type(reader)
    memories.push({ mem_type: mt, })
    i = i + 1
  }
  memories
}

///|
/// Parsed Global section entry
pub(all) struct GlobalEntry {
  global_type : @wasm_type.GlobalType
  init_expr : Bytes
} derive(Debug)

///|
/// Parse the Global section payload
pub fn parse_global_section(payload : Bytes) -> Array[GlobalEntry] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let globals = Array(capacity=count)
  let mut i = 0
  while i < count {
    let gt = @wasm_type.parse_global_type(reader)
    let expr_start = reader.get_offset()
    // Read init expression until end opcode (0x0B)
    let mut depth = 0
    let mut b = reader.read_u8()
    while b != b'\x0B' || depth > 0 {
      if b == b'\x02' || b == b'\x03' || b == b'\x04' {
        depth = depth + 1
      }
      if b == b'\x0B' && depth > 0 {
        depth = depth - 1
      }
      b = reader.read_u8()
    }
    let expr_end = reader.get_offset()
    let expr_len = expr_end - expr_start
    let expr_arr = Array::make(expr_len, b'\x00')
    let mut k = 0
    while k < expr_len {
      expr_arr[k] = payload[expr_start + k]
      k = k + 1
    }
    globals.push({ global_type: gt, init_expr: Bytes::from_array(expr_arr), })
    i = i + 1
  }
  globals
}

///|
/// Parse the Start section payload (function index)
pub fn parse_start_section(payload : Bytes) -> UInt raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  reader.read_uleb128_u32()
}

///|
/// Parse the DataCount section payload
pub fn parse_datacount_section(payload : Bytes) -> UInt raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  reader.read_uleb128_u32()
}
