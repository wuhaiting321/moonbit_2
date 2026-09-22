// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Print section headers table
pub fn dump_sections(wm : @model.WasmModule) -> Unit {
  println("Section Headers:")
  println("  [Nr] Name              Size        Items")
  let mut i = 0
  while i < wm.binary.sections.length() {
    let sec = wm.binary.sections[i]
    println(
      "  [\{i}]  \{sec.id.to_string()}     \{sec.payload_size} bytes",
    )
    i = i + 1
  }
}

///|
/// Print type signatures
pub fn dump_types(wm : @model.WasmModule) -> Unit {
  println("Type Signatures:")
  let mut i = 0
  while i < wm.func_types.length() {
    println("  [\{i}] \{wm.func_types[i].to_string()}")
    i = i + 1
  }
}

///|
/// Print import entries
pub fn dump_imports(wm : @model.WasmModule) -> Unit {
  println("Imports:")
  let mut i = 0
  while i < wm.imports.length() {
    println("  [\{i}] \{wm.imports[i].to_string()}")
    i = i + 1
  }
}

///|
/// Print export entries
pub fn dump_exports(wm : @model.WasmModule) -> Unit {
  println("Exports:")
  let mut i = 0
  while i < wm.exports.length() {
    println("  [\{i}] \{wm.exports[i].to_string()}")
    i = i + 1
  }
}

///|
/// Print function entries with type signatures
pub fn dump_functions(wm : @model.WasmModule) -> Unit {
  println("Functions:")
  let mut import_func_count : UInt = 0
  for imp in wm.imports {
    match imp.desc {
      @wasm_section.FuncTypeIdx(_) => import_func_count = import_func_count + 1
      _ => ()
    }
  }
  let mut i = 0
  while i < wm.func_type_indices.length() {
    let type_idx = wm.func_type_indices[i]
    let func_idx = import_func_count + i.reinterpret_as_uint()
    let type_str = if type_idx < wm.func_types.length().reinterpret_as_uint() {
      wm.func_types[type_idx.reinterpret_as_int()].to_string()
    } else {
      "unknown"
    }
    println("  [\{func_idx}] \{type_str}")
    i = i + 1
  }
}

///|
/// Print global entries
pub fn dump_globals(wm : @model.WasmModule) -> Unit {
  println("Globals:")
  let mut i = 0
  while i < wm.globals.length() {
    println("  [\{i}] \{wm.globals[i].global_type.to_string()}")
    i = i + 1
  }
}

///|
/// Print memory entries
pub fn dump_memories(wm : @model.WasmModule) -> Unit {
  println("Memories:")
  let mut i = 0
  while i < wm.memories.length() {
    println("  [\{i}] \{wm.memories[i].mem_type.limits.to_string()}")
    i = i + 1
  }
}

///|
/// Print table entries
pub fn dump_tables(wm : @model.WasmModule) -> Unit {
  println("Tables:")
  let mut i = 0
  while i < wm.tables.length() {
    println("  [\{i}] \{wm.tables[i].table_type.to_string()}")
    i = i + 1
  }
}

///|
/// Execute CLI action dispatch
pub fn execute_cli_action(
  opts : CliOptions,
  wm : @model.WasmModule,
) -> Unit {
  if opts.show_sections {
    dump_sections(wm)
  }
  if opts.show_types {
    dump_types(wm)
  }
  if opts.show_imports {
    dump_imports(wm)
  }
  if opts.show_exports {
    dump_exports(wm)
  }
  if opts.show_functions {
    dump_functions(wm)
  }
  if opts.show_globals {
    dump_globals(wm)
  }
  if opts.show_memories {
    dump_memories(wm)
  }
  if opts.show_tables {
    dump_tables(wm)
  }
  match opts.disassemble_func {
    Some(idx) => {
      println("Disassembly of function \{idx}:")
      let lines = wm.disassemble_func(idx) catch {
        e => {
          println("Error: \{e}")
          return
        }
      }
      for line in lines {
        println("  \{line}")
      }
    }
    None => ()
  }
  if opts.do_validate {
    let result = wm.validate()
    if result.is_valid {
      println("Validation: PASSED")
    } else {
      println("Validation: FAILED")
      for err in result.errors {
        println("  Error: \{err}")
      }
    }
  }
}

///|
/// Render analysis summary in the specified format
pub fn render_analysis_summary(
  summary : @model.ModuleSummary,
  format : String,
) -> String {
  match format.to_lower() {
    "markdown" => summary.to_markdown()
    "json" => summary.to_json()
    _ => summary.to_text()
  }
}
