# Changelog

All notable changes to `moonbit-wasmkit` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-16

### Added
- **`src/binary_reader`**: Low-level endian-aware binary stream reader, LEB128 decoder, signed integer handling, C-string extractor, and binary writer.
- **`src/wasm_type`**: Wasm value types (i32, i64, f32, f64, funcref, externref), function type signatures, block types, memory limits, table types, global types, and mutability.
- **`src/wasm_section`**: All 12 standard section parsers — Type, Import, Function, Table, Memory, Global, Export, Start, Element, Code, Data, and DataCount — with full vector decoding.
- **`src/wasm_bytecode`**: Complete Wasm instruction opcode table, immediate operand decoder, function body parser, and WAT-style text disassembler.
- **`src/wasm_custom`**: Custom section payload wrapper and Name subsection parser (module name, function names, local names).
- **`src/wasm_valid`**: Stack-based module validator with type checking, control-flow verification, label-stack enforcement, and import/export consistency checks.
- **`src/model`**: High-level `WasmModule` facade, module summary, export/import index tables, function signature resolver, Markdown/JSON/text report generators, and module diff analyzer.
- **`src/cli_core`**: CLI argument parser, command dispatcher, batch processor, interactive shell, and multi-format exporter.
- **`src/cli`**: `wasmkit` native command-line executable entrypoint.
- **CI Pipeline**: Cross-platform GitHub Actions matrix for Ubuntu, macOS, and Windows.
