// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "parse_minimal_module" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  inspect(m.binary.version, content="1")
  inspect(m.func_types.length(), content="0")
  inspect(m.imports.length(), content="0")
  inspect(m.exports.length(), content="0")
  inspect(m.total_functions(), content="0")
}

///|
test "summary_text_output" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  let summary = m.summary()
  let text = summary.to_text()
  inspect(text.has_prefix("Wasm Module:"), content="true")
}

///|
test "summary_markdown_output" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  let summary = m.summary()
  let md = summary.to_markdown()
  inspect(md.has_prefix("# Wasm Module Report:"), content="true")
}

///|
test "summary_json_output" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  let summary = m.summary()
  let json = summary.to_json()
  inspect(json.has_prefix("{"), content="true")
}

///|
test "json_escape_special_chars" {
  inspect(json_escape("hello\"world"), content="hello\\\"world")
  inspect(json_escape("line\nbreak"), content="line\\nbreak")
  inspect(json_escape("tab\there"), content="tab\\there")
}

///|
test "find_export_by_name" {
  let export_payload : Bytes = b"\x02\x03foo\x00\x00\x03bar\x00\x01"
  let exports = @wasm_section.parse_export_section(export_payload)
  let mut found_foo = false
  let mut i = 0
  while i < exports.length() {
    if exports[i].name == "foo" {
      found_foo = true
    }
    i = i + 1
  }
  inspect(found_foo, content="true")
}

///|
test "validate_empty_module" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  let result = m.validate()
  inspect(result.is_valid, content="true")
}

///|
test "total_functions_with_imports" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x01\x04\x01\x60\x00\x00\x02\x0B\x01\x03env\x03log\x00\x00"
  let m = WasmModule::parse("test.wasm", bytes)
  inspect(m.total_functions(), content="1")
}

///|
test "diff_identical_modules" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let a = WasmModule::parse("a.wasm", bytes)
  let b = WasmModule::parse("b.wasm", bytes)
  let diff = diff_modules(a, b)
  inspect(diff.types_added.length(), content="0")
  inspect(diff.types_removed.length(), content="0")
  inspect(diff.exports_added.length(), content="0")
  inspect(diff.exports_removed.length(), content="0")
  inspect(diff.function_count_delta, content="0")
}

///|
test "diff_modules_added_exports" {
  let bytes_a : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let bytes_b : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x07\x08\x01\x04main\x00\x00"
  let a = WasmModule::parse("a.wasm", bytes_a)
  let b = WasmModule::parse("b.wasm", bytes_b)
  let diff = diff_modules(a, b)
  inspect(diff.exports_added.length(), content="1")
  inspect(diff.exports_added[0].name, content="main")
}
