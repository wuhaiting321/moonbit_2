// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
pub suberror CustomError {
  InvalidNameSection(reason~ : String)
} derive(Debug, Eq)

///|
/// Custom section wrapper
pub(all) struct CustomSection {
  name : String
  payload : Bytes
} derive(Debug)

///|
/// Parse a custom section payload (name + remaining bytes)
pub fn parse_custom_section(
  payload : Bytes,
) -> CustomSection raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let name = reader.read_wasm_name()
  let remaining = reader.remaining()
  let data = reader.read_bytes(remaining)
  { name, payload: data }
}

///|
/// Name subsection identifiers
pub(all) enum NameSubsectionId {
  ModuleName
  FunctionNames
  LocalNames
  Other(Byte)
} derive(Debug, Eq)

///|
/// Name map entry (index -> name)
pub(all) struct NameEntry {
  index : UInt
  name : String
} derive(Debug, Eq)

///|
/// Parsed name custom section
pub(all) struct NameSection {
  module_name : String?
  function_names : Array[NameEntry]
  local_names : Array[(UInt, Array[NameEntry])]
} derive(Debug)

///|
/// Parse the name custom section
pub fn parse_name_section(
  payload : Bytes,
) -> NameSection raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)

  // Read section name first
  let section_name = reader.read_wasm_name()
  if section_name != "name" {
    raise InvalidNameSection(reason="expected name section, got: \{section_name}")
  }

  let mut module_name : String? = None
  let function_names : Array[NameEntry] = []
  let local_names : Array[(UInt, Array[NameEntry])] = []

  while reader.remaining() > 0 {
    let subsection_id = reader.read_u8()
    let subsection_size = reader.read_uleb128_u32().reinterpret_as_int()
    let subsection_start = reader.get_offset()

    match subsection_id {
      b'\x00' => {
        // Module name
        module_name = Some(reader.read_wasm_name())
      }
      b'\x01' => {
        // Function names: name map
        let count = reader.read_uleb128_u32().reinterpret_as_int()
        let mut i = 0
        while i < count {
          let idx = reader.read_uleb128_u32()
          let name = reader.read_wasm_name()
          function_names.push({ index: idx, name })
          i = i + 1
        }
      }
      b'\x02' => {
        // Local names: indirect name map
        let count = reader.read_uleb128_u32().reinterpret_as_int()
        let mut i = 0
        while i < count {
          let func_idx = reader.read_uleb128_u32()
          let local_count = reader.read_uleb128_u32().reinterpret_as_int()
          let entries : Array[NameEntry] = Array(capacity=local_count)
          let mut j = 0
          while j < local_count {
            let local_idx = reader.read_uleb128_u32()
            let name = reader.read_wasm_name()
            entries.push({ index: local_idx, name })
            j = j + 1
          }
          local_names.push((func_idx, entries))
          i = i + 1
        }
      }
      _ => {
        // Unknown subsection: skip
        let consumed = reader.get_offset() - subsection_start
        if consumed < subsection_size {
          reader.skip(subsection_size - consumed)
        }
      }
    }

    // Ensure we consumed exactly subsection_size bytes
    let actual_consumed = reader.get_offset() - subsection_start
    if actual_consumed < subsection_size {
      reader.skip(subsection_size - actual_consumed)
    }
  }

  { module_name, function_names, local_names }
}

///|
/// Lookup function name by index
pub fn NameSection::function_name(
  self : NameSection,
  index : UInt,
) -> String? {
  let mut i = 0
  while i < self.function_names.length() {
    if self.function_names[i].index == index {
      return Some(self.function_names[i].name)
    }
    i = i + 1
  }
  None
}
