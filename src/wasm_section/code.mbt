// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Parsed function body with locals and bytecode
pub(all) struct FuncBody {
  locals : Array[@wasm_type.ValType]
  code : Bytes
} derive(Debug)

///|
/// Parse the Code section payload (vector of function bodies)
pub fn parse_code_section(
  payload : Bytes,
) -> Array[FuncBody] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let bodies = Array(capacity=count)
  let mut i = 0
  while i < count {
    let body_size = reader.read_uleb128_u32().reinterpret_as_int()
    let body_start = reader.get_offset()

    // Parse locals: vec of (count, valtype) pairs
    let local_decl_count = reader.read_uleb128_u32().reinterpret_as_int()
    let locals : Array[@wasm_type.ValType] = []
    let mut j = 0
    while j < local_decl_count {
      let n = reader.read_uleb128_u32().reinterpret_as_int()
      let vt = @wasm_type.parse_val_type(reader)
      let mut k = 0
      while k < n {
        locals.push(vt)
        k = k + 1
      }
      j = j + 1
    }

    let code_start = reader.get_offset()
    let consumed = code_start - body_start
    let code_len = body_size - consumed
    let code_bytes = reader.read_bytes(code_len)
    bodies.push({ locals, code: code_bytes })

    // Ensure we consumed exactly body_size bytes
    let actual_consumed = reader.get_offset() - body_start
    if actual_consumed < body_size {
      reader.skip(body_size - actual_consumed)
    }

    i = i + 1
  }
  bodies
}

///|
/// Element segment kind (active, passive, declarative)
pub(all) enum ElemKind {
  Active(table_idx~ : UInt, offset_expr~ : Bytes)
  Passive
  Declarative
} derive(Debug)

///|
/// Parsed element segment
pub(all) struct Element {
  kind : ElemKind
  elem_type : @wasm_type.ElemType
  func_indices : Array[UInt]
} derive(Debug)

///|
/// Parse the Element section payload
pub fn parse_element_section(
  payload : Bytes,
) -> Array[Element] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let elements = Array(capacity=count)
  let mut i = 0
  while i < count {
    let flags = reader.read_uleb128_u32()
    match flags {
      0 => {
        // Active, table 0, funcref, expr offset, vec of func indices
        let offset_start = reader.get_offset()
        let mut b = reader.read_u8()
        while b != b'\x0B' {
          b = reader.read_u8()
        }
        let offset_end = reader.get_offset()
        let expr_len = offset_end - offset_start
        let expr_arr = Array::make(expr_len, b'\x00')
        let mut k = 0
        while k < expr_len {
          expr_arr[k] = payload[offset_start + k]
          k = k + 1
        }
        let num_funcs = reader.read_uleb128_u32().reinterpret_as_int()
        let indices : Array[UInt] = Array(capacity=num_funcs)
        let mut j = 0
        while j < num_funcs {
          indices.push(reader.read_uleb128_u32())
          j = j + 1
        }
        elements.push({
          kind: Active(table_idx=0, offset_expr=Bytes::from_array(expr_arr)),
          elem_type: @wasm_type.FuncRef,
          func_indices: indices,
        })
      }
      1 => {
        // Passive elemkind vec(funcidx)
        let _elemkind = reader.read_u8()
        let num_funcs = reader.read_uleb128_u32().reinterpret_as_int()
        let indices : Array[UInt] = Array(capacity=num_funcs)
        let mut j = 0
        while j < num_funcs {
          indices.push(reader.read_uleb128_u32())
          j = j + 1
        }
        elements.push({
          kind: Passive,
          elem_type: @wasm_type.FuncRef,
          func_indices: indices,
        })
      }
      2 => {
        // Active with explicit table index
        let table_idx = reader.read_uleb128_u32()
        let offset_start = reader.get_offset()
        let mut b = reader.read_u8()
        while b != b'\x0B' {
          b = reader.read_u8()
        }
        let offset_end = reader.get_offset()
        let expr_len = offset_end - offset_start
        let expr_arr = Array::make(expr_len, b'\x00')
        let mut k = 0
        while k < expr_len {
          expr_arr[k] = payload[offset_start + k]
          k = k + 1
        }
        let _elemkind = reader.read_u8()
        let num_funcs = reader.read_uleb128_u32().reinterpret_as_int()
        let indices : Array[UInt] = Array(capacity=num_funcs)
        let mut j = 0
        while j < num_funcs {
          indices.push(reader.read_uleb128_u32())
          j = j + 1
        }
        elements.push({
          kind: Active(
            table_idx~,
            offset_expr=Bytes::from_array(expr_arr),
          ),
          elem_type: @wasm_type.FuncRef,
          func_indices: indices,
        })
      }
      _ => {
        // Other flags: skip as passive for simplicity
        let num_funcs = reader.read_uleb128_u32().reinterpret_as_int()
        let indices : Array[UInt] = Array(capacity=num_funcs)
        let mut j = 0
        while j < num_funcs {
          indices.push(reader.read_uleb128_u32())
          j = j + 1
        }
        elements.push({
          kind: Passive,
          elem_type: @wasm_type.FuncRef,
          func_indices: indices,
        })
      }
    }
    i = i + 1
  }
  elements
}

