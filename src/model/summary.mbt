// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Section summary for reporting
pub(all) struct SectionSummary {
  id : @wasm_section.SectionId
  name : String
  payload_size : UInt
  item_count : UInt?
} derive(Debug)

///|
/// High-level module analysis summary
pub(all) struct ModuleSummary {
  module_name : String
  wasm_version : UInt
  sections : Array[SectionSummary]
  func_types : Array[@wasm_type.FuncType]
  num_imports : UInt
  num_exports : UInt
  num_functions : UInt
  num_globals : UInt
  num_memories : UInt
  num_tables : UInt
  num_data_segments : UInt
  num_elements : UInt
  has_start : Bool
  total_bytes : UInt
} derive(Debug)

///|
/// Generate a ModuleSummary from a WasmModule
pub fn WasmModule::summary(self : WasmModule) -> ModuleSummary {
  let section_summaries : Array[SectionSummary] = []
  for sec in self.binary.sections {
    let mut item_count : UInt? = None
    match sec.id {
      @wasm_section.Type =>
        item_count = Some(self.func_types.length().reinterpret_as_uint())
      @wasm_section.Import =>
        item_count = Some(self.imports.length().reinterpret_as_uint())
      @wasm_section.Function =>
        item_count = Some(self.func_type_indices.length().reinterpret_as_uint())
      @wasm_section.Export =>
        item_count = Some(self.exports.length().reinterpret_as_uint())
      @wasm_section.Global =>
        item_count = Some(self.globals.length().reinterpret_as_uint())
      @wasm_section.Memory =>
        item_count = Some(self.memories.length().reinterpret_as_uint())
      @wasm_section.Table =>
        item_count = Some(self.tables.length().reinterpret_as_uint())
      @wasm_section.Code =>
        item_count = Some(self.bodies.length().reinterpret_as_uint())
      @wasm_section.Data =>
        item_count = Some(self.data_segments.length().reinterpret_as_uint())
      @wasm_section.Element =>
        item_count = Some(self.elements.length().reinterpret_as_uint())
      _ => ()
    }
    section_summaries.push({
      id: sec.id,
      name: sec.id.to_string(),
      payload_size: sec.payload_size,
      item_count,
    })
  }

  let module_name = match self.name_section {
    Some(ns) =>
      match ns.module_name {
        Some(n) => n
        None => self.name
      }
    None => self.name
  }

  {
    module_name,
    wasm_version: self.binary.version,
    sections: section_summaries,
    func_types: self.func_types,
    num_imports: self.imports.length().reinterpret_as_uint(),
    num_exports: self.exports.length().reinterpret_as_uint(),
    num_functions: self.total_functions(),
    num_globals: self.total_globals(),
    num_memories: self.memories.length().reinterpret_as_uint(),
    num_tables: self.tables.length().reinterpret_as_uint(),
    num_data_segments: self.data_segments.length().reinterpret_as_uint(),
    num_elements: self.elements.length().reinterpret_as_uint(),
    has_start: self.start_func is Some(_),
    total_bytes: 0,
  }
}

///|
/// Render summary as plain text
pub fn ModuleSummary::to_text(self : ModuleSummary) -> String {
  let buf = StringBuilder()
  buf.write_string("Wasm Module: \{self.module_name}\n")
  buf.write_string("Version: \{self.wasm_version}\n")
  buf.write_string("Functions: \{self.num_functions}\n")
  buf.write_string("Imports: \{self.num_imports}\n")
  buf.write_string("Exports: \{self.num_exports}\n")
  buf.write_string("Globals: \{self.num_globals}\n")
  buf.write_string("Memories: \{self.num_memories}\n")
  buf.write_string("Tables: \{self.num_tables}\n")
  buf.write_string("Data segments: \{self.num_data_segments}\n")
  buf.write_string("Elements: \{self.num_elements}\n")
  buf.write_string(
    "Start function: \{if self.has_start { "yes" } else { "none" }}\n",
  )
  buf.write_string("Sections: \{self.sections.length()}\n")
  buf.to_string()
}

///|
/// Render summary as Markdown
pub fn ModuleSummary::to_markdown(self : ModuleSummary) -> String {
  let buf = StringBuilder()
  buf.write_string("# Wasm Module Report: \{self.module_name}\n\n")
  buf.write_string("## Overview\n\n")
  buf.write_string("| Property | Value |\n")
  buf.write_string("|----------|-------|\n")
  buf.write_string("| Version | \{self.wasm_version} |\n")
  buf.write_string("| Functions | \{self.num_functions} |\n")
  buf.write_string("| Imports | \{self.num_imports} |\n")
  buf.write_string("| Exports | \{self.num_exports} |\n")
  buf.write_string("| Globals | \{self.num_globals} |\n")
  buf.write_string("| Memories | \{self.num_memories} |\n")
  buf.write_string("| Tables | \{self.num_tables} |\n")
  buf.write_string("| Data segments | \{self.num_data_segments} |\n")
  buf.write_string("| Elements | \{self.num_elements} |\n")
  buf.write_string(
    "| Start function | \{if self.has_start { "yes" } else { "none" }} |\n\n",
  )

  buf.write_string("## Type Signatures\n\n")
  buf.write_string("```\n")
  let mut i = 0
  while i < self.func_types.length() {
    buf.write_string("  [\{i}] \{self.func_types[i].to_string()}\n")
    i = i + 1
  }
  buf.write_string("```\n\n")

  buf.write_string("## Sections\n\n")
  buf.write_string("| Section | Payload Size | Items |\n")
  buf.write_string("|---------|-------------|-------|\n")
  for sec in self.sections {
    let items_str = match sec.item_count {
      Some(n) => n.to_string()
      None => "-"
    }
    buf.write_string(
      "| \{sec.name} | \{sec.payload_size} bytes | \{items_str} |\n",
    )
  }

  buf.to_string()
}

///|
/// Render summary as JSON
pub fn ModuleSummary::to_json(self : ModuleSummary) -> String {
  let buf = StringBuilder()
  buf.write_string("{\n")
  buf.write_string("  \"module_name\": \"\{json_escape(self.module_name)}\",\n")
  buf.write_string("  \"wasm_version\": \{self.wasm_version},\n")
  buf.write_string("  \"functions\": \{self.num_functions},\n")
  buf.write_string("  \"imports\": \{self.num_imports},\n")
  buf.write_string("  \"exports\": \{self.num_exports},\n")
  buf.write_string("  \"globals\": \{self.num_globals},\n")
  buf.write_string("  \"memories\": \{self.num_memories},\n")
  buf.write_string("  \"tables\": \{self.num_tables},\n")
  buf.write_string("  \"data_segments\": \{self.num_data_segments},\n")
  buf.write_string("  \"elements\": \{self.num_elements},\n")
  buf.write_string("  \"has_start\": \{self.has_start},\n")
  buf.write_string("  \"sections\": [\n")
  let mut j = 0
  while j < self.sections.length() {
    let sec = self.sections[j]
    buf.write_string(
      "    { \"name\": \"\{sec.name}\", \"payload_size\": \{sec.payload_size}",
    )
    match sec.item_count {
      Some(n) => buf.write_string(", \"items\": \{n}")
      None => ()
    }
    if j < self.sections.length() - 1 {
      buf.write_string(" },\n")
    } else {
      buf.write_string(" }\n")
    }
    j = j + 1
  }
  buf.write_string("  ]\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Escape string for JSON output
pub fn json_escape(s : String) -> String {
  let buf = StringBuilder()
  for ch in s {
    match ch {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(ch)
    }
  }
  buf.to_string()
}
