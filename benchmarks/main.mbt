// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
fn synthetic_wasm_module() -> Bytes {
  // Minimal valid Wasm module with a type section
  // Magic: \0asm, Version: 1
  // Type section (id=1): 1 func type () -> ()
  Bytes::from_array([
    b'\x00', b'\x61', b'\x73', b'\x6D', b'\x01', b'\x00', b'\x00', b'\x00',
    b'\x01', b'\x04', b'\x01', b'\x60', b'\x00', b'\x00',
  ])
}

///|
fn synthetic_wasm_with_exports() -> Bytes {
  // Module with type, function, export, and code sections
  Bytes::from_array([
    // Magic + version
    b'\x00', b'\x61', b'\x73', b'\x6D', b'\x01', b'\x00', b'\x00', b'\x00',
    // Type section: 1 type () -> ()
    b'\x01', b'\x04', b'\x01', b'\x60', b'\x00', b'\x00',
    // Function section: 1 func with type index 0
    b'\x03', b'\x02', b'\x01', b'\x00',
    // Export section: 1 export "main" -> func 0
    b'\x07', b'\x08', b'\x01', b'\x04', b'm', b'a', b'i', b'n', b'\x00',
    b'\x00',
    // Code section: 1 body, size=2, 0 locals, end
    b'\x0A', b'\x04', b'\x01', b'\x02', b'\x00', b'\x0B',
  ])
}

///|
fn main {
  let iterations = 10000
  let input = synthetic_wasm_module()
  let started = @env.now()
  let mut completed = 0
  let mut i = 0
  while i < iterations {
    let parsed = try {
      let _ = @model.WasmModule::parse("benchmark.wasm", input)
      true
    } catch {
      _ => false
    }
    if parsed {
      completed += 1
    }
    i += 1
  }
  let elapsed_ms = @env.now() - started
  if completed != iterations {
    println("benchmark_failed=true")
    println("completed=\{completed}")
    panic()
  }
  let elapsed_for_rate = if elapsed_ms == 0UL { 1UL } else { elapsed_ms }
  let operations_per_second = completed.to_uint64() * 1000UL / elapsed_for_rate
  println("benchmark=WasmModule.parse")
  println("iterations=\{iterations}")
  println("completed=\{completed}")
  println("input_bytes=\{input.length()}")
  println("elapsed_ms=\{elapsed_ms}")
  println("operations_per_second=\{operations_per_second}")

  // Benchmark 2: parse + validate
  let validate_iterations = 1000
  let validate_input = synthetic_wasm_with_exports()
  let validate_started = @env.now()
  let mut validate_completed = 0
  let mut validate_i = 0
  while validate_i < validate_iterations {
    let result = try {
      let m = @model.WasmModule::parse("benchmark.wasm", validate_input)
      let vr = m.validate()
      vr.is_valid
    } catch {
      _ => false
    }
    if result {
      validate_completed += 1
    }
    validate_i += 1
  }
  let validate_elapsed = @env.now() - validate_started
  if validate_completed != validate_iterations {
    println("validate_benchmark_failed=true")
    println("validate_completed=\{validate_completed}")
    panic()
  }
  let validate_elapsed_for_rate = if validate_elapsed == 0UL {
    1UL
  } else {
    validate_elapsed
  }
  let validate_ops_per_sec = validate_completed.to_uint64() *
    1000UL /
    validate_elapsed_for_rate
  println("benchmark=WasmModule.parse_and_validate")
  println("iterations=\{validate_iterations}")
  println("completed=\{validate_completed}")
  println("input_bytes=\{validate_input.length()}")
  println("elapsed_ms=\{validate_elapsed}")
  println("operations_per_second=\{validate_ops_per_sec}")
}
