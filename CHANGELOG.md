# Changelog

All notable changes to `moonbit-wasmkit` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Export section parser now raises an error for invalid export kind bytes instead of silently defaulting to `FuncExport`.
- Element and data section parsers raise `UnsupportedSegmentFlags` for flags >= 3 instead of silently treating unknown encodings as passive segments.
- `WasmModule::get_func_type` and `disassemble_func` now guard against unsigned integer underflow when the function index is within the import range.
- `ModuleSummary.total_bytes` now reports the actual input byte length instead of a hardcoded zero.
- Extended load/store opcodes (0x30-0x3E) are now properly mapped in `decode_opcode`.

### Added
- **Function body validation**: `validate_module` now iterates over code section bodies, decoding instructions and checking function, global, local, and label index ranges, as well as control-flow structure (matched block/end, else-without-if detection, unclosed frame detection).
- **Disassembler extensions**: Added rendering for `f32.const`/`f64.const` bit-pattern immediates, `memory.size`/`memory.grow` mem_index, and all extended load/store instructions (`i32.load8_s` through `i64.store32`).
- **CLI inspection flags**: Added `--data`, `--elements`, and `--code` flags for inspecting data segments, element segments, and code body summaries.

### Tests
- Expanded `BinaryWriter` test coverage: `write_u8`, `write_u16`, `write_u64`, `write_sleb128`, `write_raw`, `patch_u32`, BigEndian roundtrips.
- Added instruction decoder tests for `f32.const`, `f64.const`, `br_table`, `call_indirect`, `memory.size`, `memory.grow`, and extended load/store.
- Added section parser tests for code, element, data, and global sections.
- Added `TypeChecker` tests for frame operations, `mark_unreachable`, and all index validation methods.
- Added integration tests for function body validation (valid and invalid modules).

## [0.1.0] - 2026-09-16

### Added
- **`src/binary_reader`**: Low-level endian-aware binary stream reader, LEB128 decoder, signed integer handling, C-string extractor, and binary writer.
- **`src/wasm_type`**: Wasm value types (i32, i64, f32, f64, funcref, externref), function type signatures, block types, memory limits, table types, global types, and mutability.
- **`src/wasm_section`**: All 12 standard section parsers — Type, Import, Function, Table, Memory, Global, Export, Start, Element, Code, Data, and DataCount — with full vector decoding.
- **`src/wasm_bytecode`**: Complete Wasm instruction opcode table, immediate operand decoder, function body parser, and WAT-style text disassembler.
- **`src/wasm_custom`**: Custom section payload wrapper and Name subsection parser (module name, function names, local names).
- **`src/wasm_valid`**: Stack-based module validator with type checking, control-flow verification, label-stack enforcement, and import/export consistency checks.
- **`src/model`**: High-level `WasmModule` facade, module summary, export/import index tables, function signature resolver, Markdown/JSON/text report generators, and module diff analyzer.
- **`src/cli_core`**: CLI argument parser, command dispatcher, and multi-format exporter.
- **`src/cli`**: `wasmkit` native command-line executable entrypoint.
- **CI Pipeline**: Cross-platform GitHub Actions matrix for Ubuntu, macOS, and Windows.
