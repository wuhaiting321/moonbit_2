// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "parse_minimal_wasm_module" {
  // Minimal valid Wasm: magic + version, no sections
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let wasm = parse_wasm_binary(bytes)
  inspect(wasm.version, content="1")
  inspect(wasm.sections.length(), content="0")
}

///|
test "parse_invalid_magic_rejected" {
  let rejected = try {
    let _ = parse_wasm_binary(b"\x00\x00\x00\x00\x01\x00\x00\x00")
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "parse_invalid_version_rejected" {
  let rejected = try {
    let _ = parse_wasm_binary(b"\x00\x61\x73\x6D\x02\x00\x00\x00")
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "parse_type_section" {
  // Type section: 1 func type () -> ()
  // Section ID=1, size=4, payload: count=1, tag=0x60, params=0, results=0
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x01\x04\x01\x60\x00\x00"
  let wasm = parse_wasm_binary(bytes)
  inspect(wasm.sections.length(), content="1")
  match wasm.find_section(Type) {
    Some(sec) => {
      let types = parse_type_section(sec.payload)
      inspect(types.length(), content="1")
      inspect(types[0].params.length(), content="0")
      inspect(types[0].results.length(), content="0")
    }
    None => inspect("missing_type", content="unexpected")
  }
}

///|
test "parse_type_section_with_signature" {
  // func (i32, i32) -> (i32)
  // payload: count=1, 0x60, 2 params (i32 i32), 1 result (i32)
  let payload : Bytes = b"\x01\x60\x02\x7F\x7F\x01\x7F"
  let types = parse_type_section(payload)
  inspect(types.length(), content="1")
  inspect(types[0].to_string(), content="(func (param i32 i32) (result i32))")
}

///|
test "parse_function_section" {
  // 2 functions referencing type indices 0 and 1
  let payload : Bytes = b"\x02\x00\x01"
  let indices = parse_function_section(payload)
  inspect(indices.length(), content="2")
  inspect(indices[0], content="0")
  inspect(indices[1], content="1")
}

///|
test "parse_import_section_empty" {
  let payload : Bytes = b"\x00"
  let imports = parse_import_section(payload)
  inspect(imports.length(), content="0")
}

///|
test "parse_import_func" {
  // 1 import: module="env", name="log", kind=func, typeidx=0
  let payload : Bytes = b"\x01\x03env\x03log\x00\x00"
  let imports = parse_import_section(payload)
  inspect(imports.length(), content="1")
  inspect(imports[0].mod_name, content="env")
  inspect(imports[0].name, content="log")
}

///|
test "parse_export_section" {
  // 1 export: name="main", kind=func, index=0
  let payload : Bytes = b"\x01\x04main\x00\x00"
  let exports = parse_export_section(payload)
  inspect(exports.length(), content="1")
  inspect(exports[0].name, content="main")
  match exports[0].kind {
    FuncExport => inspect(true, content="true")
    _ => inspect("wrong_kind", content="unexpected")
  }
  inspect(exports[0].index, content="0")
}

///|
test "parse_export_to_string" {
  let ex : Export = {
    name: "add",
    kind: FuncExport,
    index: 2,
  }
  inspect(ex.to_string(), content="(export \"add\" (func 2))")
}

///|
test "parse_memory_section" {
  // 1 memory with min=1, no max
  let payload : Bytes = b"\x01\x00\x01"
  let memories = parse_memory_section(payload)
  inspect(memories.length(), content="1")
  inspect(memories[0].mem_type.limits.min, content="1")
  match memories[0].mem_type.limits.max {
    Some(_) => inspect("has_max", content="unexpected")
    None => inspect(true, content="true")
  }
}

///|
test "parse_start_section" {
  let payload : Bytes = b"\x05"
  let idx = parse_start_section(payload)
  inspect(idx, content="5")
}

///|
test "parse_datacount_section" {
  let payload : Bytes = b"\x03"
  let count = parse_datacount_section(payload)
  inspect(count, content="3")
}

///|
test "section_id_roundtrip" {
  let ids : Array[SectionId] = [Custom, Type, Import, Function, Table, Memory, Global, Export, Start, Element, Code, Data, DataCount]
  for id in ids {
    let byte = id.to_id()
    let parsed = parse_section_id(byte)
    inspect(parsed.to_string(), content=id.to_string())
  }
}

///|
test "find_section_returns_none_when_missing" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let wasm = parse_wasm_binary(bytes)
  match wasm.find_section(Type) {
    Some(_) => inspect("found", content="unexpected")
    None => inspect(true, content="true")
  }
}

///|
test "custom_sections_collected" {
  // Module with one custom section (id=0, size=3, name="a", payload=0x01 0x02)
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x00\x03\x01\x61\xFF"
  let wasm = parse_wasm_binary(bytes)
  let customs = wasm.custom_sections()
  inspect(customs.length(), content="1")
}
