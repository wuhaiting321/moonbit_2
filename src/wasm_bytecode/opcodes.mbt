// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Wasm instruction opcodes
pub(all) enum Opcode {
  // Control instructions
  Unreachable
  Nop
  Block
  Loop
  If
  Else
  End
  Br
  BrIf
  BrTable
  Return
  Call
  CallIndirect
  // Parametric instructions
  Drop
  Select
  // Variable instructions
  LocalGet
  LocalSet
  LocalTee
  GlobalGet
  GlobalSet
  // Memory instructions
  I32Load
  I64Load
  F32Load
  F64Load
  I32Store
  I64Store
  F32Store
  F64Store
  MemorySize
  MemoryGrow
  // Numeric constants
  I32Const
  I64Const
  F32Const
  F64Const
  // Numeric i32 operations
  I32Eqz
  I32Eq
  I32Ne
  I32LtS
  I32LtU
  I32GtS
  I32GtU
  I32LeS
  I32LeU
  I32GeS
  I32GeU
  I32Clz
  I32Ctz
  I32Popcnt
  I32Add
  I32Sub
  I32Mul
  I32DivS
  I32DivU
  I32RemS
  I32RemU
  I32And
  I32Or
  I32Xor
  I32Shl
  I32ShrS
  I32ShrU
  I32Rotl
  I32Rotr
  // Numeric i64 operations
  I64Eqz
  I64Eq
  I64Ne
  I64LtS
  I64LtU
  I64GtS
  I64GtU
  I64LeS
  I64LeU
  I64GeS
  I64GeU
  I64Clz
  I64Ctz
  I64Popcnt
  I64Add
  I64Sub
  I64Mul
  I64DivS
  I64DivU
  I64RemS
  I64RemU
  I64And
  I64Or
  I64Xor
  I64Shl
  I64ShrS
  I64ShrU
  I64Rotl
  I64Rotr
  // Float operations
  F32Abs
  F32Neg
  F32Ceil
  F32Floor
  F32Trunc
  F32Nearest
  F32Sqrt
  F32Add
  F32Sub
  F32Mul
  F32Div
  F32Min
  F32Max
  F32Copysign
  F64Abs
  F64Neg
  F64Ceil
  F64Floor
  F64Trunc
  F64Nearest
  F64Sqrt
  F64Add
  F64Sub
  F64Mul
  F64Div
  F64Min
  F64Max
  F64Copysign
  // Conversions
  I32WrapI64
  I32TruncF32S
  I32TruncF32U
  I32TruncF64S
  I32TruncF64U
  I64ExtendI32S
  I64ExtendI32U
  I64TruncF32S
  I64TruncF32U
  I64TruncF64S
  I64TruncF64U
  F32ConvertI32S
  F32ConvertI32U
  F32ConvertI64S
  F32ConvertI64U
  F32DemoteF64
  F64ConvertI32S
  F64ConvertI32U
  F64ConvertI64S
  F64ConvertI64U
  F64PromoteF32
  I32ReinterpretF32
  I64ReinterpretF64
  F32ReinterpretI32
  F64ReinterpretI64
  // Extended loads
  I32Load8S
  I32Load8U
  I32Load16S
  I32Load16U
  I64Load8S
  I64Load8U
  I64Load16S
  I64Load16U
  I64Load32S
  I64Load32U
  I32Store8
  I32Store16
  I64Store8
  I64Store16
  I64Store32
  Unknown(Byte)
} derive(Debug, Eq)

