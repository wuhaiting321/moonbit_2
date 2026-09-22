// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
fn print_usage() -> Unit {
  println("moonbit-wasmkit v0.1.0 - WebAssembly Binary Analyzer")
  println("Usage: wasmkit [options] <wasm-binary>")
  println("Options:")
  println("  --sections        List Section headers")
  println("  --types           List Type signatures")
  println("  --imports         List Import entries")
  println("  --exports         List Export entries")
  println("  --functions       List Function entries")
  println("  --globals         List Global entries")
  println("  --memories        List Memory entries")
  println("  --tables          List Table entries")
  println("  --data            List Data segments")
  println("  --elements        List Element segments")
  println("  --code            List Code body summaries")
  println("  --disassemble N   Disassemble function N")
  println("  --validate        Validate the module")
  println("  --format FORMAT   Use text, markdown, or json summary output")
  println("  --help            Show this help")
  println("  --version         Show the tool version")
}

///|
fn main {
  let opts = @cli_core.parse_process_args(@env.args())
  if opts.show_version {
    println("moonbit-wasmkit v0.1.0")
    return
  }
  if opts.show_help {
    print_usage()
    return
  }
  match opts.error {
    Some(message) => {
      println("Error: \{message}")
      print_usage()
      return
    }
    None => ()
  }
  if opts.file_path == "" {
    print_usage()
    return
  }

  let bytes = @fs.read_file_to_bytes(opts.file_path) catch {
    _ => {
      println("Error: cannot read Wasm file \{opts.file_path}")
      return
    }
  }
  let wasm_mod = @model.WasmModule::parse(opts.file_path, bytes) catch {
    _ => {
      println("Error: failed to parse Wasm file \{opts.file_path}")
      return
    }
  }

  // Check if any inspection flags are set
  let has_inspection = opts.show_sections ||
    opts.show_types ||
    opts.show_imports ||
    opts.show_exports ||
    opts.show_functions ||
    opts.show_globals ||
    opts.show_memories ||
    opts.show_tables ||
    opts.show_data ||
    opts.show_elements ||
    opts.show_code ||
    opts.disassemble_func is Some(_) ||
    opts.do_validate

  if has_inspection {
    @cli_core.execute_cli_action(opts, wasm_mod)
  } else {
    println(
      @cli_core.render_analysis_summary(
        wasm_mod.summary(),
        opts.output_format,
      ),
    )
  }
}
