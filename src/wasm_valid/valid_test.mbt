// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "validate_empty_module" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let binary = @wasm_section.parse_wasm_binary(bytes)
  let result = validate_module(binary)
  inspect(result.is_valid, content="true")
  inspect(result.errors.length(), content="0")
}

///|
test "validate_module_with_types" {
  // Module with type section: 1 func type () -> ()
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x01\x04\x01\x60\x00\x00"
  let binary = @wasm_section.parse_wasm_binary(bytes)
  let result = validate_module(binary)
  inspect(result.is_valid, content="true")
}

///|
test "validate_type_index_out_of_range" {
  // Function section referencing type index 5 when only 1 type exists
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x01\x04\x01\x60\x00\x00\x03\x02\x01\x05"
  let binary = @wasm_section.parse_wasm_binary(bytes)
  let result = validate_module(binary)
  inspect(result.is_valid, content="false")
}

///|
test "validate_function_code_count_mismatch" {
  // Function section: 2 funcs, but no code section
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00\x01\x04\x01\x60\x00\x00\x03\x03\x02\x00\x00"
  let binary = @wasm_section.parse_wasm_binary(bytes)
  let result = validate_module(binary)
  inspect(result.is_valid, content="false")
}

///|
test "validate_duplicate_exports" {
  let export_payload : Bytes = b"\x02\x03foo\x00\x00\x03foo\x00\x01"
  let exports = @wasm_section.parse_export_section(export_payload)
  let result = ValidResult::ok()
  validate_export_names(exports, result)
  inspect(result.is_valid, content="false")
  inspect(result.errors.length(), content="1")
}

///|
test "validate_unique_exports_ok" {
  let export_payload : Bytes = b"\x02\x03foo\x00\x00\x03bar\x00\x01"
  let exports = @wasm_section.parse_export_section(export_payload)
  let result = ValidResult::ok()
  validate_export_names(exports, result)
  inspect(result.is_valid, content="true")
}

///|
test "type_checker_push_pop" {
  let tc = TypeChecker::new([], [@wasm_type.I32], 0, 0, 0, 0, 0)
  tc.push(Known(@wasm_type.I32))
  let val = tc.pop()
  match val {
    Known(@wasm_type.I32) => inspect(true, content="true")
    _ => inspect("wrong_type", content="unexpected")
  }
}

///|
test "type_checker_pop_expect_match" {
  let tc = TypeChecker::new([], [], 0, 0, 0, 0, 0)
  tc.push(Known(@wasm_type.I64))
  let matched = try {
    tc.pop_expect(@wasm_type.I64, 0)
    true
  } catch {
    _ => false
  } noraise {
    _ => false
  }
  inspect(matched, content="true")
}

///|
test "type_checker_pop_expect_mismatch" {
  let tc = TypeChecker::new([], [], 0, 0, 0, 0, 0)
  tc.push(Known(@wasm_type.I32))
  let rejected = try {
    tc.pop_expect(@wasm_type.I64, 0)
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "valid_result_merge" {
  let r1 = ValidResult::ok()
  let r2 = ValidResult::fail("test error")
  r1.merge(r2)
  inspect(r1.is_valid, content="false")
  inspect(r1.errors.length(), content="1")
}
