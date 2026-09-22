// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
pub suberror ModelError {
  FuncIndexOutOfRange(index~ : UInt)
} derive(Debug, Eq)

///|
/// High-Level Wasm Module Analyzer
pub(all) struct WasmModule {
  name : String
  binary : @wasm_section.WasmBinary
  func_types : Array[@wasm_type.FuncType]
  imports : Array[@wasm_section.Import]
  func_type_indices : Array[UInt]
  tables : Array[@wasm_section.TableEntry]
  memories : Array[@wasm_section.MemoryEntry]
  globals : Array[@wasm_section.GlobalEntry]
  exports : Array[@wasm_section.Export]
  start_func : UInt?
  bodies : Array[@wasm_section.FuncBody]
  elements : Array[@wasm_section.Element]
  data_segments : Array[@wasm_section.DataSegment]
  custom_sections : Array[@wasm_custom.CustomSection]
  name_section : @wasm_custom.NameSection?
  byte_length : UInt
} derive(Debug)

///|
/// Parse a WasmModule from binary bytes
pub fn WasmModule::parse(
  name : String,
  bytes : Bytes,
) -> WasmModule raise Error {
  let binary = @wasm_section.parse_wasm_binary(bytes)
  let byte_length = bytes.length().reinterpret_as_uint()

  // Parse type section
  let func_types : Array[@wasm_type.FuncType] = match
    binary.find_section(@wasm_section.Type) {
    Some(sec) => @wasm_section.parse_type_section(sec.payload) catch { _ => [] }
    None => []
  }

  // Parse import section
  let imports : Array[@wasm_section.Import] = match
    binary.find_section(@wasm_section.Import) {
    Some(sec) =>
      @wasm_section.parse_import_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse function section
  let func_type_indices : Array[UInt] = match
    binary.find_section(@wasm_section.Function) {
    Some(sec) =>
      @wasm_section.parse_function_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse table section
  let tables : Array[@wasm_section.TableEntry] = match
    binary.find_section(@wasm_section.Table) {
    Some(sec) =>
      @wasm_section.parse_table_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse memory section
  let memories : Array[@wasm_section.MemoryEntry] = match
    binary.find_section(@wasm_section.Memory) {
    Some(sec) =>
      @wasm_section.parse_memory_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse global section
  let globals : Array[@wasm_section.GlobalEntry] = match
    binary.find_section(@wasm_section.Global) {
    Some(sec) =>
      @wasm_section.parse_global_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse export section
  let exports : Array[@wasm_section.Export] = match
    binary.find_section(@wasm_section.Export) {
    Some(sec) =>
      @wasm_section.parse_export_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse start section
  let start_func : UInt? = match binary.find_section(@wasm_section.Start) {
    Some(sec) => {
      let idx = @wasm_section.parse_start_section(sec.payload) catch {
        _ =>
          return {
            name,
            binary,
            func_types,
            imports,
            func_type_indices,
            tables,
            memories,
            globals,
            exports,
            start_func: None,
            bodies: [],
            elements: [],
            data_segments: [],
            custom_sections: [],
            name_section: None,
            byte_length,
          }
      }
      Some(idx)
    }
    None => None
  }

  // Parse element section
  let elements : Array[@wasm_section.Element] = match
    binary.find_section(@wasm_section.Element) {
    Some(sec) =>
      @wasm_section.parse_element_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse code section
  let bodies : Array[@wasm_section.FuncBody] = match
    binary.find_section(@wasm_section.Code) {
    Some(sec) => @wasm_section.parse_code_section(sec.payload) catch { _ => [] }
    None => []
  }

  // Parse data section
  let data_segments : Array[@wasm_section.DataSegment] = match
    binary.find_section(@wasm_section.Data) {
    Some(sec) => @wasm_section.parse_data_section(sec.payload) catch { _ => [] }
    None => []
  }

  // Parse custom sections
  let custom_sections : Array[@wasm_custom.CustomSection] = []
  let mut name_section : @wasm_custom.NameSection? = None
  let customs = binary.custom_sections()
  for csec in customs {
    let parsed = @wasm_custom.parse_custom_section(csec.payload) catch {
      _ => continue
    }
    if parsed.name == "name" {
      let ns = @wasm_custom.parse_name_section(csec.payload) catch {
        _ => continue
      }
      name_section = Some(ns)
    }
    custom_sections.push(parsed)
  }

  {
    name,
    binary,
    func_types,
    imports,
    func_type_indices,
    tables,
    memories,
    globals,
    exports,
    start_func,
    bodies,
    elements,
    data_segments,
    custom_sections,
    name_section,
    byte_length,
  }
}

///|
/// Count total functions (imported + defined)
pub fn WasmModule::total_functions(self : WasmModule) -> UInt {
  let mut count : UInt = 0
  for imp in self.imports {
    match imp.desc {
      @wasm_section.FuncTypeIdx(_) => count = count + 1
      _ => ()
    }
  }
  count + self.func_type_indices.length().reinterpret_as_uint()
}

///|
/// Count total globals (imported + defined)
pub fn WasmModule::total_globals(self : WasmModule) -> UInt {
  let mut count : UInt = 0
  for imp in self.imports {
    match imp.desc {
      @wasm_section.Global(_) => count = count + 1
      _ => ()
    }
  }
  count + self.globals.length().reinterpret_as_uint()
}

///|
/// Get the function type for a given function index
pub fn WasmModule::get_func_type(
  self : WasmModule,
  func_idx : UInt,
) -> @wasm_type.FuncType? {
  // Check imports first
  let mut import_func_count : UInt = 0
  for imp in self.imports {
    match imp.desc {
      @wasm_section.FuncTypeIdx(type_idx) => {
        if import_func_count == func_idx {
          if type_idx < self.func_types.length().reinterpret_as_uint() {
            return Some(self.func_types[type_idx.reinterpret_as_int()])
          }
          return None
        }
        import_func_count = import_func_count + 1
      }
      _ => ()
    }
  }

  // Check defined functions
  if func_idx < import_func_count {
    return None
  }
  let defined_idx = func_idx - import_func_count
  if defined_idx < self.func_type_indices.length().reinterpret_as_uint() {
    let type_idx = self.func_type_indices[defined_idx.reinterpret_as_int()]
    if type_idx < self.func_types.length().reinterpret_as_uint() {
      return Some(self.func_types[type_idx.reinterpret_as_int()])
    }
  }
  None
}

///|
/// Disassemble a specific function body by index
pub fn WasmModule::disassemble_func(
  self : WasmModule,
  func_idx : UInt,
) -> Array[String] raise Error {
  let mut import_func_count : UInt = 0
  for imp in self.imports {
    match imp.desc {
      @wasm_section.FuncTypeIdx(_) => import_func_count = import_func_count + 1
      _ => ()
    }
  }
  if func_idx < import_func_count {
    raise FuncIndexOutOfRange(index=func_idx)
  }
  let body_idx = func_idx - import_func_count
  if body_idx >= self.bodies.length().reinterpret_as_uint() {
    raise FuncIndexOutOfRange(index=func_idx)
  }
  let body = self.bodies[body_idx.reinterpret_as_int()]
  @wasm_bytecode.disassemble_function(body.code)
}

///|
/// Validate the module
pub fn WasmModule::validate(self : WasmModule) -> @wasm_valid.ValidResult {
  @wasm_valid.validate_module(self.binary)
}
