# moonbit-wasmkit

[![CI](https://github.com/wuhaiting321/moonbit-wasmkit/actions/workflows/ci.yml/badge.svg)](https://github.com/wuhaiting321/moonbit-wasmkit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

`moonbit-wasmkit` is a pure-MoonBit WebAssembly binary analysis library
with a native command-line entrypoint. It is designed for toolchains, IDE
plugins, and sandbox runtimes that need to parse, disassemble, validate,
and inspect `.wasm` modules without binding to a C runtime.

## What it provides

- Complete Wasm binary format parsing: magic number, version, and all
  standard section types (Type, Import, Function, Table, Memory, Global,
  Export, Start, Element, Code, Data, DataCount).
- Instruction bytecode decoder covering numeric, variable, memory, control,
  parametric, and reference instructions with immediate operands.
- Custom section and Name subsection decoder for debugging metadata.
- Stack-based module validator with type checking, control-flow verification,
  and label-stack discipline enforcement.
- High-level `WasmModule` analysis facade with section summaries,
  export/import tables, function signature indexes, and Markdown/JSON reports.
- A native `wasmkit` CLI for module inspection, disassembly, validation,
  and multi-format report export.

The core parser and validator are implemented in MoonBit. The native CLI uses
`moonbitlang/x/fs` only for reading the input file.

## Package layout

| Package | Purpose |
| --- | --- |
| `src/binary_reader` | Bounds-checked byte, endian, string, and LEB128 readers and writers |
| `src/wasm_type` | Wasm value types, function signatures, limits, and block types |
| `src/wasm_section` | All standard section parsers: Type, Import, Function, Table, Memory, Global, Export, Start, Element, Code, Data, DataCount |
| `src/wasm_bytecode` | Instruction opcodes, immediate decoder, and text disassembler |
| `src/wasm_custom` | Custom section payload decoder and Name subsection parser |
| `src/wasm_valid` | Type checker, control-flow validator, and module verifier |
| `src/model` | `WasmModule`, section summaries, export/import tables, reports, and diffs |
| `src/cli_core` | Testable CLI argument parsing, command dispatch, and rendering logic |
| `src/cli` | Native executable entrypoint |

## Requirements

- MoonBit stable toolchain. The local verification record was produced with
  MoonBit `0.1.20260916` and compiler `v0.10.9+6e6c44045`.
- A native C toolchain when building the native CLI or running native tests.

## Library usage

Add the module as a dependency in your MoonBit project and import the package
you need:

    import {
      "wuhaiting321/wasmkit/src/model",
    }

    fn analyze(bytes : Bytes) -> String raise {
      let module = @model.WasmModule::parse("module.wasm", bytes)
      let summary = module.summary()
      summary.to_markdown()
    }

`WasmModule::parse` accepts bytes so callers can obtain them from
their own filesystem, embedded-resource, or network layer. Parsing failures
use MoonBit's checked-error mechanism.

## Command-line usage

The executable is native because file access is platform-specific:

    moon run src/cli --target native -- --help
    moon run src/cli --target native -- --format text module.wasm
    moon run src/cli --target native -- --format markdown module.wasm
    moon run src/cli --target native -- --format json module.wasm
    moon run src/cli --target native -- --sections --types --imports module.wasm
    moon run src/cli --target native -- --disassemble 0 module.wasm
    moon run src/cli --target native -- --validate module.wasm

Supported options include `--help`, `--version`,
`--sections`, `--types`, `--imports`, `--exports`,
`--functions`, `--globals`, `--memories`, `--tables`,
`--disassemble FUNC_INDEX`, `--validate`,
`--format text|markdown|json`. Invalid options and multiple input paths
are reported before file parsing.

## Benchmark

Run the deterministic native parser benchmark locally:

    moon run benchmarks --target native --release

The benchmark reports iteration count, successful operations, input size,
elapsed milliseconds, and operations per second for both parsing and a
validation workload. These are deterministic small workloads and should not
be generalized to large modules. The recorded local result and environment
details are in [docs/benchmarks/2026-09-16-native.md](docs/benchmarks/2026-09-16-native.md).

## Development

Run the same core checks locally:

    moon fmt --check
    moon check --deny-warn
    moon check --target all
    moon test --deny-warn
    moon test --target native --deny-warn
    moon info
    moon build --release --target native

`moon info` regenerates the package interface summaries. Review any
`pkg.generated.mbti` change as a public-API change; do not edit
generated files by hand.

GitHub Actions runs the formatting, deny-warn, cross-target check, native
tests, coverage summary, interface-diff, and native release-build gates on
pushes and pull requests.

## License

Copyright 2026 wuhaiting321. This project is distributed under the
[Apache License 2.0](LICENSE).

---

## 中文说明

`moonbit-wasmkit` 是一个纯 MoonBit 实现的 WebAssembly 二进制分析与验证工具
包，并提供原生命令行入口，适用于工具链、IDE 插件和沙箱运行时中对 `.wasm`
模块的解析、反汇编、验证和检查。

项目包含边界检查的二进制读取器、Wasm 类型系统解码器、标准节解析器、字节码
反汇编器、自定义节解码器、模块验证器，以及面向使用者的 `WasmModule` 摘要、
导出/导入表索引、差异分析和 Markdown/JSON 报告接口。原生 CLI 负责读取文件，
核心解析器与验证器仍由 MoonBit 实现。

常用命令：

    moon run src/cli --target native -- --help
    moon run src/cli --target native -- --format json module.wasm
    moon run src/cli --target native -- --validate module.wasm
    moon fmt --check
    moon check --deny-warn
    moon test --target native --deny-warn

许可证为 Apache License 2.0，详见 [LICENSE](LICENSE)。
