// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "parse_help_flag" {
  let opts = parse_cli_args(["--help"])
  inspect(opts.show_help, content="true")
  inspect(opts.file_path, content="")
}

///|
test "parse_version_flag" {
  let opts = parse_cli_args(["--version"])
  inspect(opts.show_version, content="true")
}

///|
test "parse_file_path" {
  let opts = parse_cli_args(["module.wasm"])
  inspect(opts.file_path, content="module.wasm")
}

///|
test "parse_sections_flag" {
  let opts = parse_cli_args(["--sections", "test.wasm"])
  inspect(opts.show_sections, content="true")
  inspect(opts.file_path, content="test.wasm")
}

///|
test "parse_types_flag" {
  let opts = parse_cli_args(["--types", "test.wasm"])
  inspect(opts.show_types, content="true")
}

///|
test "parse_validate_flag" {
  let opts = parse_cli_args(["--validate", "test.wasm"])
  inspect(opts.do_validate, content="true")
}

///|
test "parse_disassemble" {
  let opts = parse_cli_args(["--disassemble", "3", "test.wasm"])
  match opts.disassemble_func {
    Some(idx) => inspect(idx, content="3")
    None => inspect("missing_idx", content="unexpected")
  }
}

///|
test "parse_format_markdown" {
  let opts = parse_cli_args(["--format", "markdown", "test.wasm"])
  inspect(opts.output_format, content="markdown")
}

///|
test "parse_format_json" {
  let opts = parse_cli_args(["--format", "json", "test.wasm"])
  inspect(opts.output_format, content="json")
}

///|
test "parse_format_equals_syntax" {
  let opts = parse_cli_args(["--format=json", "test.wasm"])
  inspect(opts.output_format, content="json")
}

///|
test "parse_invalid_format" {
  let opts = parse_cli_args(["--format", "xml", "test.wasm"])
  match opts.error {
    Some(msg) => inspect(msg.has_prefix("Unsupported"), content="true")
    None => inspect("no_error", content="unexpected")
  }
}

///|
test "parse_unknown_option" {
  let opts = parse_cli_args(["--unknown", "test.wasm"])
  match opts.error {
    Some(msg) => inspect(msg.has_prefix("Unknown"), content="true")
    None => inspect("no_error", content="unexpected")
  }
}

///|
test "parse_multiple_files_rejected" {
  let opts = parse_cli_args(["a.wasm", "b.wasm"])
  match opts.error {
    Some(msg) =>
      inspect(msg.has_prefix("Multiple"), content="true")
    None => inspect("no_error", content="unexpected")
  }
}

///|
test "parse_process_args_skips_executable" {
  let opts = parse_process_args(["wasmkit", "--validate", "test.wasm"])
  inspect(opts.do_validate, content="true")
  inspect(opts.file_path, content="test.wasm")
}

///|
test "parse_all_inspection_flags" {
  let opts = parse_cli_args([
    "--sections",
    "--types",
    "--imports",
    "--exports",
    "--functions",
    "--globals",
    "--memories",
    "--tables",
    "test.wasm",
  ])
  inspect(opts.show_sections, content="true")
  inspect(opts.show_types, content="true")
  inspect(opts.show_imports, content="true")
  inspect(opts.show_exports, content="true")
  inspect(opts.show_functions, content="true")
  inspect(opts.show_globals, content="true")
  inspect(opts.show_memories, content="true")
  inspect(opts.show_tables, content="true")
}

///|
test "render_summary_text" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = @model.WasmModule::parse("test.wasm", bytes)
  let text = render_analysis_summary(m.summary(), "text")
  inspect(text.has_prefix("Wasm Module:"), content="true")
}

///|
test "render_summary_json" {
  let bytes : Bytes = b"\x00\x61\x73\x6D\x01\x00\x00\x00"
  let m = @model.WasmModule::parse("test.wasm", bytes)
  let json = render_analysis_summary(m.summary(), "json")
  inspect(json.has_prefix("{"), content="true")
}
