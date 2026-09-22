# MoonBit 9 月黑客松项目申报书

## 一、项目基本信息

| 申报项 | 内容 |
| :--- | :--- |
| **项目名称** | `moonbit-wasmkit`（WebAssembly 二进制分析与验证工具包） |
| **项目标识** | `wuhaiting321/wasmkit`（包命名空间：`wuhaiting321/wasmkit`） |
| **申报人 / 唯一贡献者** | `wuhaiting321`（GitHub：[wuhaiting321](https://github.com/wuhaiting321)） |
| **项目开源地址** | https://github.com/wuhaiting321/moonbit_2 |
| **开发语言** | MoonBit（100% 纯 MoonBit 实现，零 C/C++ FFI 绑定） |
| **开源许可证** | Apache License 2.0 |

## 二、项目简介与立项背景

WebAssembly 模块在部署到浏览器、边缘运行时或嵌入式沙箱前，通常需要进行二进制格式解析、结构验证和静态检查。现有工具多依赖 C/C++ 运行时或绑定外部库，难以直接集成到 MoonBit 生态中。

`moonbit-wasmkit` 是一个纯 MoonBit 实现的 WebAssembly 二进制分析工具包，提供从底层字节流读取、全部标准节解析、指令反汇编到模块级验证的完整管线，并附带原生命令行工具用于模块检查。项目可作为 MoonBit 生态中 Wasm 工具链、IDE 插件或沙箱预验证组件的基础库使用。

## 三、项目方向与适用场景

- **方向**：MoonBit 基础生态库 / WebAssembly 工具链
- **适用场景**：
  - Wasm 模块静态分析与结构检查
  - Wasm 沙箱运行时的部署前预验证
  - IDE 插件中的 Wasm 调试辅助（函数名查找、反汇编输出）
  - 编译器工具链中的模块差异比对与报告生成

## 四、核心功能实现

1. **二进制流读写器**（`src/binary_reader`）：边界检查的字节读取器，支持大/小端序、LEB128 编码、UTF-8 名称读取，以及二进制写入器。
2. **Wasm 类型系统**（`src/wasm_type`）：值类型（i32/i64/f32/f64/funcref/externref）、函数签名、块类型、内存限制、表类型、全局类型。
3. **标准节解析器**（`src/wasm_section`）：覆盖全部 12 种标准节（Type、Import、Function、Table、Memory、Global、Export、Start、Element、Code、Data、DataCount），含完整向量解码。
4. **指令解码与反汇编**（`src/wasm_bytecode`）：覆盖 Wasm MVP 170+ 条指令操作码表、立即数解码器、WAT 格式文本反汇编器，支持扩展 load/store 指令。
5. **自定义节与名称节**（`src/wasm_custom`）：Custom section 载荷封装，Name 子节解析（模块名、函数名、局部变量名），支持按索引查找。
6. **模块验证器**（`src/wasm_valid`）：结构性校验（类型索引合法性、函数/代码节数量匹配、内存/表数量 MVP 限制、导出名唯一性、启动函数范围检查）和函数体验证（指令解码、索引范围检查、控制流结构匹配）。
7. **高层分析接口**（`src/model`）：`WasmModule` 封装解析全流程，提供节摘要、导出/导入表、函数签名查询、Text/Markdown/JSON 报告导出和双模块差异比对。
8. **命令行工具**（`src/cli_core` + `src/cli`）：原生命令行入口，支持 `--sections`、`--types`、`--imports`、`--exports`、`--functions`、`--globals`、`--memories`、`--tables`、`--data`、`--elements`、`--code`、`--disassemble`、`--validate`、`--format` 等检查选项。

## 五、原创性说明

本项目为**完全自主原创**的 MoonBit 项目。项目参考了 WebAssembly 官方规范（[WebAssembly Specification](https://webassembly.github.io/spec/)）中公开的二进制格式定义和指令编码表，所有代码均由申报人使用纯 MoonBit 语言独立编写，未移植、复制或依赖任何第三方开源代码。

## 六、交付成果与质量指标

| 指标 | 数据 |
| :--- | :--- |
| **源码规模** | 32 个 `.mbt` 文件，共 6,074 行（非测试 4,572 行 + 测试 1,502 行） |
| **模块化包数** | 9 个子包 |
| **自动化测试** | 141 项单元与集成测试，通过率 100% |
| **质量门禁** | `moon check --deny-warn` 零警告零错误 |
| **跨平台 CI** | GitHub Actions 矩阵覆盖 Ubuntu、macOS、Windows |
| **有效提交** | 14 次原子化提交，唯一贡献者 `wuhaiting321` |

## 七、验收复现命令

```bash
moon version --all
moon fmt --check
moon check --deny-warn
moon check --target all --deny-warn
moon test --deny-warn
moon info
git diff --exit-code
```
