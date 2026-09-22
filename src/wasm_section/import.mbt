// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Import descriptor kinds
pub(all) enum ImportKind {
  FunctionKind
  TableKind
  MemoryKind
  GlobalKind
} derive(Debug, Eq)

///|
/// Decode import kind from byte
pub fn parse_import_kind(
  reader : @binary_reader.BinaryReader,
) -> ImportKind raise Error {
  let code = reader.read_u8()
  match code {
    b'\x00' => FunctionKind
    b'\x01' => TableKind
    b'\x02' => MemoryKind
    b'\x03' => GlobalKind
    _ => raise InvalidSectionId(id=code)
  }
}

///|
/// Import descriptor payload
pub(all) enum ImportDesc {
  FuncTypeIdx(UInt)
  Table(@wasm_type.TableType)
  Memory(@wasm_type.MemType)
  Global(@wasm_type.GlobalType)
} derive(Debug, Eq)

///|
/// A single import entry
pub(all) struct Import {
  mod_name : String
  name : String
  desc : ImportDesc
} derive(Debug, Eq)

///|
/// Display import in readable form
pub fn Import::to_string(self : Import) -> String {
  let desc_str = match self.desc {
    FuncTypeIdx(idx) => "func[\{idx}]"
    Table(tt) => "table(\{tt.to_string()})"
    Memory(mt) => "memory(\{mt.limits.to_string()})"
    Global(gt) => "global(\{gt.to_string()})"
  }
  "(import \"\{self.mod_name}\" \"\{self.name}\" \{desc_str})"
}

///|
/// Parse import descriptor
fn parse_import_desc(
  reader : @binary_reader.BinaryReader,
) -> ImportDesc raise Error {
  let kind = parse_import_kind(reader)
  match kind {
    FunctionKind => {
      let idx = reader.read_uleb128_u32()
      FuncTypeIdx(idx)
    }
    TableKind => {
      let tt = @wasm_type.parse_table_type(reader)
      Table(tt)
    }
    MemoryKind => {
      let mt = @wasm_type.parse_mem_type(reader)
      Memory(mt)
    }
    GlobalKind => {
      let gt = @wasm_type.parse_global_type(reader)
      Global(gt)
    }
  }
}

///|
/// Parse the Import section payload
pub fn parse_import_section(payload : Bytes) -> Array[Import] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let imports = Array(capacity=count)
  let mut i = 0
  while i < count {
    let mod_name = reader.read_wasm_name()
    let name = reader.read_wasm_name()
    let desc = parse_import_desc(reader)
    imports.push({ mod_name, name, desc, })
    i = i + 1
  }
  imports
}

///|
/// Export kinds
pub(all) enum ExportKind {
  FuncExport
  TableExport
  MemExport
  GlobalExport
} derive(Debug, Eq)

///|
/// A single export entry
pub(all) struct Export {
  name : String
  kind : ExportKind
  index : UInt
} derive(Debug, Eq)

///|
/// Display export in readable form
pub fn Export::to_string(self : Export) -> String {
  let kind_str = match self.kind {
    FuncExport => "func"
    TableExport => "table"
    MemExport => "memory"
    GlobalExport => "global"
  }
  "(export \"\{self.name}\" (\{kind_str} \{self.index}))"
}

///|
/// Parse the Export section payload
pub fn parse_export_section(payload : Bytes) -> Array[Export] raise Error {
  let reader = @binary_reader.BinaryReader::new(payload)
  let count = reader.read_uleb128_u32().reinterpret_as_int()
  let exports = Array(capacity=count)
  let mut i = 0
  while i < count {
    let name = reader.read_wasm_name()
    let kind_byte = reader.read_u8()
    let kind : ExportKind = match kind_byte {
      b'\x00' => FuncExport
      b'\x01' => TableExport
      b'\x02' => MemExport
      b'\x03' => GlobalExport
      _ => raise InvalidSectionId(id=kind_byte)
    }
    let index = reader.read_uleb128_u32()
    exports.push({ name, kind, index, })
    i = i + 1
  }
  exports
}
