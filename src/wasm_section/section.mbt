// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Section parsing errors
pub suberror SectionError {
  InvalidMagic
  InvalidVersion(version~ : UInt)
  InvalidSectionId(id~ : Byte)
  UnsupportedSegmentFlags(section~ : String, flags~ : UInt)
} derive(Debug, Eq)

///|
/// Standard Wasm section identifiers
pub(all) enum SectionId {
  Custom
  Type
  Import
  Function
  Table
  Memory
  Global
  Export
  Start
  Element
  Code
  Data
  DataCount
} derive(Debug, Eq)

///|
/// Section ID numeric value
pub fn SectionId::to_id(self : SectionId) -> Byte {
  match self {
    Custom => b'\x00'
    Type => b'\x01'
    Import => b'\x02'
    Function => b'\x03'
    Table => b'\x04'
    Memory => b'\x05'
    Global => b'\x06'
    Export => b'\x07'
    Start => b'\x08'
    Element => b'\x09'
    Code => b'\x0A'
    Data => b'\x0B'
    DataCount => b'\x0C'
  }
}

///|
/// Display section name
pub fn SectionId::to_string(self : SectionId) -> String {
  match self {
    Custom => "custom"
    Type => "type"
    Import => "import"
    Function => "function"
    Table => "table"
    Memory => "memory"
    Global => "global"
    Export => "export"
    Start => "start"
    Element => "element"
    Code => "code"
    Data => "data"
    DataCount => "datacount"
  }
}

///|
/// Decode section ID from byte
pub fn parse_section_id(code : Byte) -> SectionId raise SectionError {
  match code {
    b'\x00' => Custom
    b'\x01' => Type
    b'\x02' => Import
    b'\x03' => Function
    b'\x04' => Table
    b'\x05' => Memory
    b'\x06' => Global
    b'\x07' => Export
    b'\x08' => Start
    b'\x09' => Element
    b'\x0A' => Code
    b'\x0B' => Data
    b'\x0C' => DataCount
    _ => raise InvalidSectionId(id=code)
  }
}

///|
/// Raw section header with payload
pub(all) struct RawSection {
  id : SectionId
  payload_size : UInt
  payload : Bytes
} derive(Debug)

///|
/// Top-level Wasm module container (raw parsed form)
pub(all) struct WasmBinary {
  version : UInt
  sections : Array[RawSection]
} derive(Debug)

///|
/// Parse the Wasm magic number and version, then all sections
pub fn parse_wasm_binary(bytes : Bytes) -> WasmBinary raise Error {
  let reader = @binary_reader.BinaryReader::new(bytes)

  // Magic number: \0asm
  let m0 = reader.read_u8()
  let m1 = reader.read_u8()
  let m2 = reader.read_u8()
  let m3 = reader.read_u8()
  if m0 != b'\x00' || m1 != b'\x61' || m2 != b'\x73' || m3 != b'\x6D' {
    raise InvalidMagic
  }

  // Version (currently only version 1 is valid)
  let version = reader.read_u32()
  if version != 1 {
    raise InvalidVersion(version~)
  }

  let sections : Array[RawSection] = []

  while reader.remaining() > 0 {
    let id_byte = reader.read_u8()
    let id = parse_section_id(id_byte)
    let payload_size = reader.read_uleb128_u32()
    let payload_size_int = payload_size.reinterpret_as_int()
    let payload = reader.read_bytes(payload_size_int)
    sections.push({ id, payload_size, payload, })
  }

  { version, sections, }
}

///|
/// Find first section by ID
pub fn WasmBinary::find_section(
  self : WasmBinary,
  id : SectionId,
) -> RawSection? {
  let mut i = 0
  while i < self.sections.length() {
    if self.sections[i].id == id {
      return Some(self.sections[i])
    }
    i = i + 1
  }
  None
}

///|
/// Collect all custom sections
pub fn WasmBinary::custom_sections(self : WasmBinary) -> Array[RawSection] {
  let result : Array[RawSection] = []
  let mut i = 0
  while i < self.sections.length() {
    if self.sections[i].id == Custom {
      result.push(self.sections[i])
    }
    i = i + 1
  }
  result
}