///|
/// Data segment kind
pub(all) enum DataKind {
  ActiveData(mem_idx~ : UInt, offset_expr~ : Bytes)
  PassiveData
} derive(Debug)

///|
/// Parsed data segment
pub(all) struct DataSegment {
  kind : DataKind
  data : Bytes
} derive(Debug)

///|
/// Parse the Data section payload
pub fn parse_data_section(
  payload : Bytes,
) -> Array[DataSegment] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let segments = Array(capacity=count)
  let mut i = 0
  while i < count {
    let flags = reader.read_uleb128_u32()
    match flags {
      0 => {
        // Active, memory 0, expr offset, bytes
        let offset_start = reader.get_offset()
        let mut b = reader.read_u8()
        while b != b'\x0B' {
          b = reader.read_u8()
        }
        let offset_end = reader.get_offset()
        let expr_len = offset_end - offset_start
        let expr_arr = Array::make(expr_len, b'\x00')
        let mut k = 0
        while k < expr_len {
          expr_arr[k] = payload[offset_start + k]
          k = k + 1
        }
        let data_len = reader.read_uleb128_u32().reinterpret_as_int()
        let data = reader.read_bytes(data_len)
        segments.push({
          kind: ActiveData(
            mem_idx=0,
            offset_expr=Bytes::from_array(expr_arr),
          ),
          data,
        })
      }
      1 => {
        // Passive
        let data_len = reader.read_uleb128_u32().reinterpret_as_int()
        let data = reader.read_bytes(data_len)
        segments.push({ kind: PassiveData, data })
      }
      2 => {
        // Active with explicit memory index
        let mem_idx = reader.read_uleb128_u32()
        let offset_start = reader.get_offset()
        let mut b = reader.read_u8()
        while b != b'\x0B' {
          b = reader.read_u8()
        }
        let offset_end = reader.get_offset()
        let expr_len = offset_end - offset_start
        let expr_arr = Array::make(expr_len, b'\x00')
        let mut k = 0
        while k < expr_len {
          expr_arr[k] = payload[offset_start + k]
          k = k + 1
        }
        let data_len = reader.read_uleb128_u32().reinterpret_as_int()
        let data = reader.read_bytes(data_len)
        segments.push({
          kind: ActiveData(mem_idx~, offset_expr=Bytes::from_array(expr_arr)),
          data,
        })
      }
      _ => {
        let data_len = reader.read_uleb128_u32().reinterpret_as_int()
        let data = reader.read_bytes(data_len)
        segments.push({ kind: PassiveData, data })
      }
    }
    i = i + 1
  }
  segments
}
