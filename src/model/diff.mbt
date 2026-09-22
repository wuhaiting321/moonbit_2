// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Diff result between two modules
pub(all) struct ModuleDiff {
  types_added : Array[@wasm_type.FuncType]
  types_removed : Array[@wasm_type.FuncType]
  exports_added : Array[@wasm_section.Export]
  exports_removed : Array[@wasm_section.Export]
  imports_added : Array[@wasm_section.Import]
  imports_removed : Array[@wasm_section.Import]
  function_count_delta : Int
  global_count_delta : Int
} derive(Debug)

///|
/// Compare two modules and produce a diff
pub fn diff_modules(a : WasmModule, b : WasmModule) -> ModuleDiff {
  let types_added : Array[@wasm_type.FuncType] = []
  let types_removed : Array[@wasm_type.FuncType] = []

  // Compare type signatures
  for ft in b.func_types {
    let mut found = false
    for at in a.func_types {
      if ft == at {
        found = true
        break
      }
    }
    if !found {
      types_added.push(ft)
    }
  }
  for ft in a.func_types {
    let mut found = false
    for bt in b.func_types {
      if ft == bt {
        found = true
        break
      }
    }
    if !found {
      types_removed.push(ft)
    }
  }

  // Compare exports by name
  let exports_added : Array[@wasm_section.Export] = []
  let exports_removed : Array[@wasm_section.Export] = []
  for exp in b.exports {
    let mut found = false
    for ae in a.exports {
      if exp.name == ae.name {
        found = true
        break
      }
    }
    if !found {
      exports_added.push(exp)
    }
  }
  for exp in a.exports {
    let mut found = false
    for be in b.exports {
      if exp.name == be.name {
        found = true
        break
      }
    }
    if !found {
      exports_removed.push(exp)
    }
  }

  // Compare imports by module.name
  let imports_added : Array[@wasm_section.Import] = []
  let imports_removed : Array[@wasm_section.Import] = []
  for imp in b.imports {
    let key_b = "\{imp.mod_name}.\{imp.name}"
    let mut found = false
    for ai in a.imports {
      let key_a = "\{ai.mod_name}.\{ai.name}"
      if key_b == key_a {
        found = true
        break
      }
    }
    if !found {
      imports_added.push(imp)
    }
  }
  for imp in a.imports {
    let key_a = "\{imp.mod_name}.\{imp.name}"
    let mut found = false
    for bi in b.imports {
      let key_b = "\{bi.mod_name}.\{bi.name}"
      if key_a == key_b {
        found = true
        break
      }
    }
    if !found {
      imports_removed.push(imp)
    }
  }

  let func_a = a.total_functions().reinterpret_as_int()
  let func_b = b.total_functions().reinterpret_as_int()
  let global_a = a.total_globals().reinterpret_as_int()
  let global_b = b.total_globals().reinterpret_as_int()

  {
    types_added,
    types_removed,
    exports_added,
    exports_removed,
    imports_added,
    imports_removed,
    function_count_delta: func_b - func_a,
    global_count_delta: global_b - global_a,
  }
}

///|
/// Render diff as Markdown
pub fn ModuleDiff::to_markdown(self : ModuleDiff) -> String {
  let buf = StringBuilder()
  buf.write_string("# Module Diff Report\n\n")

  buf.write_string("## Type Changes\n\n")
  if self.types_added.length() > 0 {
    buf.write_string("### Added Types\n")
    for ft in self.types_added {
      buf.write_string("- `\{ft.to_string()}`\n")
    }
    buf.write_string("\n")
  }
  if self.types_removed.length() > 0 {
    buf.write_string("### Removed Types\n")
    for ft in self.types_removed {
      buf.write_string("- `\{ft.to_string()}`\n")
    }
    buf.write_string("\n")
  }

  buf.write_string("## Export Changes\n\n")
  if self.exports_added.length() > 0 {
    buf.write_string("### Added Exports\n")
    for exp in self.exports_added {
      buf.write_string("- `\{exp.to_string()}`\n")
    }
    buf.write_string("\n")
  }
  if self.exports_removed.length() > 0 {
    buf.write_string("### Removed Exports\n")
    for exp in self.exports_removed {
      buf.write_string("- `\{exp.to_string()}`\n")
    }
    buf.write_string("\n")
  }

  buf.write_string("## Import Changes\n\n")
  if self.imports_added.length() > 0 {
    buf.write_string("### Added Imports\n")
    for imp in self.imports_added {
      buf.write_string("- `\{imp.to_string()}`\n")
    }
    buf.write_string("\n")
  }
  if self.imports_removed.length() > 0 {
    buf.write_string("### Removed Imports\n")
    for imp in self.imports_removed {
      buf.write_string("- `\{imp.to_string()}`\n")
    }
    buf.write_string("\n")
  }

  buf.write_string("## Count Deltas\n\n")
  buf.write_string("| Entity | Delta |\n")
  buf.write_string("|--------|-------|\n")
  buf.write_string(
    "| Functions | \{if self.function_count_delta >= 0 { "+" } else { "" }}\{self.function_count_delta} |\n",
  )
  buf.write_string(
    "| Globals | \{if self.global_count_delta >= 0 { "+" } else { "" }}\{self.global_count_delta} |\n",
  )

  buf.to_string()
}

///|
/// Build an export index mapping names to export entries
pub fn WasmModule::export_index(
  self : WasmModule,
) -> Array[@wasm_section.Export] {
  self.exports
}

///|
/// Find export by name
pub fn WasmModule::find_export(
  self : WasmModule,
  name : String,
) -> @wasm_section.Export? {
  let mut i = 0
  while i < self.exports.length() {
    if self.exports[i].name == name {
      return Some(self.exports[i])
    }
    i = i + 1
  }
  None
}
