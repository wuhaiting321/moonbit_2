// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Memory access immediate (alignment + offset)
pub(all) struct MemArg {
  align : UInt
  offset : UInt
} derive(Debug, Eq)

///|
/// Parsed instruction with opcode and immediates
pub(all) struct Instruction {
  opcode : Opcode
  mut block_type : @wasm_type.BlockType?
  mut label_indices : Array[UInt]
  mut default_target : UInt?
  mut func_index : UInt?
  mut type_index : UInt?
  mut local_index : UInt?
  mut global_index : UInt?
  mut mem_arg : MemArg?
  mut mem_index : UInt?
  mut i32_imm : Int?
  mut i64_imm : Int64?
  mut f32_imm : UInt?
  mut f64_imm : UInt64?
  offset : Int
} derive(Debug)

///|
/// Decode an opcode byte into an Opcode enum
pub fn decode_opcode(code : Byte) -> Opcode {
  match code {
    b'\x00' => Unreachable
    b'\x01' => Nop
    b'\x02' => Block
    b'\x03' => Loop
    b'\x04' => If
    b'\x05' => Else
    b'\x0B' => End
    b'\x0C' => Br
    b'\x0D' => BrIf
    b'\x0E' => BrTable
    b'\x0F' => Return
    b'\x10' => Call
    b'\x11' => CallIndirect
    b'\x1A' => Drop
    b'\x1B' => Select
    b'\x20' => LocalGet
    b'\x21' => LocalSet
    b'\x22' => LocalTee
    b'\x23' => GlobalGet
    b'\x24' => GlobalSet
    b'\x28' => I32Load
    b'\x29' => I64Load
    b'\x2A' => F32Load
    b'\x2B' => F64Load
    b'\x2C' => I32Store
    b'\x2D' => I64Store
    b'\x2E' => F32Store
    b'\x2F' => F64Store
    b'\x3F' => MemorySize
    b'\x40' => MemoryGrow
    b'\x41' => I32Const
    b'\x42' => I64Const
    b'\x43' => F32Const
    b'\x44' => F64Const
    b'\x45' => I32Eqz
    b'\x46' => I32Eq
    b'\x47' => I32Ne
    b'\x48' => I32LtS
    b'\x49' => I32LtU
    b'\x4A' => I32GtS
    b'\x4B' => I32GtU
    b'\x4C' => I32LeS
    b'\x4D' => I32LeU
    b'\x4E' => I32GeS
    b'\x4F' => I32GeU
    b'\x50' => I64Eqz
    b'\x51' => I64Eq
    b'\x52' => I64Ne
    b'\x53' => I64LtS
    b'\x54' => I64LtU
    b'\x55' => I64GtS
    b'\x56' => I64GtU
    b'\x57' => I64LeS
    b'\x58' => I64LeU
    b'\x59' => I64GeS
    b'\x5A' => I64GeU
    b'\x67' => I32Clz
    b'\x68' => I32Ctz
    b'\x69' => I32Popcnt
    b'\x6A' => I32Add
    b'\x6B' => I32Sub
    b'\x6C' => I32Mul
    b'\x6D' => I32DivS
    b'\x6E' => I32DivU
    b'\x6F' => I32RemS
    b'\x70' => I32RemU
    b'\x71' => I32And
    b'\x72' => I32Or
    b'\x73' => I32Xor
    b'\x74' => I32Shl
    b'\x75' => I32ShrS
    b'\x76' => I32ShrU
    b'\x77' => I32Rotl
    b'\x78' => I32Rotr
    b'\x79' => I64Clz
    b'\x7A' => I64Ctz
    b'\x7B' => I64Popcnt
    b'\x7C' => I64Add
    b'\x7D' => I64Sub
    b'\x7E' => I64Mul
    b'\x7F' => I64DivS
    b'\x80' => I64DivU
    b'\x81' => I64RemS
    b'\x82' => I64RemU
    b'\x83' => I64And
    b'\x84' => I64Or
    b'\x85' => I64Xor
    b'\x86' => I64Shl
    b'\x87' => I64ShrS
    b'\x88' => I64ShrU
    b'\x89' => I64Rotl
    b'\x8A' => I64Rotr
    b'\x8B' => F32Abs
    b'\x8C' => F32Neg
    b'\x8D' => F32Ceil
    b'\x8E' => F32Floor
    b'\x8F' => F32Trunc
    b'\x90' => F32Nearest
    b'\x91' => F32Sqrt
    b'\x92' => F32Add
    b'\x93' => F32Sub
    b'\x94' => F32Mul
    b'\x95' => F32Div
    b'\x96' => F32Min
    b'\x97' => F32Max
    b'\x98' => F32Copysign
    b'\x99' => F64Abs
    b'\x9A' => F64Neg
    b'\x9B' => F64Ceil
    b'\x9C' => F64Floor
    b'\x9D' => F64Trunc
    b'\x9E' => F64Nearest
    b'\x9F' => F64Sqrt
    b'\xA0' => F64Add
    b'\xA1' => F64Sub
    b'\xA2' => F64Mul
    b'\xA3' => F64Div
    b'\xA4' => F64Min
    b'\xA5' => F64Max
    b'\xA6' => F64Copysign
    b'\xA7' => I32WrapI64
    b'\xA8' => I32TruncF32S
    b'\xA9' => I32TruncF32U
    b'\xAA' => I32TruncF64S
    b'\xAB' => I32TruncF64U
    b'\xAC' => I64ExtendI32S
    b'\xAD' => I64ExtendI32U
    b'\xAE' => I64TruncF32S
    b'\xAF' => I64TruncF32U
    b'\xB0' => I64TruncF64S
    b'\xB1' => I64TruncF64U
    b'\xB2' => F32ConvertI32S
    b'\xB3' => F32ConvertI32U
    b'\xB4' => F32ConvertI64S
    b'\xB5' => F32ConvertI64U
    b'\xB6' => F32DemoteF64
    b'\xB7' => F64ConvertI32S
    b'\xB8' => F64ConvertI32U
    b'\xB9' => F64ConvertI64S
    b'\xBA' => F64ConvertI64U
    b'\xBB' => F64PromoteF32
    b'\xBC' => I32ReinterpretF32
    b'\xBD' => I64ReinterpretF64
    b'\xBE' => F32ReinterpretI32
    b'\xBF' => F64ReinterpretI64
    _ => Unknown(code)
  }
}