///|
/// Display opcode mnemonic
pub fn Opcode::to_string(self : Opcode) -> String {
  match self {
    Unreachable => "unreachable"
    Nop => "nop"
    Block => "block"
    Loop => "loop"
    If => "if"
    Else => "else"
    End => "end"
    Br => "br"
    BrIf => "br_if"
    BrTable => "br_table"
    Return => "return"
    Call => "call"
    CallIndirect => "call_indirect"
    Drop => "drop"
    Select => "select"
    LocalGet => "local.get"
    LocalSet => "local.set"
    LocalTee => "local.tee"
    GlobalGet => "global.get"
    GlobalSet => "global.set"
    I32Load => "i32.load"
    I64Load => "i64.load"
    F32Load => "f32.load"
    F64Load => "f64.load"
    I32Store => "i32.store"
    I64Store => "i64.store"
    F32Store => "f32.store"
    F64Store => "f64.store"
    MemorySize => "memory.size"
    MemoryGrow => "memory.grow"
    I32Const => "i32.const"
    I64Const => "i64.const"
    F32Const => "f32.const"
    F64Const => "f64.const"
    I32Eqz => "i32.eqz"
    I32Eq => "i32.eq"
    I32Ne => "i32.ne"
    I32LtS => "i32.lt_s"
    I32LtU => "i32.lt_u"
    I32GtS => "i32.gt_s"
    I32GtU => "i32.gt_u"
    I32LeS => "i32.le_s"
    I32LeU => "i32.le_u"
    I32GeS => "i32.ge_s"
    I32GeU => "i32.ge_u"
    I32Clz => "i32.clz"
    I32Ctz => "i32.ctz"
    I32Popcnt => "i32.popcnt"
    I32Add => "i32.add"
    I32Sub => "i32.sub"
    I32Mul => "i32.mul"
    I32DivS => "i32.div_s"
    I32DivU => "i32.div_u"
    I32RemS => "i32.rem_s"
    I32RemU => "i32.rem_u"
    I32And => "i32.and"
    I32Or => "i32.or"
    I32Xor => "i32.xor"
    I32Shl => "i32.shl"
    I32ShrS => "i32.shr_s"
    I32ShrU => "i32.shr_u"
    I32Rotl => "i32.rotl"
    I32Rotr => "i32.rotr"
    I64Eqz => "i64.eqz"
    I64Eq => "i64.eq"
    I64Ne => "i64.ne"
    I64LtS => "i64.lt_s"
    I64LtU => "i64.lt_u"
    I64GtS => "i64.gt_s"
    I64GtU => "i64.gt_u"
    I64LeS => "i64.le_s"
    I64LeU => "i64.le_u"
    I64GeS => "i64.ge_s"
    I64GeU => "i64.ge_u"
    I64Clz => "i64.clz"
    I64Ctz => "i64.ctz"
    I64Popcnt => "i64.popcnt"
    I64Add => "i64.add"
    I64Sub => "i64.sub"
    I64Mul => "i64.mul"
    I64DivS => "i64.div_s"
    I64DivU => "i64.div_u"
    I64RemS => "i64.rem_s"
    I64RemU => "i64.rem_u"
    I64And => "i64.and"
    I64Or => "i64.or"
    I64Xor => "i64.xor"
    I64Shl => "i64.shl"
    I64ShrS => "i64.shr_s"
    I64ShrU => "i64.shr_u"
    I64Rotl => "i64.rotl"
    I64Rotr => "i64.rotr"
    F32Abs => "f32.abs"
    F32Neg => "f32.neg"
    F32Ceil => "f32.ceil"
    F32Floor => "f32.floor"
    F32Trunc => "f32.trunc"
    F32Nearest => "f32.nearest"
    F32Sqrt => "f32.sqrt"
    F32Add => "f32.add"
    F32Sub => "f32.sub"
    F32Mul => "f32.mul"
    F32Div => "f32.div"
    F32Min => "f32.min"
    F32Max => "f32.max"
    F32Copysign => "f32.copysign"
    F64Abs => "f64.abs"
    F64Neg => "f64.neg"
    F64Ceil => "f64.ceil"
    F64Floor => "f64.floor"
    F64Trunc => "f64.trunc"
    F64Nearest => "f64.nearest"
    F64Sqrt => "f64.sqrt"
    F64Add => "f64.add"
    F64Sub => "f64.sub"
    F64Mul => "f64.mul"
    F64Div => "f64.div"
    F64Min => "f64.min"
    F64Max => "f64.max"
    F64Copysign => "f64.copysign"
    I32WrapI64 => "i32.wrap_i64"
    I32TruncF32S => "i32.trunc_f32_s"
    I32TruncF32U => "i32.trunc_f32_u"
    I32TruncF64S => "i32.trunc_f64_s"
    I32TruncF64U => "i32.trunc_f64_u"
    I64ExtendI32S => "i64.extend_i32_s"
    I64ExtendI32U => "i64.extend_i32_u"
    I64TruncF32S => "i64.trunc_f32_s"
    I64TruncF32U => "i64.trunc_f32_u"
    I64TruncF64S => "i64.trunc_f64_s"
    I64TruncF64U => "i64.trunc_f64_u"
    F32ConvertI32S => "f32.convert_i32_s"
    F32ConvertI32U => "f32.convert_i32_u"
    F32ConvertI64S => "f32.convert_i64_s"
    F32ConvertI64U => "f32.convert_i64_u"
    F32DemoteF64 => "f32.demote_f64"
    F64ConvertI32S => "f64.convert_i32_s"
    F64ConvertI32U => "f64.convert_i32_u"
    F64ConvertI64S => "f64.convert_i64_s"
    F64ConvertI64U => "f64.convert_i64_u"
    F64PromoteF32 => "f64.promote_f32"
    I32ReinterpretF32 => "i32.reinterpret_f32"
    I64ReinterpretF64 => "i64.reinterpret_f64"
    F32ReinterpretI32 => "f32.reinterpret_i32"
    F64ReinterpretI64 => "f64.reinterpret_i64"
    I32Load8S => "i32.load8_s"
    I32Load8U => "i32.load8_u"
    I32Load16S => "i32.load16_s"
    I32Load16U => "i32.load16_u"
    I64Load8S => "i64.load8_s"
    I64Load8U => "i64.load8_u"
    I64Load16S => "i64.load16_s"
    I64Load16U => "i64.load16_u"
    I64Load32S => "i64.load32_s"
    I64Load32U => "i64.load32_u"
    I32Store8 => "i32.store8"
    I32Store16 => "i32.store16"
    I64Store8 => "i64.store8"
    I64Store16 => "i64.store16"
    I64Store32 => "i64.store32"
    Unknown(b) => "unknown_0x\{b}"
  }
}
