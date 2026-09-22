// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Validate an entire parsed Wasm module
pub fn validate_module(
  binary : @wasm_section.WasmBinary,
) -> ValidResult {
  let result = ValidResult::ok()

  // Extract sections
  let type_sec = binary.find_section(@wasm_section.Type)
  let import_sec = binary.find_section(@wasm_section.Import)
  let func_sec = binary.find_section(@wasm_section.Function)
  let table_sec = binary.find_section(@wasm_section.Table)
  let memory_sec = binary.find_section(@wasm_section.Memory)
  let global_sec = binary.find_section(@wasm_section.Global)
  let export_sec = binary.find_section(@wasm_section.Export)
  let start_sec = binary.find_section(@wasm_section.Start)
  let code_sec = binary.find_section(@wasm_section.Code)

  // Parse type section
  let func_types : Array[@wasm_type.FuncType] = match type_sec {
    Some(sec) =>
      @wasm_section.parse_type_section(sec.payload) catch {
        _ => {
          result.merge(ValidResult::fail("type section parse error"))
          []
        }
      }
    None => []
  }

  // Parse imports to count imported entities
  let imports : Array[@wasm_section.Import] = match import_sec {
    Some(sec) =>
      @wasm_section.parse_import_section(sec.payload) catch {
        _ => {
          result.merge(ValidResult::fail("import section parse error"))
          []
        }
      }
    None => []
  }

  let mut num_import_funcs : UInt = 0
  let mut num_import_globals : UInt = 0
  let mut num_import_tables : UInt = 0
  let mut num_import_memories : UInt = 0
  for imp in imports {
    match imp.desc {
      @wasm_section.FuncTypeIdx(type_idx) => {
        if type_idx >= func_types.length().reinterpret_as_uint() {
          result.merge(
            ValidResult::fail(
              "import references invalid type index \{type_idx}",
            ),
          )
        }
        num_import_funcs = num_import_funcs + 1
      }
      @wasm_section.Global(_) =>
        num_import_globals = num_import_globals + 1
      @wasm_section.Table(_) =>
        num_import_tables = num_import_tables + 1
      @wasm_section.Memory(_) =>
        num_import_memories = num_import_memories + 1
    }
  }

  // Parse function section
  let func_type_indices : Array[UInt] = match func_sec {
    Some(sec) =>
      @wasm_section.parse_function_section(sec.payload) catch {
        _ => {
          result.merge(ValidResult::fail("function section parse error"))
          []
        }
      }
    None => []
  }

  // Validate function type indices
  for type_idx in func_type_indices {
    if type_idx >= func_types.length().reinterpret_as_uint() {
      result.merge(
        ValidResult::fail(
          "function references invalid type index \{type_idx}",
        ),
      )
    }
  }

  // Parse tables
  let tables : Array[@wasm_section.TableEntry] = match table_sec {
    Some(sec) =>
      @wasm_section.parse_table_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Parse memories
  let memories : Array[@wasm_section.MemoryEntry] = match memory_sec {
    Some(sec) =>
      @wasm_section.parse_memory_section(sec.payload) catch {
        _ => []
      }
    None => []
  }

  // Validate memory count (at most 1)
  let total_memories = num_import_memories + memories.length().reinterpret_as_uint()
  if total_memories > 1 {
    result.merge(
      ValidResult::fail(
        "multiple memories not allowed (found \{total_memories})",
      ),
    )
  }

  // Validate table count (at most 1 in MVP)
  let total_tables = num_import_tables + tables.length().reinterpret_as_uint()
  if total_tables > 1 {
    result.merge(
      ValidResult::fail(
        "multiple tables not allowed in MVP (found \{total_tables})",
      ),
    )
  }

  // Parse globals
  let globals : Array[@wasm_section.GlobalEntry] = match global_sec {
    Some(sec) =>
      @wasm_section.parse_global_section(sec.payload) catch {
        _ => []
      }
    None => []
  }
  let _num_globals = num_import_globals + globals.length().reinterpret_as_uint()

  // Parse exports and check for duplicates
  let exports : Array[@wasm_section.Export] = match export_sec {
    Some(sec) =>
      @wasm_section.parse_export_section(sec.payload) catch {
        _ => []
      }
    None => []
  }
  validate_export_names(exports, result)

  // Validate start function
  match start_sec {
    Some(sec) => {
      let start_idx = @wasm_section.parse_start_section(sec.payload) catch {
        _ => 0
      }
      let total_funcs = num_import_funcs + func_type_indices.length().reinterpret_as_uint()
      if start_idx >= total_funcs {
        result.merge(
          ValidResult::fail(
            "start function index \{start_idx} out of range (max \{total_funcs})",
          ),
        )
      }
    }
    None => ()
  }

  // Validate code/function count match
  let num_defined_funcs = func_type_indices.length().reinterpret_as_uint()
  match code_sec {
    Some(sec) => {
      let bodies = @wasm_section.parse_code_section(sec.payload) catch {
        _ => []
      }
      let num_bodies = bodies.length().reinterpret_as_uint()
      if num_defined_funcs != num_bodies {
        result.merge(
          ValidResult::fail(
            "function count (\{num_defined_funcs}) != code count (\{num_bodies})",
          ),
        )
      }
      // Validate each function body
      let num_globals = num_import_globals + globals.length().reinterpret_as_uint()
      let num_memories = num_import_memories + memories.length().reinterpret_as_uint()
      let num_tables_total = num_import_tables + tables.length().reinterpret_as_uint()
      let mut func_i = 0
      while func_i < bodies.length() {
        let body = bodies[func_i]
        let type_idx = if func_i < func_type_indices.length() {
          func_type_indices[func_i]
        } else {
          0
        }
        let func_type = if type_idx < func_types.length().reinterpret_as_uint() {
          Some(func_types[type_idx.reinterpret_as_int()])
        } else {
          None
        }
        validate_function_body(
          body,
          func_type,
          func_types,
          num_import_funcs,
          num_defined_funcs,
          num_globals,
          num_memories,
          num_tables_total,
          func_i,
          result,
        )
        func_i = func_i + 1
      }
    }
    None => {
      if num_defined_funcs > 0 {
        result.merge(
          ValidResult::fail(
            "functions defined but no code section present",
          ),
        )
      }
    }
  }

  result
}

///|
/// Check exports for duplicate names
pub fn validate_export_names(
  exports : Array[@wasm_section.Export],
  result : ValidResult,
) -> Unit {
  let seen : Array[String] = []
  for exp in exports {
    let mut is_dup = false
    let mut j = 0
    while j < seen.length() {
      if seen[j] == exp.name {
        is_dup = true
        break
      }
      j = j + 1
    }
    if is_dup {
      result.merge(
        ValidResult::fail("duplicate export name: \"\{exp.name}\""),
      )
    } else {
      seen.push(exp.name)
    }
  }
}

///|
/// Validate a single function body: decode instructions, check indices,
/// and verify control-flow structure
fn validate_function_body(
  body : @wasm_section.FuncBody,
  func_type : @wasm_type.FuncType?,
  func_types : Array[@wasm_type.FuncType],
  num_import_funcs : UInt,
  num_defined_funcs : UInt,
  num_globals : UInt,
  num_memories : UInt,
  num_tables : UInt,
  func_index : Int,
  result : ValidResult,
) -> Unit {
  // Build local types: params + body locals
  let local_types : Array[@wasm_type.ValType] = []
  match func_type {
    Some(ft) =>
      for p in ft.params {
        local_types.push(p)
      }
    None => ()
  }
  for lt in body.locals {
    local_types.push(lt)
  }

  let tc = TypeChecker::new(
    func_types,
    local_types,
    num_import_funcs,
    num_defined_funcs,
    num_globals,
    num_memories,
    num_tables,
  )

  // Push the function's implicit block frame
  let result_types : Array[@wasm_type.ValType] = match func_type {
    Some(ft) => ft.results
    None => []
  }
  tc.push_frame(@wasm_bytecode.Block, [], result_types)

  let reader = @binary_reader.BinaryReader::new(body.code)
  let mut inst_count = 0
  while reader.remaining() > 0 {
    let inst = @wasm_bytecode.decode_instruction(reader) catch {
      _ => {
        result.merge(
          ValidResult::fail(
            "func[\{func_index}]: decode error at instruction \{inst_count}",
          ),
        )
        return
      }
    }

    // Validate index references
    match inst.opcode {
      @wasm_bytecode.Call =>
        match inst.func_index {
          Some(idx) =>
            tc.check_func_index(idx) catch {
              _ =>
                result.merge(
                  ValidResult::fail(
                    "func[\{func_index}]: invalid func index \{idx} at instruction \{inst_count}",
                  ),
                )
            }
          None => ()
        }
      @wasm_bytecode.CallIndirect =>
        match inst.type_index {
          Some(idx) =>
            if idx >= func_types.length().reinterpret_as_uint() {
              result.merge(
                ValidResult::fail(
                  "func[\{func_index}]: call_indirect references invalid type index \{idx}",
                ),
              )
            }
          None => ()
        }
      @wasm_bytecode.LocalGet | @wasm_bytecode.LocalSet | @wasm_bytecode.LocalTee =>
        match inst.local_index {
          Some(idx) =>
            tc.check_local_index(idx) catch {
              _ =>
                result.merge(
                  ValidResult::fail(
                    "func[\{func_index}]: invalid local index \{idx} at instruction \{inst_count}",
                  ),
                )
            }
          None => ()
        }
      @wasm_bytecode.GlobalGet | @wasm_bytecode.GlobalSet =>
        match inst.global_index {
          Some(idx) =>
            tc.check_global_index(idx) catch {
              _ =>
                result.merge(
                  ValidResult::fail(
                    "func[\{func_index}]: invalid global index \{idx} at instruction \{inst_count}",
                  ),
                )
            }
          None => ()
        }
      @wasm_bytecode.Br | @wasm_bytecode.BrIf =>
        if inst.label_indices.length() > 0 {
          tc.check_label_index(inst.label_indices[0]) catch {
            _ =>
              result.merge(
                ValidResult::fail(
                  "func[\{func_index}]: invalid label index \{inst.label_indices[0]} at instruction \{inst_count}",
                ),
              )
          }
        }
      @wasm_bytecode.BrTable => {
        for idx in inst.label_indices {
          tc.check_label_index(idx) catch {
            _ =>
              result.merge(
                ValidResult::fail(
                  "func[\{func_index}]: invalid label index \{idx} at instruction \{inst_count}",
                ),
              )
          }
        }
        match inst.default_target {
          Some(d) =>
            tc.check_label_index(d) catch {
              _ =>
                result.merge(
                  ValidResult::fail(
                    "func[\{func_index}]: invalid default label index \{d} at instruction \{inst_count}",
                  ),
                )
            }
          None => ()
        }
      }
      _ => ()
    }

    // Track control flow structure
    match inst.opcode {
      @wasm_bytecode.Block | @wasm_bytecode.Loop | @wasm_bytecode.If => {
        let end_types : Array[@wasm_type.ValType] = match inst.block_type {
          Some(@wasm_type.Value(vt)) => [vt]
          Some(@wasm_type.TypeIndex(idx)) =>
            if idx < func_types.length().reinterpret_as_uint() {
              func_types[idx.reinterpret_as_int()].results
            } else {
              []
            }
          _ => []
        }
        tc.push_frame(inst.opcode, [], end_types)
      }
      @wasm_bytecode.End => {
        let popped = try {
          let f = tc.pop_frame()
          Some(f)
        } catch {
          _ => None
        }
        match popped {
          None =>
            result.merge(
              ValidResult::fail(
                "func[\{func_index}]: unmatched end at instruction \{inst_count}",
              ),
            )
          Some(_) => ()
        }
      }
      @wasm_bytecode.Else => {
        match tc.current_frame() {
          Some(frame) =>
            if frame.opcode != @wasm_bytecode.If {
              result.merge(
                ValidResult::fail(
                  "func[\{func_index}]: else without matching if at instruction \{inst_count}",
                ),
              )
            }
          None =>
            result.merge(
              ValidResult::fail(
                "func[\{func_index}]: else without control frame at instruction \{inst_count}",
              ),
            )
        }
      }
      @wasm_bytecode.Unreachable => tc.mark_unreachable()
      _ => ()
    }

    inst_count = inst_count + 1
  }

  // After processing all instructions, the function's implicit block
  // frame should have been closed by the final 'end' instruction.
  // If control_stack still has frames, the function body is missing
  // end instructions.
  if tc.control_stack.length() > 0 {
    result.merge(
      ValidResult::fail(
        "func[\{func_index}]: \{tc.control_stack.length()} unclosed control frame(s)",
      ),
    )
  }
}