///|
/// Decode a single instruction from the reader
pub fn decode_instruction(
  reader : @binary_reader.BinaryReader,
) -> Instruction raise Error {
  let offset = reader.get_offset()
  let code = reader.read_u8()
  let opcode = decode_opcode(code)

  let inst : Instruction = {
    opcode,
    block_type: None,
    label_indices: [],
    default_target: None,
    func_index: None,
    type_index: None,
    local_index: None,
    global_index: None,
    mem_arg: None,
    mem_index: None,
    i32_imm: None,
    i64_imm: None,
    f32_imm: None,
    f64_imm: None,
    offset,
  }

  match opcode {
    Block | Loop | If => {
      let bt = @wasm_type.parse_block_type(reader)
      inst.block_type = Some(bt)
    }
    Br | BrIf => {
      let idx = reader.read_uleb128_u32()
      inst.label_indices = [idx]
    }
    BrTable => {
      let count = reader.read_uleb128_u32().reinterpret_as_int()
      let indices : Array[UInt] = Array(capacity=count)
      let mut i = 0
      while i < count {
        indices.push(reader.read_uleb128_u32())
        i = i + 1
      }
      inst.label_indices = indices
      let default = reader.read_uleb128_u32()
      inst.default_target = Some(default)
    }
    Call => {
      let idx = reader.read_uleb128_u32()
      inst.func_index = Some(idx)
    }
    CallIndirect => {
      let type_idx = reader.read_uleb128_u32()
      let table_idx = reader.read_uleb128_u32()
      inst.type_index = Some(type_idx)
      inst.func_index = Some(table_idx)
    }
    LocalGet | LocalSet | LocalTee => {
      let idx = reader.read_uleb128_u32()
      inst.local_index = Some(idx)
    }
    GlobalGet | GlobalSet => {
      let idx = reader.read_uleb128_u32()
      inst.global_index = Some(idx)
    }
    I32Load | I64Load | F32Load | F64Load | I32Store | I64Store | F32Store | F64Store | I32Load8S | I32Load8U | I32Load16S | I32Load16U | I64Load8S | I64Load8U | I64Load16S | I64Load16U | I64Load32S | I64Load32U | I32Store8 | I32Store16 | I64Store8 | I64Store16 | I64Store32 => {
      let align = reader.read_uleb128_u32()
      let mem_offset = reader.read_uleb128_u32()
      inst.mem_arg = Some({ align, offset: mem_offset })
    }
    MemorySize | MemoryGrow => {
      let mem_idx = reader.read_u8()
      inst.mem_index = Some(mem_idx.to_uint())
    }
    I32Const => {
      let val = reader.read_sleb128_i32()
      inst.i32_imm = Some(val)
    }
    I64Const => {
      let val = reader.read_sleb128()
      inst.i64_imm = Some(val)
    }
    F32Const => {
      let val = reader.read_u32()
      inst.f32_imm = Some(val)
    }
    F64Const => {
      let val = reader.read_u64()
      inst.f64_imm = Some(val)
    }
    _ => ()
  }

  inst
}
